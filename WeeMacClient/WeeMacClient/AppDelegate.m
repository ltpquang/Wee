//
//  AppDelegate.m
//  WeeMacClient
//
//  Created by Le Thai Phuc Quang on 5/23/15.
//  Copyright (c) 2015 QuangLTP. All rights reserved.
//

#import "AppDelegate.h"
#import "MACAddress.h"
#import <ParseOSX/ParseOSX.h>
#import "NSImage+Resize.h"
#import "PQComputerNameCrafter.h"

@interface AppDelegate ()
// Data components
@property FileWatcher *watcher;
//@property (atomic, assign) BOOL launchOnLogin;

// UI components
@property (strong, nonatomic) NSWindowController *signInController;
@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) NSMenu *signedInMenu;
@property (nonatomic) NSMenu *unsignedInMenu;

@property (nonatomic) NSMenuItem *emailLabelMenuItem;
@property (nonatomic) NSMenuItem *uploadMenuItem;
@property (nonatomic) NSMenuItem *launchOnLogInItem;
@end

@implementation AppDelegate

#pragma mark - Delegates
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupParse];
    [PFUser logOut];
    [self setupFileChangingObserver];
    [self setupStatusItem];
    [self checkForUserAndSignIn];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
}

- (void)evaluateAndConfigMenuItems {
    if ([PFUser currentUser]) {
        _statusItem.menu = [self getSignedInMenu];
    }
    else {
        _statusItem.menu = [self getUnsignedInMenu];
    }
}

- (void)configUploadMenuItemIsUploading:(BOOL)isUploading
                         withPercentage:(int)percentComplete {
    if (!_uploadMenuItem) {
        _uploadMenuItem = [[NSMenuItem alloc] init];
    }
    if (isUploading) {
        [_uploadMenuItem setTitle:[NSString stringWithFormat:@"Uploading - %i%%...", percentComplete]];
        [_uploadMenuItem setAction:nil];
    }
    else {
        [_uploadMenuItem setTitle:@"Upload current wallpaper"];
        [_uploadMenuItem setAction:@selector(getUploadAction:)];
    }
}

- (void)registerThisDevice {
    PFQuery *query = [PFQuery queryWithClassName:@"MasterDevice"];
    [[query whereKey:@"user" equalTo:[PFUser currentUser]]
     whereKey:@"deviceIdentifier" equalTo:[MACAddress serialNumber]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *PF_NULLABLE_S objects, NSError *PF_NULLABLE_S error) {
        if (objects.count == 0) {
            PFObject *object = [PFObject objectWithClassName:@"MasterDevice"];
            object[@"user"] = [PFUser currentUser];
            object[@"deviceIdentifier"] = [MACAddress serialNumber];
            object[@"deviceName"] = [PQComputerNameCrafter craftComputerName];
            [[NSHost currentHost] localizedName];
            [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error) {
                if (succeeded || [[error userInfo][@"error"] isEqualToString:@"record exists"]) {
                    [self evaluateAndConfigMenuItems];
                    [self uploadCurrentWallpaperAndSaveToParse];
                }
                else {
                    NSLog(@"%@", error);
                }
            }];
        }
        else {
            [self evaluateAndConfigMenuItems];
            [self uploadCurrentWallpaperAndSaveToParse];
        }
    }];
}

- (void)uploadCurrentWallpaperAndSaveToParse {
    NSURL *wallpaperUrl = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[NSScreen mainScreen]];
    NSData *wallpaperData = [NSData dataWithContentsOfURL:wallpaperUrl];
    PFFile *file = [PFFile fileWithName:[wallpaperUrl lastPathComponent] data:wallpaperData];
    
    NSImage *sourceImage = [[NSImage alloc] initWithContentsOfURL:wallpaperUrl];
    NSImage *resizedImage = [sourceImage resizeToWidth:320.0];
    NSData *resizedData = [resizedImage jpegData];
    PFFile *resizedFile = [PFFile fileWithName:[wallpaperUrl lastPathComponent] data:resizedData];
    
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error) {
        [resizedFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error) {
            PFQuery *query = [PFQuery queryWithClassName:@"MasterDevice"];
            [[query whereKey:@"user" equalTo:[PFUser currentUser]]
             whereKey:@"deviceIdentifier" equalTo:[MACAddress serialNumber]];
            
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *PF_NULLABLE_S object,  NSError *PF_NULLABLE_S error) {
                if(object) {
                    object[@"lastestWallpaper"] = file;
                    object[@"lastestWallpaperThumbnail"] = resizedFile;
                    object[@"thumbnailWidth"] = @(resizedImage.size.width);
                    object[@"thumbnailHeight"] = @(resizedImage.size.height);
                    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error) {
                        //saving done;
                        NSLog(@"Saving done");
                        [self configUploadMenuItemIsUploading:NO withPercentage:0];
                    }];
                }
            }];
        
        }
                                 progressBlock:^(int percentDone) {
                                     NSLog(@"%i", percentDone);
                                     [self configUploadMenuItemIsUploading:YES withPercentage:percentDone];
                                 }];
        
        
        
    }
                      progressBlock:^(int percentDone) {
                          NSLog(@"%i", percentDone);
                          [self configUploadMenuItemIsUploading:YES withPercentage:percentDone];
                      }];
}

