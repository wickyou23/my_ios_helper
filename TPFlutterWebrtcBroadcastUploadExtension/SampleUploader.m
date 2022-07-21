//
//  SampleUploader.m
//  flutterWebrtcExtension
//
//  Created by Thang Phung on 18/07/2022.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import "SampleUploader.h"
#import "Utils.h"
#import "SocketConnection.h"

#define kBufferMaxLength 1024

@interface SampleUploader ()

@property (nonatomic, class, strong, readonly) CIContext* imageContext;

@property (nonatomic, strong) SocketConnection* connection;
@property (nonatomic, strong) NSData* dataToSend;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, assign) NSUInteger byteIndex;
@property (atomic, assign) BOOL isReady;

@end

@implementation SampleUploader

static CIContext* _imageContext = NULL;

+ (CIContext*)imageContext
{
    if (_imageContext == NULL) {
        _imageContext = [[CIContext alloc] init];
    }
    
    return _imageContext;
}

- (instancetype)initWithConnection:(SocketConnection*)connection
{
    self = [super init];
    if (self) {
        _isReady = NO;
        _connection = connection;
        _serialQueue = dispatch_queue_create("org.tp.meet.broadcast.sampleUploader", DISPATCH_QUEUE_SERIAL);
        
        [self setupConnectionCallBack];
    }
    
    return self;
}

- (BOOL)sendSampleBuffer:(CMSampleBufferRef)buffer
{
    if (!_isReady) {
        return NO;
    }
    
    _isReady = NO;
    _dataToSend = [self prepareSampleBuffer:buffer];
    _byteIndex = 0;
    
    exLog(@"=============== Data Length: %0.2luKB", (unsigned long)([_dataToSend length]/1024));
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_serialQueue, ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf sendDataChunk];
        }
    });
    
    return YES;
}

- (NSData* _Nullable)prepareSampleBuffer:(CMSampleBufferRef)buffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(buffer);
    if (!imageBuffer) {
        exLog(@"image buffer not available");
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    CGFloat scaleFactor = 2.0;
    size_t height = CVPixelBufferGetHeight(imageBuffer) / (int)scaleFactor;
    size_t width = CVPixelBufferGetWidth(imageBuffer) / (int)scaleFactor;
    CFTypeRef orientation = CMGetAttachment(buffer, (__bridge CFStringRef)RPVideoSampleOrientationKey, NULL);
    CGAffineTransform scaleTransform = CGAffineTransformScale(CGAffineTransformIdentity, (CGFloat)1.0/scaleFactor, (CGFloat)1.0/scaleFactor);
    NSData* bufferData = [self jpegDataWithBuffer:imageBuffer scaleTransform:scaleTransform];
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    if (!bufferData) {
        exLog("corrupted image buffer")
        return NULL;
    }
    
    CFHTTPMessageRef httpResponse = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_1);
    CFHTTPMessageSetHeaderFieldValue(httpResponse, (__bridge CFStringRef)@"Content-Length", (__bridge CFStringRef)[@(bufferData.length) stringValue]);
    CFHTTPMessageSetHeaderFieldValue(httpResponse, (__bridge CFStringRef)@"Buffer-Width", (__bridge CFStringRef)[@(width) stringValue]);
    CFHTTPMessageSetHeaderFieldValue(httpResponse, (__bridge CFStringRef)@"Buffer-Height", (__bridge CFStringRef)[@(height) stringValue]);
    if (CFGetTypeID(orientation) == CFNumberGetTypeID()) {
        CFHTTPMessageSetHeaderFieldValue(httpResponse, (__bridge CFStringRef)@"Buffer-Orientation", (__bridge CFStringRef)[(__bridge NSNumber *)orientation stringValue]);
    }
    
    CFHTTPMessageSetBody(httpResponse, (__bridge CFDataRef)bufferData);
    
    CFDataRef serializedMessage = CFHTTPMessageCopySerializedMessage(httpResponse);
    NSData* serializedData = (__bridge NSData*)serializedMessage;
    
    CFRelease(serializedMessage);
    CFRelease(httpResponse);
    return serializedData;
}

- (NSData* _Nullable)jpegDataWithBuffer:(CVPixelBufferRef)buffer scaleTransform:(CGAffineTransform)scale
{
    CIImage* image = [[[CIImage alloc] initWithCVPixelBuffer:buffer] imageByApplyingTransform:scale];
    CGColorSpaceRef colorSpace = image.colorSpace;
    if (!colorSpace) {
        return NULL;
    }
    
    return [SampleUploader.imageContext JPEGRepresentationOfImage:image
                                                       colorSpace:colorSpace
                                                          options:@{(CIImageRepresentationOption)kCGImageDestinationLossyCompressionQuality: @1.0}];
}

- (void)setupConnectionCallBack
{
    __weak typeof(self) weakSelf = self;
    _connection.didOpen = ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.isReady = YES;
        }
    };
    
    _connection.streamHasSpaceAvailable = ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            dispatch_async(strongSelf.serialQueue, ^{
                if (strongSelf) {
                    strongSelf.isReady = ![strongSelf sendDataChunk];
                }
            });
        }
    };
}

- (BOOL)sendDataChunk
{
    if (_dataToSend == NULL) {
        return NO;
    }
    
    NSUInteger bytesLeft = _dataToSend.length - _byteIndex;
    NSUInteger length = bytesLeft > kBufferMaxLength ? kBufferMaxLength : bytesLeft;
    
    uint8_t* bytes = (uint8_t*)malloc(length);
    [_dataToSend getBytes:bytes range:NSMakeRange(_byteIndex, length)];
    length = [_connection writeToStreamWithBuffer:bytes maxLength:length];
    free(bytes);
    
//    exLog(@"==========================================");
//    exLog(@"Byte Index: %lu", (unsigned long)_byteIndex);
//    exLog(@"Byte remain: %lu", (unsigned long)bytesLeft);
//    exLog(@"Byte sent: %lu", (unsigned long)length);
//    exLog(@"==========================================");
    
    if (length > 0) {
        _byteIndex += length;
        bytesLeft -= length;
        
        if (bytesLeft == 0) {
            _dataToSend = NULL;
            _byteIndex = 0;
            return NO;
        }
    }
    else {
        exLog("writeBufferToStream failure");
    }
    
    return YES;
}

@end
