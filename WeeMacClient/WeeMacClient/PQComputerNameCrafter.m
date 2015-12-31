//
//  PQComputerNameCrafter.m
//  WeeMacClient
//
//  Created by Le Thai Phuc Quang on 5/28/15.
//  Copyright (c) 2015 QuangLTP. All rights reserved.
//

#import "PQComputerNameCrafter.h"
#import <GBDeviceInfo.h>

@implementation PQComputerNameCrafter
+ (NSString *)deviceName {
    GBDeviceInfo *deviceInfo = [GBDeviceInfo deviceInfo];
    switch (deviceInfo.family) {
        case GBDeviceFamilyiMac:
            return @"iMac";
            break;
        case GBDeviceFamilyMacBook:
            return @"MacBook";
            break;
        case GBDeviceFamilyMacBookAir:
            return @"MacBook Air";
            break;
        case GBDeviceFamilyMacBookPro:
            return @"MacBook Pro";
            break;
        case GBDeviceFamilyMacMini:
            return @"Mac mini";
            break;
        case GBDeviceFamilyMacPro:
            return @"Mac Pro";
            break;
        case GBDeviceFamilyXserve:
            return @"Xserve";
            break;
        case GBDeviceFamilyUnknown:
            return @"Unknown device";
            break;
    }
}
+ (NSString *)craftComputerName {
    NSString *firstName = [[NSFullUserName() componentsSeparatedByString:@" "] firstObject];
    return [NSString stringWithFormat:@"%@'s %@", firstName, [self deviceName]];
}
@end
