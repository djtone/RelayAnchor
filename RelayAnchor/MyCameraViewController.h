//
//  MyCameraViewController.h
//  RelayAnchor
//
//  Created by chuck johnston on 3/10/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CameraSessionView.h"

@interface MyCameraViewController : UIViewController

@property (weak, nonatomic) IBOutlet CameraSessionView * myCameraSessionView;
@property (weak, nonatomic) IBOutlet UIView *cropView;
@property (weak, nonatomic) IBOutlet UIView *cropAlphaViewTop;
@property (weak, nonatomic) IBOutlet UIView *cropAlphaViewLeft;
@property (weak, nonatomic) IBOutlet UIView *cropAlphaViewRight;
@property (weak, nonatomic) IBOutlet UIView *cropAlphaViewBottom;
@property (weak, nonatomic) IBOutlet UIImageView *cropAdjusterTopLeft;
@property (weak, nonatomic) IBOutlet UIImageView *cropAdjusterBottomRight;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;

#pragma mark - crop adjusting
@property CGPoint dragPointOffset;
@property UIPanGestureRecognizer * dragCropViewGesture;
@property UIPanGestureRecognizer * cropAdjusterGestureTopLeft;
@property UIPanGestureRecognizer * cropAdjusterGestureBottomRight;

@property UIImage * croppedImage;

- (IBAction)cancelAction:(id)sender;

@end
