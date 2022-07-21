//
//  Utils.h
//  flutterWebrtcExtension
//
//  Created by Thang Phung on 18/07/2022.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

#define exLog(fmt, ...) NSLog((@"[EXT-APP] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject

@end

NS_ASSUME_NONNULL_END
