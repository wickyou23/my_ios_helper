//
//  TPUtils.h
//  TPAPReceiptLocally
//
//  Created by Thang Phung on 02/06/2021.
//

#import <Foundation/Foundation.h>

@interface TPIAPUtils : NSObject

+(nullable NSString*)generateSignatureLocallyWithPrivateKey:(nonnull NSData*)privateKeyData
                                                 andPayload:(nonnull NSString*)payload;
+(BOOL)verifySignatureLocallyWithPublicKey:(nonnull NSData*)publicKeyData
                                andPayload:(nonnull NSString*)payload
                              andSignature:(nonnull NSString*)signatureString;

@end
