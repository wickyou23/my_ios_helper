//
//  IAPHelper.h
//  TPIAPReceiptLocally
//
//  Created by Thang Phung on 26/05/2021.
//

#import <Foundation/Foundation.h>

typedef const uint8_t *_Nonnull*_Nonnull CUINT8_T;

NS_ASSUME_NONNULL_BEGIN

@interface TPReceiptHelper : NSObject

+ (nullable NSNumber*)readASN1Integer:(CUINT8_T)p andMaxLength:(long)maxLength;
+ (nullable NSString*)readASN1String:(CUINT8_T)p andMaxLength:(long)maxLength;
+ (nullable NSData*)readASN1Data:(CUINT8_T)p andMaxLength:(long)maxLength;
+ (nullable NSDate*)readASN1Date:(CUINT8_T)p andMaxLength:(long)maxLength;

@end

NS_ASSUME_NONNULL_END
