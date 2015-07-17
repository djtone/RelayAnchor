//
//  myCameraPreview.h
//  RelaySeller
//
//  Created by chuck johnston on 2/19/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface myCameraPreview : UIView

@property (nonatomic) AVCaptureSession * session;

@end
