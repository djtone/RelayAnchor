//
//  myCameraPreview.m
//  RelaySeller
//
//  Created by chuck johnston on 2/19/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "myCameraPreview.h"
#import <AVFoundation/AVFoundation.h>

@implementation myCameraPreview

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
    return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session
{
    [(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}

@end