#pragma mark - Launch at login
- (BOOL)launchOnLogin
{
    LSSharedFileListRef loginItemsListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    CFArrayRef snapshotRef = LSSharedFileListCopySnapshot(loginItemsListRef, NULL);
    NSArray* loginItems = CFBridgingRelease(snapshotRef);
    NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    for (id item in loginItems) {
        LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)CFBridgingRetain(item);
        CFURLRef itemURLRef;
        if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
            NSURL *itemURL = (NSURL *)CFBridgingRelease(itemURLRef);
            if ([itemURL isEqual:bundleURL]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)setLaunchOnLogin:(BOOL)launchOnLogin
{
    NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    LSSharedFileListRef loginItemsListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if (launchOnLogin) {
        NSDictionary *properties;
        properties = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.loginitem.HideOnLaunch"];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsListRef, kLSSharedFileListItemLast, NULL, NULL, (CFURLRef)CFBridgingRetain(bundleURL), (CFDictionaryRef)CFBridgingRetain(properties),NULL);
        if (itemRef) {
            CFRelease(itemRef);
        }
    } else {
        LSSharedFileListRef loginItemsListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        CFArrayRef snapshotRef = LSSharedFileListCopySnapshot(loginItemsListRef, NULL);
        NSArray* loginItems = CFBridgingRelease(snapshotRef);
        
        for (id item in loginItems) {
            LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)CFBridgingRetain(item);
            CFURLRef itemURLRef;
            if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
                NSURL *itemURL = (NSURL *)CFBridgingRelease(itemURLRef);
                if ([itemURL isEqual:bundleURL]) {
                    LSSharedFileListItemRemove(loginItemsListRef, itemRef);
                }
            }
        }
    }
}

#pragma mark - Parse setup
- (void)setupParse {
    // Initialize Parse.
    [Parse setApplicationId:@"bwGMcwXKS9NHuzt2nES4SjzNthcWrOcjKynalHHI"
                  clientKey:@"Vbobvtxd3gbCYXsIZYqqvbLFfkcxAal1073ZxELT"];
}

