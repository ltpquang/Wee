//
//  PQSignInViewController.m
//  WeeMacClient
//
//  Created by Le Thai Phuc Quang on 5/23/15.
//  Copyright (c) 2015 QuangLTP. All rights reserved.
//

#import "PQSignInViewController.h"
#import "AppDelegate.h"
#import <ParseOSX/ParseOSX.h>
#import "MACAddress.h"
#import "PQComputerNameCrafter.h"

@interface PQSignInViewController ()
@property (weak) IBOutlet NSTextField *signUpEmailTextField;
@property (weak) IBOutlet NSSecureTextField *signUpPasswordTextField;
@property (weak) IBOutlet NSSecureTextField *signUpConfirmPasswordTextField;

@property (weak) IBOutlet NSTextField *signInEmailTextField;
@property (weak) IBOutlet NSSecureTextField *signInPasswordTextField;

@property (weak) IBOutlet NSButton *signInButton;
@property (weak) IBOutlet NSButton *signUpButton;
@end

@implementation PQSignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configButton];
    // Do view setup here.
}

- (void)configButton {
    NSMutableAttributedString *attrTitle =
    [[NSMutableAttributedString alloc] initWithString:@"Sign in"];
    NSUInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, len);
    [attrTitle addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithCalibratedRed:247.0/255.0 green:216.0/255.0 blue:5.0/255.0 alpha:1.0] range:range];
    [attrTitle setAlignment:NSCenterTextAlignment range:range];
    [attrTitle fixAttributesInRange:range];
    [_signInButton setAttributedTitle:attrTitle];
    
    
    NSMutableAttributedString *attrTitle2 =
    [[NSMutableAttributedString alloc] initWithString:@"Sign up"];
    NSUInteger len2 = [attrTitle2 length];
    NSRange range2 = NSMakeRange(0, len2);
    [attrTitle2 addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithCalibratedRed:247.0/255.0 green:216.0/255.0 blue:5.0/255.0 alpha:1.0] range:range2];
    [attrTitle2 setAlignment:NSCenterTextAlignment range:range2];
    [attrTitle2 fixAttributesInRange:range2];
    [_signUpButton setAttributedTitle:attrTitle2];
}

- (AppDelegate *)getApp {
    return (AppDelegate *)[[NSApplication sharedApplication] delegate];
}

- (void)showErrorWithMessageText:(NSString *)mText andInformativeText:(NSString *)iText {
    
    NSAlert *al = [[NSAlert alloc] init];
    [al setMessageText:mText];
    [al setInformativeText:iText];
    [al runModal];
}

- (BOOL)checkEmail:(NSString *)email {
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    return [emailTest evaluateWithObject:email];
}

- (IBAction)signUpButton_TUI:(id)sender {
    NSString *email = _signUpEmailTextField.stringValue;
    NSString *password = _signUpPasswordTextField.stringValue;
    NSString *confirmPassword = _signUpConfirmPasswordTextField.stringValue;
    if (![self checkEmail:email]) {
        [self showErrorWithMessageText:@"Oops" andInformativeText:@"Please enter valid email"];
        return;
    }
    if (password.length == 0) {
        [self showErrorWithMessageText:@"Oops" andInformativeText:@"Enter passwords please"];
        return;
    }
    if (![password isEqualToString:confirmPassword]) {
        [self showErrorWithMessageText:@"Oops" andInformativeText:@"Two passwords don't match"];
        return;
    }
    
    PFUser *user = [PFUser user];
    user.username = email;
    user.password = password;
    [self disableButtons];
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error) {
        [self enableButtons];
        if (succeeded) {
            [self disableButtons];
            [PFUser logInWithUsernameInBackground:email
                                         password:password
                                            block:^(PFUser *PF_NULLABLE_S user, NSError *PF_NULLABLE_S error) {
                                                [self enableButtons];
                                                if (user) {
                                                    [[self getApp] registerThisDevice];
                                                    [[[self view] window] close];
                                                }
                                                else {
                                                    if ([[error userInfo][@"error"] isEqualToString:@"invalid login parameters"]) {
                                                        [self showErrorWithMessageText:@"404! Account not found!" andInformativeText:@"Please try again with another email and password"];
                                                    }
                                                    NSLog(@"%@", error);
                                                }
                                            }];
        }
        else {
            if (error.code == 202) {
                [self showErrorWithMessageText:@"This email already in use" andInformativeText:@"Please choose another one"];
            }
            NSLog(@"%@", error);
        }
    }];
}

- (IBAction)signInButton_TUI:(id)sender {
    NSString *email = _signInEmailTextField.stringValue;
    NSString *password = _signInPasswordTextField.stringValue;
    
    [self disableButtons];
    [PFUser logInWithUsernameInBackground:email
                                 password:password
                                    block:^(PFUser *PF_NULLABLE_S user, NSError *PF_NULLABLE_S error) {
                                        [self enableButtons];
                                        if (user) {
                                            [[self getApp] registerThisDevice];
                                            [[[self view] window] close];
                                        }
                                        else {
                                            if ([[error userInfo][@"error"] isEqualToString:@"invalid login parameters"]) {
                                                [self showErrorWithMessageText:@"404! Account not found!" andInformativeText:@"Please try again with another email and password"];
                                            }
                                            NSLog(@"%@", error);
                                        }
                                        
                                    }];
}

- (void)disableButtons {
    [_signInButton setEnabled:NO];
    [_signUpButton setEnabled:NO];
}

- (void)enableButtons {
    [_signInButton setEnabled:YES];
    [_signUpButton setEnabled:YES];
}

@end
