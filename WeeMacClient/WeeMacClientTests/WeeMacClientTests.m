//
//  WeeMacClientTests.m
//  WeeMacClientTests
//
//  Created by Le Thai Phuc Quang on 5/23/15.
//  Copyright (c) 2015 QuangLTP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "MACAddress.h"
#import "PQComputerNameCrafter.h"

@interface WeeMacClientTests : XCTestCase

@end

@implementation WeeMacClientTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    NSString *mac = [PQComputerNameCrafter craftComputerName];
    
    
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
