//
//  AppDelegate.h
//  WeeMacClient
//
//  Created by Le Thai Phuc Quang on 5/23/15.
//  Copyright (c) 2015 QuangLTP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileWatcher.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, FileWatcherDelegate>

- (void)evaluateAndConfigMenuItems;
- (void)uploadCurrentWallpaperAndSaveToParse;
- (void)registerThisDevice;
@end

