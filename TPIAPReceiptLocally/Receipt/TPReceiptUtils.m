//
//  TPUtils.m
//  TPIAPReceiptLocally
//
//  Created by Thang Phung on 02/06/2021.
//

#import "TPReceiptUtils.h"
#import "OpenSSL.h"
#import <CommonCrypto/CommonDigest.h>

@implementation TPReceiptUtils

+(nullable NSString*)generateSignatureLocallyWithPrivateKey:(nonnull NSData*)privateKeyData
                                                 andPayload:(nonnull NSString*)payload {
    if (payload.length == 0) {
        NSLog(@"Payload is empty");
        return NULL;
    }
    
    EC_KEY *eckeyAlgorithm = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
    if (eckeyAlgorithm == NULL) {
        #if DEBUG
        fprintf(stderr, "Error in eckeyAlgorithm.\n");
        ERR_print_errors_fp(stderr);
        #endif
        
        EC_KEY_free(eckeyAlgorithm);
        return NULL;
    }
    
    BIO *bio = BIO_new(BIO_s_mem());
    BIO_write(bio, privateKeyData.bytes, (int)privateKeyData.length);
    EC_KEY *eckey = d2i_ECPrivateKey_bio(bio, &eckeyAlgorithm);
    BIO_free(bio);
    if (eckey == NULL) {
        #if DEBUG
        fprintf(stderr, "Error in get eckey.\n");
        ERR_print_errors_fp(stderr);
        #endif
        
        EC_KEY_free(eckey);
        return NULL;
    }
    
    NSData* dgst = [payload dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char *buffer, *pp;
    unsigned int buf_len = ECDSA_size(eckey);
    buffer = OPENSSL_malloc(buf_len);
    pp = buffer;
    if (ECDSA_sign(0, dgst.bytes, (int)dgst.length, pp, &buf_len, eckey) == 0) {
        #if DEBUG
        fprintf(stderr, "Error in ECDSA_sign.\n");
        ERR_print_errors_fp(stderr);
        #endif
        
        EC_KEY_free(eckey);
        return NULL;
    }
    
    EC_KEY_free(eckey);
    NSData *sig = [[NSData alloc] initWithBytes:pp length:buf_len];
    return [sig base64EncodedStringWithOptions:0];
}

+(BOOL)verifySignatureLocallyWithPublicKey:(nonnull NSData*)publicKeyData
                                andPayload:(nonnull NSString*)payload
                              andSignature:(nonnull NSString*)signatureString {
    if (payload.length == 0) {
        NSLog(@"Payload is empty");
        return FALSE;
    }
    
    if (signatureString.length == 0) {
        NSLog(@"signatureString is empty");
        return FALSE;
    }
    
    EC_KEY *eckeyAlgorithm = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
    if (eckeyAlgorithm == NULL) {
        #if DEBUG
        fprintf(stderr, "Error in eckeyAlgorithm.\n");
        ERR_print_errors_fp(stderr);
        #endif

        EC_KEY_free(eckeyAlgorithm);
        return FALSE;
    }
    
    BIO *bio = BIO_new(BIO_s_mem());
    BIO_write(bio, publicKeyData.bytes, (int)publicKeyData.length);
    EC_KEY *eckey = d2i_EC_PUBKEY_bio(bio, &eckeyAlgorithm);
    BIO_free(bio);
    if (eckey == NULL) {
        #if DEBUG
        fprintf(stderr, "Error in get eckey.\n");
        ERR_print_errors_fp(stderr);
        #endif

        EC_KEY_free(eckey);
        return NULL;
    }
    
    NSData* dgst = [payload dataUsingEncoding:NSUTF8StringEncoding];
    NSData* sig = [[NSData alloc] initWithBase64EncodedString:signatureString options:0];
    int ret = ECDSA_verify(0, dgst.bytes, (int)dgst.length, sig.bytes, (int)sig.length, eckey);
    EC_KEY_free(eckey);
    if (ret == 1) {
        return TRUE;
    }
    else if (ret == 0) {
        NSLog(@"Incorrect signature");
        return FALSE;
    }
    else {
        #if DEBUG
        fprintf(stderr, "Error in eckeyAlgorithm.\n");
        ERR_print_errors_fp(stderr);
        #endif
        
        return FALSE;
    }
}

@end
