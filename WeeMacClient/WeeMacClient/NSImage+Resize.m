//
//  NSImage+Resize.m
//  WeeMacClient
//
//  Created by Le Thai Phuc Quang on 5/25/15.
//  Copyright (c) 2015 QuangLTP. All rights reserved.
//

#import "NSImage+Resize.h"

@implementation NSImage (Resize)
- (NSImage *)resizeToWidth:(CGFloat)newWidth {
    /*
    CGFloat newHeight = newWidth * self.size.height / self.size.width;
    
    NSImage *sourceImage = self;
    
    NSSize newSize = NSSizeFromCGSize(CGSizeMake(newWidth, newHeight));
    
    NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
    [smallImage lockFocus];
    [sourceImage setSize: newSize];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationLow];
    [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositeCopy fraction:1.0];
    [smallImage unlockFocus];
    return smallImage;
     */
    CGFloat newHeight = newWidth * self.size.height / self.size.width;
    NSRect targetFrame = NSMakeRect(0, 0, newWidth, newHeight);
    NSImage*  targetImage = [[NSImage alloc] initWithSize:NSSizeFromCGSize(CGSizeMake(newWidth, newHeight))];
    
    [targetImage lockFocus];
    
    [self drawInRect:targetFrame
            fromRect:NSZeroRect       //portion of source image to draw
           operation:NSCompositeCopy  //compositing operation
            fraction:1.0              //alpha (transparency) value
      respectFlipped:YES              //coordinate system
               hints:@{NSImageHintInterpolation:
                           [NSNumber numberWithInt:NSImageInterpolationHigh]}];
    
    [targetImage unlockFocus];
    
    return targetImage;
}

- (NSData *)jpegData {
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    return [imageRep representationUsingType:NSJPEGFileType properties:nil];
}
@end
