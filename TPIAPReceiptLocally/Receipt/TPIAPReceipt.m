//
//  IAPReceipt.m
//  TPAPReceiptLocally
//
//  Created by Thang Phung on 26/05/2021.
//

#import "TPIAPReceipt.h"
#import "OpenSSL.h"
#import "TPIAPHelper.h"

NSInteger const TPAppReceiptASN1TypeQuantity = 1701;
NSInteger const TPAppReceiptASN1TypeProductIdentifier = 1702;
NSInteger const TPAppReceiptASN1TypeTransactionIdentifier = 1703;
NSInteger const TPAppReceiptASN1TypePurchaseDate = 1704;
NSInteger const TPAppReceiptASN1TypeOriginalTransactionIdentifier = 1705;
NSInteger const TPAppReceiptASN1TypeOriginalPurchaseDate = 1706;
NSInteger const TPAppReceiptASN1TypeSubscriptionExpirationDate = 1708;
NSInteger const TPAppReceiptASN1TypeWebOrderLineItemID = 1711;
NSInteger const TPAppReceiptASN1TypeCancellationDate = 1712;

@implementation TPIAPReceipt

- (instancetype)initWithPointer:(const uint8_t *)p andPayloadLength:(long)payloadLength {
    self = [super init];
    if (self) {
        const uint8_t *end = p + payloadLength;
        int type = 0;
        int xclass = 0;
        long length = 0;
        
        ASN1_get_object(&p, &length, &type, &xclass, payloadLength);
        if (type != V_ASN1_SET) {
            return NULL;
        }
        
        while (p < end) {
            ASN1_get_object(&p, &length, &type, &xclass, end - p);
            if (type != V_ASN1_SEQUENCE) {
                return NULL;
            }
            
            NSNumber *attributeType = [TPIAPHelper readASN1Integer:&p andMaxLength:end - p];
            if (attributeType == NULL) {
                return NULL;
            }
            
            NSNumber *attributeType2 = [TPIAPHelper readASN1Integer:&p andMaxLength:end - p];
            if (attributeType2 == NULL) {
                return NULL;
            }
            
            ASN1_get_object(&p, &length, &type, &xclass, end - p);
            if (type != V_ASN1_OCTET_STRING) {
                return NULL;
            }
            
            switch (attributeType.longValue) {
                case TPAppReceiptASN1TypeQuantity: {
                    const uint8_t *pp = p;
                    [self setQuantity:[TPIAPHelper readASN1Integer:&pp andMaxLength:length]];
                }
                    break;
                case TPAppReceiptASN1TypeProductIdentifier: {
                    const uint8_t *pp = p;
                    [self setProductIdentifier:[TPIAPHelper readASN1String:&pp andMaxLength:length]];
                }
                    break;
                case TPAppReceiptASN1TypeTransactionIdentifier: {
                    const uint8_t *pp = p;
                    [self setTransactionIdentifer:[TPIAPHelper readASN1String:&pp andMaxLength:length]];
                }
                    break;
                case TPAppReceiptASN1TypePurchaseDate: {
                    const uint8_t *pp = p;
                    [self setPurchaseDate:[TPIAPHelper readASN1Date:&pp andMaxLength:length]];
                }
                    break;
                case TPAppReceiptASN1TypeOriginalTransactionIdentifier: {
                    const uint8_t *pp = p;
                    [self setOriginalTransactionIdentifier:[TPIAPHelper readASN1String:&pp andMaxLength:length]];
                }
                    break;
                case TPAppReceiptASN1TypeOriginalPurchaseDate: {
                    const uint8_t *pp = p;
                    [self setOriginalPurchaseDate:[TPIAPHelper readASN1Date:&pp andMaxLength:length]];
                }
                    break;
                case TPAppReceiptASN1TypeSubscriptionExpirationDate: {
                    const uint8_t *pp = p;
                    [self setSubscriptionExpirationDate:[TPIAPHelper readASN1Date:&pp andMaxLength:length]];
                }
                    break;
                case TPAppReceiptASN1TypeWebOrderLineItemID: {
                    const uint8_t *pp = p;
                    [self setWebOrderLineId:[TPIAPHelper readASN1Integer:&pp andMaxLength:length]];
                }
                    break;
                case TPAppReceiptASN1TypeCancellationDate: {
                    const uint8_t *pp = p;
                    [self setSubscriptionCancellationDate:[TPIAPHelper readASN1Date:&pp andMaxLength:length]];
                }
                    break;
                default:
                    break;
            }
            
            p += length;
        }
    }
    
    return self;
}

@end

