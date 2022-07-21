//
//  SocketConnection.h
//  flutterWebrtcExtension
//
//  Created by Thang Phung on 18/07/2022.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SocketConnection : NSObject

@property (nonatomic, copy, nullable) void(^didOpen)(void);
@property (nonatomic, copy, nullable) void(^didClose)(NSError* _Nullable);
@property (nonatomic, copy, nullable) void(^streamHasSpaceAvailable)(void);

- (instancetype _Nullable)initWithFilePath:(NSString * _Nonnull)filePath;
- (NSInteger)writeToStreamWithBuffer:(nonnull const uint8_t*)buffer maxLength:(NSUInteger)length;
- (BOOL)open;
- (void)close;

@end

NS_ASSUME_NONNULL_END
