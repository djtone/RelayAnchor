//
//  CameraSessionView.h
//  RelayAnchor
//
//  Created by chuck johnston on 3/10/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface CameraSessionView : UIView

@property (nonatomic) AVCaptureSession * session;

@end
