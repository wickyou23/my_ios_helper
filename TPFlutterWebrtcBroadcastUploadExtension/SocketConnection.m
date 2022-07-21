//
//  SocketConnection.m
//  flutterWebrtcExtension
//
//  Created by Thang Phung on 18/07/2022.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import "SocketConnection.h"
#import "Utils.h"

#include <sys/socket.h>
#include <sys/un.h>

@interface SocketConnection () <NSStreamDelegate>

@property (nonatomic, strong) NSString* filePath;
@property (nonatomic, assign) int socketHandle;
@property (nonatomic, strong) NSInputStream* _Nullable inputStream;
@property (nonatomic, strong) NSOutputStream* _Nullable outputStream;
@property (nonatomic, strong) dispatch_queue_t networkQueue;
@property (nonatomic, assign) BOOL shouldKeepRunning;
@property (nonatomic, assign) struct sockaddr_un address;

@end

@implementation SocketConnection

- (instancetype _Nullable)initWithFilePath:(NSString * _Nonnull)filePath
{
    self = [super init];
    if (self) {
        _filePath = filePath;
        _socketHandle = socket(AF_UNIX, SOCK_STREAM, 0);
        if (_socketHandle == -1) {
            exLog(@"[EXTENSION] failure: create socket");
            return NULL;
        }
    }
    
    return self;
}

- (BOOL)open
{
    exLog(@"open socket connection");
    if (![[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
        exLog(@"failure: socket file missing");
        return NO;
    }
    
    if (![self setupAddress]) {
        return NO;
    }
    
    if (![self connectSocket]) {
        return NO;
    }
    
    [self setupStreams];
    
    [_inputStream open];
    [_outputStream open];
    
    return YES;
}

- (void)close
{
    [self unscheduleStreams];
    
    _inputStream.delegate = NULL;
    _outputStream.delegate = NULL;
    
    [_inputStream close];
    [_outputStream close];
    
    _inputStream = NULL;
    _outputStream = NULL;
}

- (NSInteger)writeToStreamWithBuffer:(nonnull const uint8_t*)buffer maxLength:(NSUInteger)length
{
    return [_outputStream write:buffer maxLength:length];
}

//MARK: - STREAM DELEGATE

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            exLog(@"server stream open completed");
            if (aStream == _outputStream) {
                if (_didOpen) {
                    _didOpen();
                }
            }
        }
            
            break;
        case NSStreamEventHasBytesAvailable: {
            exLog(@"server stream event has bytes available");
            if (aStream == _inputStream) {
                uint8_t buffer = 0;
                NSInteger numberOfBytesRead = [_inputStream read:&buffer maxLength:1];
                if (numberOfBytesRead == 0 && [aStream streamStatus] == kCFStreamStatusAtEnd) {
                    exLog(@"server socket closed");
                    close(_socketHandle);
                    if (_didClose) {
                        _didClose(NULL);
                    }
                }
            }
        }
            break;
        case NSStreamEventHasSpaceAvailable: {
            if (aStream == _outputStream) {
                if (_streamHasSpaceAvailable) {
                    _streamHasSpaceAvailable();
                }
            }
        }
            break;
        case NSStreamEventEndEncountered:
            exLog(@"server stream end encountered");
            break;
        case NSStreamEventErrorOccurred: {
            exLog(@"server stream error encountered: %@", aStream.streamError.localizedDescription);
            close(_socketHandle);
            if (_didClose) {
                _didClose(aStream.streamError);
            }
        }
            break;
        default:
            break;
    }
}

//MARK: - PRIVATE FUNCTION

- (BOOL)setupAddress
{
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    
    if (_filePath.length > sizeof(addr.sun_path)) {
        exLog(@"[EXTENSION] failure: path too long");
        return false;
    }
    
    strncpy(addr.sun_path, _filePath.UTF8String, sizeof(addr.sun_path) - 1);
    
    _address = addr;
    return true;
}

- (BOOL)connectSocket
{
    int status = connect(_socketHandle, (struct sockaddr *)&_address, sizeof(_address));
    if (status < 0) {
        exLog(@"failure: socket connect %s", strerror(errno));
        return NO;
    }
    else {
        exLog(@"susscesfully: Socket connect");
        return YES;
    }
}

- (void)setupStreams
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, _socketHandle, &readStream, &writeStream);
    
    _inputStream = (__bridge_transfer NSInputStream *)readStream;
    _inputStream.delegate = self;
    [_inputStream setProperty:@"kCFBooleanTrue" forKey:@"kCFStreamPropertyShouldCloseNativeSocket"];

    _outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    _outputStream.delegate = self;
    [_outputStream setProperty:@"kCFBooleanTrue" forKey:@"kCFStreamPropertyShouldCloseNativeSocket"];

    [self scheduleStreams];
}

- (void)scheduleStreams
{
    _shouldKeepRunning = YES;
    _networkQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_networkQueue, ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.inputStream scheduleInRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
            [strongSelf.outputStream scheduleInRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
            
            [[NSRunLoop currentRunLoop] run];
            
            BOOL isRunning = NO;
            
            do {
                isRunning = strongSelf.shouldKeepRunning && [[NSRunLoop currentRunLoop] runMode:NSRunLoopCommonModes beforeDate:[NSDate distantFuture]];
            } while (isRunning);
        }
    });
}

- (void)unscheduleStreams {
    __weak typeof(self) weakSelf = self;
    dispatch_sync(_networkQueue, ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.inputStream removeFromRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
            [strongSelf.outputStream removeFromRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
        }
    });
    
    _shouldKeepRunning = false;
}

@end
