//
//  Receipt.m
//  TPAPReceiptLocally
//
//  Created by Thang Phung on 26/05/2021.
//

#import "TPReceipt.h"
#import "OpenSSL.h"
#import "TPIAPHelper.h"
#import "TPIAPReceipt.h"
#import <UIKit/UIKit.h>
#import "TPReceiptEnum.h"

NSInteger const TPAppReceiptASN1TypeBundleIdentifier = 2;
NSInteger const TPAppReceiptASN1TypeAppVersion = 3;
NSInteger const TPAppReceiptASN1TypeOpaqueValue = 4;
NSInteger const TPAppReceiptASN1TypeHash = 5;
NSInteger const TPAppReceiptASN1TypeCreationDate = 7;
NSInteger const TPAppReceiptASN1TypeInAppPurchaseReceipt = 17;
NSInteger const TPAppReceiptASN1TypeOriginalAppVersion = 19;
NSInteger const TPAppReceiptASN1TypeExpirationDate = 21;

@interface TPReceipt()

@property (nonatomic, nullable) NSString *bundleIdString;
@property (nonatomic, nullable) NSString *bundleVersionString;
@property (nonatomic, nullable) NSData *bundleIdData;
@property (nonatomic, nullable) NSData *hashData;
@property (nonatomic, nullable) NSData *opaqueData;
@property (nonatomic, nullable) NSDate *expirationDate;
@property (nonatomic, nullable) NSDate *receiptCreationDate;
@property (nonatomic, nullable) NSString *originalAppVersion;
@property (nonatomic, nonnull) NSBundle *appBundle;
@property (nonatomic, nonnull) NSString *certificateName;
@property (nonatomic, nonnull) NSData *receiptData;
@property (nonatomic, assign) TPProductType paymentType;
@property (nonatomic, assign) BOOL isStoreKitTesting;

@end


@implementation TPReceipt

- (nullable instancetype)initWithPaymentType:(TPProductType)paymentType AppBundle:(nonnull NSBundle*)appBundle andCertificateName:(nonnull NSString*)certificateName
{
    self = [super init];
    if (self) {
        [self setAppBundle:appBundle];
        [self setCertificateName:certificateName];
        [self setInAppReceipts:[[NSMutableDictionary alloc] init]];
        [self setPaymentType:paymentType];
        
        PKCS7 *payload = [self loadReceipt];
        BOOL validate = [self validateSigning:payload];
        if (validate == FALSE) {
            return self;
        }
        
        [self readReceipt:payload];
        [self validateReceipt];
    }
    return self;
}

- (nullable instancetype)initWithStorekitPaymentType:(TPProductType)paymentType AppBundle:(nonnull NSBundle*)appBundle andCertificateName:(nonnull NSString*)certificateName
{
    self = [self initWithPaymentType:paymentType AppBundle:appBundle andCertificateName:certificateName];
    if (self) {
        [self setAppBundle:appBundle];
        [self setCertificateName:certificateName];
        [self setInAppReceipts:[[NSMutableDictionary alloc] init]];
        [self setPaymentType:paymentType];
        [self setIsStoreKitTesting:TRUE];
        
        PKCS7 *payload = [self loadReceipt];
        BOOL validate = [self validateSigning:payload];
        if (validate == FALSE) {
            return self;
        }
        
        [self readReceipt:payload];
        [self validateReceipt];
    }
    return self;
}

#if DEBUG
- (nullable instancetype)initWithAppBundle:(nonnull NSBundle*)appBundle andReceiptData:(nonnull NSData*)receiptData andCertificateName:(nonnull NSString*)certificateName
{
    self = [super init];
    if (self) {
        [self setAppBundle:appBundle];
        [self setCertificateName:certificateName];
        [self setReceiptData:receiptData];
        [self setInAppReceipts:[[NSMutableDictionary alloc] init]];
//        [self setIsStoreKitTesting:TRUE];
        PKCS7 *payload = [self loadReceipt];
        BOOL validate = [self validateSigning:payload];
        if (validate == FALSE) {
            return NULL;
        }

        [self readReceipt:payload];
        [self validateReceipt];
    }
    return self;
}
#endif

- (nullable PKCS7*)loadReceipt {
    #if DEBUG
    NSData *receiptData = self.receiptData;
    #else
    NSURL *receiptUrl = self.appBundle.appStoreReceiptURL;
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
    if (receiptData == NULL) {
        [self setReceiptStatus:kNoReceiptPresent];
        return NULL;
    }
    #endif
    
    BIO *receiptBIO = BIO_new_mem_buf(((const uint8_t *)receiptData.bytes), (int)receiptData.length);
    PKCS7 *receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, NULL);
    BIO_free(receiptBIO);
    
    if (receiptPKCS7 == NULL) {
        #if DEBUG
        fprintf(stderr, "Error in d2i_PKCS7_bio.\n");
        ERR_print_errors_fp(stderr);
        #endif
        
        [self setReceiptStatus:kUnknownReceiptFormat];
        return NULL;
    }
    
    if (OBJ_obj2nid(receiptPKCS7->type) != NID_pkcs7_signed) {
        [self setReceiptStatus:kInvalidPKCS7Signature];
        return NULL;
    }
    
    struct pkcs7_st *receiptContents = receiptPKCS7->d.sign->contents;
    if (receiptContents == NULL || OBJ_obj2nid(receiptContents->type) != NID_pkcs7_data) {
        [self setReceiptStatus:kInvalidPKCS7Type];
        return NULL;
    }
    
    return receiptPKCS7;
}