#pragma mark - File watcher setup and delegates
- (void)setupFileChangingObserver {
    _watcher = [[FileWatcher alloc] init];
    _watcher.delegate = self;
    
    NSString *urlString = [NSString stringWithFormat:@"file://localhost%@/Library/Application Support/Dock/desktoppicture.db", NSHomeDirectory()];
    [_watcher watchFileAtURL:[NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

- (void)fileDidChangeAtURL:(NSURL *)notification {
    if (![PFUser currentUser]) {
        return;
    }
    else {
        [self uploadCurrentWallpaperAndSaveToParse];
    }
    NSLog(@"i saw that, %@!", notification);
}

#pragma mark - User handling
- (void)checkForUserAndSignIn {
    if ([PFUser currentUser]) {
        //do stuff if current user available
        [self evaluateAndConfigMenuItems];
        [self registerThisDevice];
        //[self uploadCurrentWallpaperAndSaveToParse];
    }
    else {
        [self getSignInAction:nil];
    }
}

#pragma mark - Status item setup
- (void)setupStatusItem {
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *menuIcon = [NSImage imageNamed:@"egg"];
    NSImage *highlightIcon = [NSImage imageNamed:@"egg"]; // Yes, we're using the exact same image asset.
    [highlightIcon setTemplate:YES]; // Allows the correct highlighting of the icon when the menu is clicked.
    [[self statusItem] setImage:menuIcon];
    [[self statusItem] setAlternateImage:highlightIcon];
    [[self statusItem] setMenu:nil];
    [[self statusItem] setHighlightMode:YES];
    //_statusItem.menu = [self getUnsignedInMenu];
    [self evaluateAndConfigMenuItems];
}

- (NSMenu *)getUnsignedInMenu {
    if (_unsignedInMenu) {
        return _unsignedInMenu;
    }
    _unsignedInMenu = [[NSMenu alloc] init];
    
    //Add items for image category
    //[menu addItemWithTitle:@"Hóng" action:@selector(getRandomImage:) keyEquivalent:@""];
    
    
    //Seperator
    //[_unsignedInMenu addItem:[NSMenuItem separatorItem]];
    
    //Add option item
    //[menu addItemWithTitle:@"Óp sình" action:@selector(getOptionAction:) keyEquivalent:@""];
    
    //Add about item
    [_unsignedInMenu addItemWithTitle:@"Sign in..." action:@selector(getSignInAction:) keyEquivalent:@""];
    
    
    //Seperator
    [_unsignedInMenu addItem:[NSMenuItem separatorItem]];
    
    //Add quit item
    [_unsignedInMenu addItemWithTitle:@"Quit" action:@selector(getQuitAction:) keyEquivalent:@""];
    
    return _unsignedInMenu;
}

- (NSMenu *)getSignedInMenu {
    if (_signedInMenu) {
        [_emailLabelMenuItem setTitle:[NSString stringWithFormat:@"%@", [[PFUser currentUser] username]]];
        return _signedInMenu;
    }
    
    _signedInMenu = [[NSMenu alloc] init];
    
    //Add items for image category
    //[menu addItemWithTitle:@"Hóng" action:@selector(getRandomImage:) keyEquivalent:@""];
    
    [self configUploadMenuItemIsUploading:NO withPercentage:0];
    [_signedInMenu addItem:_uploadMenuItem];
    
    //Seperator
    [_signedInMenu addItem:[NSMenuItem separatorItem]];
    
    
    _launchOnLogInItem = [[NSMenuItem alloc] initWithTitle:@"Launch on login" action:@selector(getLaunchOnLoginAction:) keyEquivalent:@""];
    [_launchOnLogInItem setState:[self launchOnLogin]];
    [_signedInMenu addItem:_launchOnLogInItem];
    
    
    [_signedInMenu addItem:[NSMenuItem separatorItem]];
    
    //Add about item
    _emailLabelMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@", [[PFUser currentUser] username]]
                                                     action:nil
                                              keyEquivalent:@""];
    [_signedInMenu addItem:_emailLabelMenuItem];
    [_signedInMenu addItemWithTitle:@"Sign out" action:@selector(getSignOutAction:) keyEquivalent:@""];
    
    //Seperator
    [_signedInMenu addItem:[NSMenuItem separatorItem]];
    
    [_signedInMenu addItemWithTitle:@"Wee for OS X v1.0" action:nil keyEquivalent:@""];
    [_signedInMenu addItemWithTitle:@"Check for update..." action:@selector(getCheckForUpdateAction:) keyEquivalent:@""];
    
    //Seperator
    [_signedInMenu addItem:[NSMenuItem separatorItem]];
    
    //Add quit item
    [_signedInMenu addItemWithTitle:@"Quit Wee" action:@selector(getQuitAction:) keyEquivalent:@""];
    
    return _signedInMenu;
}

- (void)getSignInAction:(id)sender {
    NSStoryboard *sb = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    _signInController = [sb instantiateControllerWithIdentifier:@"SignInWindowController"];
    [_signInController showWindow:_signInController];
}

- (void)getSignOutAction:(id)sender {
    PFQuery *query = [PFQuery queryWithClassName:@"MasterDevice"];
    [[query whereKey:@"user" equalTo:[PFUser currentUser]]
     whereKey:@"deviceIdentifier" equalTo:[MACAddress serialNumber]];
    
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *PF_NULLABLE_S object,  NSError *PF_NULLABLE_S error) {
        [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error) {
            if (succeeded) {
            }
            else {
                NSLog(@"%@", error);
            }
        }];
        
        [PFUser logOutInBackgroundWithBlock:^(NSError *PF_NULLABLE_S error) {
            //_statusItem.menu = [self getUnsignedInMenu];
            [self evaluateAndConfigMenuItems];
        }];
    }];
    
}

- (void)getAboutAction:(id)sender {
    
}

- (void)getLaunchOnLoginAction:(id)sender {
    BOOL isLaunch = [self launchOnLogin];
    [_launchOnLogInItem setState:!isLaunch];
    [self setLaunchOnLogin:!isLaunch];
}

- (void)getUploadAction:(id)sender {
    [self uploadCurrentWallpaperAndSaveToParse];
}

- (void)getCheckForUpdateAction:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://www.stackoverflow.com/"];
    if( ![[NSWorkspace sharedWorkspace] openURL:url] )
        NSLog(@"Failed to open url: %@",[url description]);
}

- (void)getQuitAction:(id)sender {
    [NSApp terminate:self];
}


@end
