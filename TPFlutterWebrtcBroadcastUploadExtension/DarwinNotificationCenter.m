//
//  DarwinNotificationCenter.m
//  flutterWebrtcExtension
//
//  Created by Thang Phung on 18/07/2022.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import "DarwinNotificationCenter.h"

@interface DarwinNotificationCenter ()

@property (nonatomic, assign) CFNotificationCenterRef notificationCenter;

@end

@implementation DarwinNotificationCenter

+ (instancetype)shared
{
    static dispatch_once_t onceToken = 0;
    static id _sharedObject = nil;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[self alloc] init];
    });
    
    return _sharedObject;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _notificationCenter = CFNotificationCenterGetDarwinNotifyCenter();
    }
    
    return self;
}

- (void)postNotification:(NSString*)nameNotification
{
    CFNotificationCenterPostNotification(_notificationCenter, (__bridge CFStringRef)nameNotification, NULL, NULL, YES);
}

@end