- (BOOL)validateSigning:(PKCS7*)receipt {
    NSURL *rootCertUrl = [self.appBundle URLForResource:self.certificateName withExtension:@"cer"];
    NSData *rootCertData = [NSData dataWithContentsOfURL:rootCertUrl];
    if (rootCertData == NULL) {
        [self setReceiptStatus: kInvalidAppleRootCertificate];
        return FALSE;
    }
    
    BIO *rootCertBio = BIO_new_mem_buf(((const uint8_t *)rootCertData.bytes), (int)rootCertData.length);
    X509 *rootCertX509 = d2i_X509_bio(rootCertBio, NULL);
    BIO_free(rootCertBio);
    
    X509_STORE *store = X509_STORE_new();
    X509_STORE_add_cert(store, rootCertX509);
    
    OpenSSL_add_all_digests();
    
    int verificationResult = 0;
    if (self.isStoreKitTesting == TRUE) {
        verificationResult = PKCS7_verify(receipt, NULL, store, NULL, NULL, PKCS7_NOCHAIN);
    }
    else {
        verificationResult = PKCS7_verify(receipt, NULL, store, NULL, NULL, 0);
    }
    
    if (verificationResult != 1) {
        #if DEBUG
        fprintf(stderr, "Error in PKCS7_verify.\n");
        ERR_print_errors_fp(stderr);
        #endif
        
        [self setReceiptStatus: kFailedAppleSignature];
        EVP_cleanup();
        return FALSE;
    }
    
    EVP_cleanup();
    return TRUE;
}

- (void)readReceipt:(PKCS7*)receiptPKCS7 {
    PKCS7_SIGNED *receiptSign = receiptPKCS7->d.sign;
    ASN1_OCTET_STRING *octets = receiptSign->contents->d.data;
    NSData *data = [[NSData alloc] initWithBytes:octets->data length:octets->length];
    if (!data) {
        return;
    }
    
    const uint8_t *p = data.bytes;
    const uint8_t *end = p + octets->length;
    
    int type = 0;
    int xclass = 0;
    long length = 0;
     
    ASN1_get_object(&p, &length, &type, &xclass, end - p);
    if (type != V_ASN1_SET) {
        [self setReceiptStatus:kUnexpectedASN1Type];
        return;
    }
    
    while (p < end) {
        ASN1_get_object(&p, &length, &type, &xclass, end - p);
        if (type != V_ASN1_SEQUENCE) {
            [self setReceiptStatus:kUnexpectedASN1Type];
            return;
        }
        
        NSNumber *attributeType = [TPIAPHelper readASN1Integer:&p andMaxLength:length];
        if (attributeType == NULL) {
            [self setReceiptStatus:kUnexpectedASN1Type];
            return;
        }
        
        NSNumber *attributeType2 = [TPIAPHelper readASN1Integer:&p andMaxLength:end - p];
        if (attributeType2 == NULL) {
            [self setReceiptStatus:kUnexpectedASN1Type];
            return;
        }
        
        ASN1_get_object(&p, &length, &type, &xclass, end - p);
        if (type != V_ASN1_OCTET_STRING) {
            [self setReceiptStatus:kUnexpectedASN1Type];
            return;
        }
        
        switch (attributeType.longValue) {
            case TPAppReceiptASN1TypeBundleIdentifier: {
                const uint8_t *pp = p;
                [self setBundleIdString:[TPIAPHelper readASN1String:&pp andMaxLength:length]];
                [self setBundleIdData:[TPIAPHelper readASN1Data:&p andMaxLength:length]];
            }
                break;
            case TPAppReceiptASN1TypeAppVersion: {
                const uint8_t *pp = p;
                [self setBundleVersionString:[TPIAPHelper readASN1String:&pp andMaxLength:length]];
            }
                break;
            case TPAppReceiptASN1TypeOpaqueValue: {
                const uint8_t *pp = p;
                [self setOpaqueData:[TPIAPHelper readASN1Data:&pp andMaxLength:length]];
            }
                break;
            case TPAppReceiptASN1TypeHash: {
                const uint8_t *pp = p;
                [self setHashData:[TPIAPHelper readASN1Data:&pp andMaxLength:length]];
            }
                break;
            case TPAppReceiptASN1TypeCreationDate: {
                const uint8_t *pp = p;
                [self setReceiptCreationDate:[TPIAPHelper readASN1Date:&pp andMaxLength:length]];
            }
                break;
            case TPAppReceiptASN1TypeInAppPurchaseReceipt: {
                const uint8_t *pp = p;
                TPIAPReceipt *parsedReceipt = [[TPIAPReceipt alloc] initWithPointer:pp andPayloadLength:length];
                NSString* originalTransactionID= parsedReceipt.originalTransactionIdentifier;
                if (originalTransactionID == NULL) {
                    originalTransactionID = parsedReceipt.transactionIdentifer;
                }
                
                if (parsedReceipt != NULL && originalTransactionID) {
                    NSMutableArray *inAppTransaction = [self.inAppReceipts valueForKey:originalTransactionID];
                    if (inAppTransaction) {
                        [inAppTransaction addObject:parsedReceipt];
                    }
                    else {
                        inAppTransaction = [[NSMutableArray alloc] init];
                        [inAppTransaction addObject:parsedReceipt];
                    }
                    
                    [self.inAppReceipts setValue:inAppTransaction forKey:originalTransactionID];
                }
            }
                break;
            case TPAppReceiptASN1TypeOriginalAppVersion: {
                const uint8_t *pp = p;
                [self setOriginalAppVersion:[TPIAPHelper readASN1String:&pp andMaxLength:length]];
            }
                break;
            case TPAppReceiptASN1TypeExpirationDate: {
                const uint8_t *pp = p;
                [self setExpirationDate:[TPIAPHelper readASN1Date:&pp andMaxLength:length]];
            }
                break;
            default:
                break;
        }
        
        p += length;
    }
}

