//
//  TPReceiptEnum.h
//  TPAPReceiptLocally
//
//  Created by Thang Phung on 31/05/2021.
//

typedef NS_ENUM(NSUInteger, TPReceiptStatus) {
    kValidationSuccess,
    kNoReceiptPresent,
    kUnknownFailure,
    kUnknownReceiptFormat,
    kInvalidPKCS7Signature,
    kInvalidPKCS7Type,
    kInvalidAppleRootCertificate,
    kFailedAppleSignature,
    kUnexpectedASN1Type,
    kMissingComponent,
    kInvalidBundleIdentifier,
    kInvalidVersionIdentifier,
    kInvalidHash,
    kInvalidExpired,
};

typedef NS_ENUM(NSUInteger, TPProductType) {
    kConsumables,
    kNonConsumables,
    kAutoRenewable,
    kNonRenewing,
};
