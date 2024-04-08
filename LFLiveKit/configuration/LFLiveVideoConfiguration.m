//
//  LFLiveVideoConfiguration.m
//  LFLiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import "LFLiveVideoConfiguration.h"
#import <AVFoundation/AVFoundation.h>

CGSize videoSizeOf(LFLiveVideoSessionPreset prsent)
{
    CGSize videoSize = CGSizeZero;
    switch (prsent) {
    case LFCaptureSessionPreset360x640: {
        videoSize = CGSizeMake(360, 640);
    } break;
    case LFCaptureSessionPreset540x960: {
        videoSize = CGSizeMake(540, 960);
    } break;
    case LFCaptureSessionPreset720x1280: {
        videoSize = CGSizeMake(720, 1280);
    } break;
    case LFCaptureSessionPreset1920x1080: {
        videoSize = CGSizeMake(1080, 1920);
    } break;
    case LFCaptureSessionPreset3840x2160: {
        videoSize = CGSizeMake(2160, 3840);
    } break;
    default: {
        videoSize = CGSizeMake(360, 640);
    } break;
    }
    return videoSize;
}

AVCaptureSessionPreset avSessionPresetOf(LFLiveVideoSessionPreset prsent)
{
    AVCaptureSessionPreset avSessionPreset = nil;
    switch (prsent) {
    case LFCaptureSessionPreset360x640: {
        avSessionPreset = AVCaptureSessionPreset640x480;
    } break;
    case LFCaptureSessionPreset540x960: {
        avSessionPreset = AVCaptureSessionPresetiFrame960x540;
    } break;
    case LFCaptureSessionPreset720x1280: {
        avSessionPreset = AVCaptureSessionPreset1280x720;
    } break;
    case LFCaptureSessionPreset1920x1080: {
        avSessionPreset = AVCaptureSessionPreset1920x1080;
    } break;
    case LFCaptureSessionPreset3840x2160: {
        avSessionPreset = AVCaptureSessionPreset3840x2160;
    } break;
    default: {
        avSessionPreset = AVCaptureSessionPreset640x480;
    } break;
    }
    return avSessionPreset;
}

LFLiveVideoQuality makeVideoQuality(BOOL high, LFLiveVideoSessionPreset preset)
{
    return (LFLiveVideoQuality){
        .high = high,
        .preset = preset,
    };
}

@implementation LFLiveVideoConfiguration

#pragma mark-- LifeCycle

