//
//  IAPReceipt.h
//  TPAPReceiptLocally
//
//  Created by Thang Phung on 26/05/2021.
//

#import <Foundation/Foundation.h>

@interface TPIAPReceipt : NSObject

@property (nonatomic, nullable) NSNumber *quantity;
@property (nonatomic, nullable) NSString *productIdentifier;
@property (nonatomic, nullable) NSString *transactionIdentifer;
@property (nonatomic, nullable) NSString *originalTransactionIdentifier;
@property (nonatomic, nullable) NSDate *purchaseDate;
@property (nonatomic, nullable) NSDate *originalPurchaseDate;
@property (nonatomic, nullable) NSDate *subscriptionExpirationDate;
@property (nonatomic, nullable) NSNumber *subscriptionIntroductoryPricePeriod;
@property (nonatomic, nullable) NSDate *subscriptionCancellationDate;
@property (nonatomic, nullable) NSNumber *webOrderLineId;

- (nullable instancetype)initWithPointer:(nonnull const uint8_t *)p andPayloadLength:(long)payloadLength;

@end