- (void)validateReceipt {
    if (self.bundleIdString == NULL || self.bundleVersionString == NULL || self.opaqueData == NULL || self.hashData == NULL) {
        [self setReceiptStatus:kMissingComponent];
        return;
    }
    
    // Check bundleId
    NSString *appBundleId = self.appBundle.bundleIdentifier;
    if (appBundleId == NULL) {
        [self setReceiptStatus:kUnknownFailure];
        return;
    }

    if (![self.bundleIdString isEqualToString:appBundleId]) {
        [self setReceiptStatus:kInvalidBundleIdentifier];
        return;
    }

    // Check app version
//    NSString *appVersionString = [self.appBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
//    if (appVersionString == NULL) {
//        [self setReceiptStatus:kUnknownFailure];
//        return;
//    }
//
//    if (![self.bundleVersionString isEqualToString:appVersionString]) {
//        [self setReceiptStatus:kInvalidVersionIdentifier];
//        return;
//    }
    
    // Check the GUID hash
    NSData *guidHash = [self computeHash];
    if (guidHash == self.hashData) {
        [self setReceiptStatus:kInvalidHash];
        return;
    }
    
//    // Check the expiration attribute if it's present
//    if (self.inAppReceipts.count != 0) {
//        __weak __typeof(self)weakSelf = self;
//        [self.inAppReceipts enumerateKeysAndObjectsUsingBlock:^(NSString* _Nonnull key, NSMutableArray*  _Nonnull obj, BOOL * _Nonnull stop) {
//            __typeof(weakSelf) strongSelf = weakSelf;
//            TPIAPReceipt *lastIAPReceipt = [obj firstObject];
//            if (lastIAPReceipt.subscriptionExpirationDate
//                && lastIAPReceipt.purchaseDate
//                && lastIAPReceipt.subscriptionExpirationDate < lastIAPReceipt.purchaseDate) {
//                [strongSelf setReceiptStatus:kInvalidExpired];
//                *stop = TRUE;
//            }
//        }];
//    }
//    
//    if (self.receiptStatus == kInvalidExpired) {
//        return;
//    }
    
    [self setReceiptStatus:kValidationSuccess];
}

- (NSData*)getDeviceIdentifier {
    NSString *uuid = UIDevice.currentDevice.identifierForVendor.UUIDString;
    return [NSData dataWithBytes:[uuid UTF8String] length:16];
}

- (nullable NSData*)computeHash {
    NSData *identifierData = [self getDeviceIdentifier];
    SHA_CTX ctx;
    SHA1_Init(&ctx);
    
    const uint8_t *bundleBytes = self.bundleIdData.bytes;
    SHA1_Update(&ctx, bundleBytes, self.bundleIdData.length);
    
    const uint8_t *identifierBytes = identifierData.bytes;
    SHA1_Update(&ctx, identifierBytes, identifierData.length);
    
    const uint8_t *opaqueBytes = self.opaqueData.bytes;
    SHA1_Update(&ctx, opaqueBytes, self.opaqueData.length);
    
    uint8_t hash[20] = {0};
    SHA1_Final(hash, &ctx);
    return [NSData dataWithBytes:hash length:20];
}

@end