+ (instancetype)defaultConfiguration
{
    LFLiveVideoQuality quality = makeVideoQuality(YES, LFCaptureSessionPreset360x640);
    LFLiveVideoConfiguration *configuration = [LFLiveVideoConfiguration defaultConfigurationForQuality:quality];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(LFLiveVideoQuality)videoQuality
{
    LFLiveVideoConfiguration *configuration = [LFLiveVideoConfiguration defaultConfigurationForQuality:videoQuality outputImageOrientation:UIInterfaceOrientationPortrait];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(LFLiveVideoQuality)videoQuality outputImageOrientation:(UIInterfaceOrientation)outputImageOrientation
{
    LFLiveVideoConfiguration *configuration = [LFLiveVideoConfiguration new];

    NSUInteger fps = videoQuality.high ? 30 : 24;
    configuration.videoFrameRate = fps;
    configuration.videoMaxFrameRate = fps;
    configuration.videoMinFrameRate = fps / 2;

    configuration.sessionPreset = [configuration supportSessionPreset:videoQuality.preset];
    configuration.videoMaxKeyframeInterval = configuration.videoFrameRate * 2;
    configuration.outputImageOrientation = outputImageOrientation;

    CGSize size = videoSizeOf(configuration.sessionPreset);

    if (configuration.landscape) {
        configuration.videoSize = CGSizeMake(size.height, size.width);
    } else {
        configuration.videoSize = CGSizeMake(size.width, size.height);
    }

    NSUInteger bitRate = (NSUInteger)size.width * ((NSUInteger)size.width) * 3 * 4;
    if (!videoQuality.high) {
        bitRate *= 0.8;
    }
    configuration.videoBitRate = bitRate;
    configuration.videoMaxBitRate = bitRate * 1.5;
    configuration.videoMinBitRate = bitRate * 0.7;

    return configuration;
}

- (BOOL)landscape
{
    return UIInterfaceOrientationIsLandscape(_outputImageOrientation);
}

- (CGSize)videoSize
{
    if (_videoSizeRespectingAspectRatio) {
        return self.aspectRatioVideoSize;
    }
    return _videoSize;
}

- (void)setVideoMaxBitRate:(NSUInteger)videoMaxBitRate
{
    if (videoMaxBitRate <= _videoBitRate)
        return;
    _videoMaxBitRate = videoMaxBitRate;
}

- (void)setVideoMinBitRate:(NSUInteger)videoMinBitRate
{
    if (videoMinBitRate >= _videoBitRate)
        return;
    _videoMinBitRate = videoMinBitRate;
}

- (void)setVideoMaxFrameRate:(NSUInteger)videoMaxFrameRate
{
    if (videoMaxFrameRate <= _videoFrameRate)
        return;
    _videoMaxFrameRate = videoMaxFrameRate;
}

- (void)setVideoMinFrameRate:(NSUInteger)videoMinFrameRate
{
    if (videoMinFrameRate >= _videoFrameRate)
        return;
    _videoMinFrameRate = videoMinFrameRate;
}

- (void)setSessionPreset:(LFLiveVideoSessionPreset)sessionPreset
{
    _sessionPreset = sessionPreset; // [self supportSessionPreset:sessionPreset];
}

#pragma mark-- Custom Method
- (LFLiveVideoSessionPreset)supportSessionPreset:(LFLiveVideoSessionPreset)sessionPreset
{
    AVCaptureDevice *inputCamera;

    AVCaptureDeviceDiscoverySession *discoverySession =
        [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                                                               mediaType:AVMediaTypeVideo
                                                                position:AVCaptureDevicePositionUnspecified];

    NSArray *devices = discoverySession.devices;

    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            inputCamera = device;
        }
    }

    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];

    AVCaptureSession *session = [[AVCaptureSession alloc] init];

    if ([session canAddInput:videoInput]) {
        [session addInput:videoInput];
    }

    for (NSInteger idx = sessionPreset; idx >= 0; --idx) {
        LFLiveVideoSessionPreset preset = (LFLiveVideoSessionPreset)idx;
        AVCaptureSessionPreset avPreset = avSessionPresetOf(preset);
        if ([session canSetSessionPreset:avPreset]) {
            return preset;
        }
    }

    return LFCaptureSessionPreset360x640;
}

- (CGSize)captureOutVideoSize
{
    CGSize videoSize = videoSizeOf(_sessionPreset);

    if (self.landscape) {
        return CGSizeMake(videoSize.height, videoSize.width);
    }

    return videoSize;
}

- (AVCaptureSessionPreset)avSessionPreset
{
    return avSessionPresetOf(_sessionPreset);
}

- (CGSize)aspectRatioVideoSize
{
    CGSize size = AVMakeRectWithAspectRatioInsideRect(self.captureOutVideoSize,
                                                      CGRectMake(0, 0, _videoSize.width, _videoSize.height))
                      .size;
    NSInteger width = ceil(size.width);
    NSInteger height = ceil(size.height);
    if (width % 2 != 0)
        width = width - 1;
    if (height % 2 != 0)
        height = height - 1;
    return CGSizeMake(width, height);
}

