//
//  NSImage+Resize.h
//  WeeMacClient
//
//  Created by Le Thai Phuc Quang on 5/25/15.
//  Copyright (c) 2015 QuangLTP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Resize)
- (NSImage *)resizeToWidth:(CGFloat)newWidth;
- (NSData *)jpegData;
@end
