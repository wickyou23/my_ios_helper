//
//  TPIAPReceiptLocally_SimulatorTests.m
//  TPIAPReceiptLocally-SimulatorTests
//
//  Created by Thang Phung on 13/07/2021.
//

#import <XCTest/XCTest.h>
#import "TPReceipt.h"

@interface TPIAPReceiptLocally_SimulatorTests : XCTestCase

@end

@implementation TPIAPReceiptLocally_SimulatorTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    for (int i; i < 100; i++) {
        //Add base64 receipt string here
        NSString *base64String = @"";
        NSData *receiptData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
        TPReceiptDecoder *tpReceipt = [[TPReceipt alloc] initWithAppBundle:[NSBundle mainBundle] andReceiptData:receiptData andCertificateName:@"AppleIncRootCertificate"];
        NSLog(@"%@", tpReceipt);
        XCTAssertNotNil(tpReceipt);
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
