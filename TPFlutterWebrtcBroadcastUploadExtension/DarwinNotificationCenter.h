//
//  DarwinNotificationCenter.h
//  flutterWebrtcExtension
//
//  Created by Thang Phung on 18/07/2022.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kBroadcastStarted @"iOS_BroadcastStarted"
#define kBroadcastStopped @"iOS_BroadcastStopped"

NS_ASSUME_NONNULL_BEGIN

@interface DarwinNotificationCenter : NSObject

+ (instancetype)shared;

- (void)postNotification:(NSString*)nameNotification;

@end

NS_ASSUME_NONNULL_END
