//
//  SampleHandler.m
//  flutterWebrtcExtension
//
//  Created by Thang Phung on 15/07/2022.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#include <sys/socket.h>
#include <sys/un.h>

#import "SampleHandler.h"
#import "SocketConnection.h"
#import "SampleUploader.h"
#import "DarwinNotificationCenter.h"
#import "Utils.h"

NSString* const kRTCScreensharingSocketFD = @"rtc_SSFD";

@interface SampleHandler () <NSStreamDelegate>

@property (nonatomic, strong) SocketConnection* clientConnection;
@property (nonatomic, strong) SampleUploader* uploader;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, strong, readonly) NSString* socketFilePath;

@end

@implementation SampleHandler

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL* sharedContainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.tp.flutterwebrtc"];
        if (sharedContainer) {
            exLog(@"containerURLForSecurityApplicationGroupIdentifier: group.tp.flutterwebrtc");
            _socketFilePath = [[sharedContainer URLByAppendingPathComponent:kRTCScreensharingSocketFD] path];
            _clientConnection = [[SocketConnection alloc] initWithFilePath:_socketFilePath];
            [self setupConnectionCallback];
            
            _uploader = [[SampleUploader alloc] initWithConnection:_clientConnection];
        }
        else {
            exLog(@"containerURLForSecurityApplicationGroupIdentifier NULL");
        }
    }
    
    return self;
}

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    _frameCount = 0;
    [[DarwinNotificationCenter shared] postNotification:kBroadcastStarted];
    [self openConnection];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    
    [[DarwinNotificationCenter shared] postNotification:kBroadcastStopped];
    [_clientConnection close];
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
        {
            _frameCount += 1;
            if (_frameCount == 3) {
                [_uploader sendSampleBuffer:sampleBuffer];
                _frameCount = 0;
            }
        }
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;
        default:
            break;
    }
}

- (void)openConnection
{
    dispatch_queue_t queue = dispatch_queue_create("broadcast.connectTimer", DISPATCH_QUEUE_SERIAL);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), 100 * NSEC_PER_MSEC, 500 * NSEC_PER_MSEC);
    
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            if (![strongSelf.clientConnection open]) {
                return;
            }
            
            dispatch_source_cancel(timer);
        }
    });
    
    dispatch_resume(timer);
}

- (void)setupConnectionCallback
{
    __weak typeof(self) weakSelf = self;
    _clientConnection.didClose = ^(NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            exLog(@"client connection did close %@", [error localizedDescription]);
            if (error) {
                [strongSelf finishBroadcastWithError:error];
            }
            else {
                NSInteger screenSharingStopped = 1991;
                NSError* error = [[NSError alloc] initWithDomain:RPRecordingErrorDomain
                                                            code:screenSharingStopped
                                                        userInfo:@{NSLocalizedDescriptionKey: @"Screen sharing stopped"}];
                [strongSelf finishBroadcastWithError:error];
            }
        }
    };
}

@end