#pragma mark-- encoder
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSValue valueWithCGSize:self.videoSize] forKey:@"videoSize"];
    [aCoder encodeObject:@(self.videoFrameRate) forKey:@"videoFrameRate"];
    [aCoder encodeObject:@(self.videoMaxFrameRate) forKey:@"videoMaxFrameRate"];
    [aCoder encodeObject:@(self.videoMinFrameRate) forKey:@"videoMinFrameRate"];
    [aCoder encodeObject:@(self.videoMaxKeyframeInterval) forKey:@"videoMaxKeyframeInterval"];
    [aCoder encodeObject:@(self.videoBitRate) forKey:@"videoBitRate"];
    [aCoder encodeObject:@(self.videoMaxBitRate) forKey:@"videoMaxBitRate"];
    [aCoder encodeObject:@(self.videoMinBitRate) forKey:@"videoMinBitRate"];
    [aCoder encodeObject:@(self.sessionPreset) forKey:@"sessionPreset"];
    [aCoder encodeObject:@(self.outputImageOrientation) forKey:@"outputImageOrientation"];
    [aCoder encodeObject:@(self.autorotate) forKey:@"autorotate"];
    [aCoder encodeObject:@(self.videoSizeRespectingAspectRatio) forKey:@"videoSizeRespectingAspectRatio"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    _videoSize = [[aDecoder decodeObjectForKey:@"videoSize"] CGSizeValue];
    _videoFrameRate = [[aDecoder decodeObjectForKey:@"videoFrameRate"] unsignedIntegerValue];
    _videoMaxFrameRate = [[aDecoder decodeObjectForKey:@"videoMaxFrameRate"] unsignedIntegerValue];
    _videoMinFrameRate = [[aDecoder decodeObjectForKey:@"videoMinFrameRate"] unsignedIntegerValue];
    _videoMaxKeyframeInterval = [[aDecoder decodeObjectForKey:@"videoMaxKeyframeInterval"] unsignedIntegerValue];
    _videoBitRate = [[aDecoder decodeObjectForKey:@"videoBitRate"] unsignedIntegerValue];
    _videoMaxBitRate = [[aDecoder decodeObjectForKey:@"videoMaxBitRate"] unsignedIntegerValue];
    _videoMinBitRate = [[aDecoder decodeObjectForKey:@"videoMinBitRate"] unsignedIntegerValue];
    _sessionPreset = [[aDecoder decodeObjectForKey:@"sessionPreset"] unsignedIntegerValue];
    _outputImageOrientation = [[aDecoder decodeObjectForKey:@"outputImageOrientation"] unsignedIntegerValue];
    _autorotate = [[aDecoder decodeObjectForKey:@"autorotate"] boolValue];
    _videoSizeRespectingAspectRatio = [[aDecoder decodeObjectForKey:@"videoSizeRespectingAspectRatio"] unsignedIntegerValue];
    return self;
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    NSArray *values = @[ [NSValue valueWithCGSize:self.videoSize],
                         @(self.videoFrameRate),
                         @(self.videoMaxFrameRate),
                         @(self.videoMinFrameRate),
                         @(self.videoMaxKeyframeInterval),
                         @(self.videoBitRate),
                         @(self.videoMaxBitRate),
                         @(self.videoMinBitRate),
                         self.avSessionPreset,
                         @(self.sessionPreset),
                         @(self.outputImageOrientation),
                         @(self.autorotate),
                         @(self.videoSizeRespectingAspectRatio) ];

    for (NSObject *value in values) {
        hash ^= value.hash;
    }
    return hash;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        LFLiveVideoConfiguration *object = other;
        return CGSizeEqualToSize(object.videoSize, self.videoSize) &&
               object.videoFrameRate == self.videoFrameRate &&
               object.videoMaxFrameRate == self.videoMaxFrameRate &&
               object.videoMinFrameRate == self.videoMinFrameRate &&
               object.videoMaxKeyframeInterval == self.videoMaxKeyframeInterval &&
               object.videoBitRate == self.videoBitRate &&
               object.videoMaxBitRate == self.videoMaxBitRate &&
               object.videoMinBitRate == self.videoMinBitRate &&
               [object.avSessionPreset isEqualToString:self.avSessionPreset] &&
               object.sessionPreset == self.sessionPreset &&
               object.outputImageOrientation == self.outputImageOrientation &&
               object.autorotate == self.autorotate &&
               object.videoSizeRespectingAspectRatio == self.videoSizeRespectingAspectRatio;
    }
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    LFLiveVideoConfiguration *other = [self.class defaultConfiguration];
    return other;
}

- (NSString *)description
{
    NSMutableString *desc = @"".mutableCopy;
    [desc appendFormat:@"<LFLiveVideoConfiguration: %p>", self];
    [desc appendFormat:@" videoSize:%@", NSStringFromCGSize(self.videoSize)];
    [desc appendFormat:@" videoSizeRespectingAspectRatio:%@", @(self.videoSizeRespectingAspectRatio)];
    [desc appendFormat:@" videoFrameRate:%zi", self.videoFrameRate];
    [desc appendFormat:@" videoMaxFrameRate:%zi", self.videoMaxFrameRate];
    [desc appendFormat:@" videoMinFrameRate:%zi", self.videoMinFrameRate];
    [desc appendFormat:@" videoMaxKeyframeInterval:%zi", self.videoMaxKeyframeInterval];
    [desc appendFormat:@" videoBitRate:%zi", self.videoBitRate];
    [desc appendFormat:@" videoMaxBitRate:%zi", self.videoMaxBitRate];
    [desc appendFormat:@" videoMinBitRate:%zi", self.videoMinBitRate];
    [desc appendFormat:@" avSessionPreset:%@", self.avSessionPreset];
    [desc appendFormat:@" sessionPreset:%zi", self.sessionPreset];
    [desc appendFormat:@" outputImageOrientation:%zi", self.outputImageOrientation];
    [desc appendFormat:@" autorotate:%@", @(self.autorotate)];
    return desc;
}

@end
