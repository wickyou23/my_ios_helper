//
//  SampleUploader.h
//  flutterWebrtcExtension
//
//  Created by Thang Phung on 18/07/2022.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

#import "SocketConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface SampleUploader : NSObject

- (instancetype)initWithConnection:(SocketConnection*)connection;

- (BOOL)sendSampleBuffer:(CMSampleBufferRef)buffer;

@end

NS_ASSUME_NONNULL_END
