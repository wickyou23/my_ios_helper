//
//  Receipt.h
//  TPAPReceiptLocally
//
//  Created by Thang Phung on 26/05/2021.
//

#import <Foundation/Foundation.h>
#import "TPReceiptEnum.h"

///Description:
/*
https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html

To validate the receipt, perform the following tests, in order:
1.Locate the receipt.
- If no receipt is present, validation fails.
2. Verify that the receipt is properly signed by Apple.
- If it is not signed by Apple, validation fails.
3. Verify that the bundle identifier in the receipt matches a hard-coded constant containing the CFBundleIdentifier value you expect in the Info.plist file.
- If they do not match, validation fails.
4. Verify that the version identifier string in the receipt matches a hard-coded constant containing the CFBundleShortVersionString value (for macOS) or the CFBundleVersion value (for iOS) that you expect in the Info.plist file.
- If they do not match, validation fails.
5. Compute the hash of the GUID as described in Compute the Hash of the GUID.
- If the result does not match the hash in the receipt, validation fails.
*/

@interface TPReceipt : NSObject

@property (nonatomic, assign) TPReceiptStatus receiptStatus;
@property (nonatomic, nullable) NSMutableDictionary *inAppReceipts;

//MARK: - For Production or Sandbox verify
- (nullable instancetype)initWithPaymentType:(TPProductType)paymentType
                                   AppBundle:(nonnull NSBundle*)appBundle
                          andCertificateName:(nonnull NSString*)certificateName;

//MARK: - For Storekit verify
- (nullable instancetype)initWithStorekitPaymentType:(TPProductType)paymentType
                                           AppBundle:(nonnull NSBundle*)appBundle
                                  andCertificateName:(nonnull NSString*)certificateName;

////MARK: - For Unit Test
//- (nullable instancetype)initWithAppBundle:(nonnull NSBundle*)appBundle
//                            andReceiptData:(nonnull NSData*)receiptData
//                        andCertificateName:(nonnull NSString*)certificateName;

@end

