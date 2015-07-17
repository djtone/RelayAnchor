//
//  iPhone_MyCameraPreviewViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 7/6/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_MyCameraPreviewViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "iPhone_AcceptPictureViewController.h"

@implementation iPhone_MyCameraPreviewViewController

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * RecordingContext = &RecordingContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    // Create the AVCaptureSession
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [self setSession:session];
    
    // Setup the preview view
    [[self myCameraSessionView] setSession:session];
    [(AVCaptureVideoPreviewLayer *)[self.myCameraSessionView layer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.cropAdjusterGestureTopLeft = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(adjustCropView:)];
    [self.cropAdjusterTopLeft addGestureRecognizer:self.cropAdjusterGestureTopLeft];
    self.cropAdjusterGestureBottomRight = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(adjustCropView:)];
    [self.cropAdjusterBottomRight addGestureRecognizer:self.cropAdjusterGestureBottomRight];
    
    //more ui stuff
    self.myCameraSessionView.backgroundColor = [UIColor blackColor]; //this prevents a screen flicker. but if its set to black in the storyboard, then it is difficult to see the other views
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    
    // Check for device authorization
    [self checkDeviceAuthorizationStatus];
    
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
    
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:sessionQueue];
    
    dispatch_async(sessionQueue, ^{
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [iPhone_MyCameraPreviewViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if (error)
        {
            NSLog(@"%@", error);
        }
        
        if ([session canAddInput:videoDeviceInput])
        {
            [session addInput:videoDeviceInput];
            [self setVideoDeviceInput:videoDeviceInput];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Why are we dispatching this to the main queue?
                // Because AVCaptureVideoPreviewLayer is the backing layer for AVCammyCameraSessionView and UIView can only be manipulated on main thread.
                // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                
                [[(AVCaptureVideoPreviewLayer *)[[self myCameraSessionView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
            });
        }
        
        AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        if (error)
        {
            NSLog(@"%@", error);
        }
        
        if ([session canAddInput:audioDeviceInput])
        {
            [session addInput:audioDeviceInput];
        }
        
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ([session canAddOutput:movieFileOutput])
        {
            [session addOutput:movieFileOutput];
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([connection isVideoStabilizationSupported])
                [connection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeStandard];
            [self setMovieFileOutput:movieFileOutput];
        }
        
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ([session canAddOutput:stillImageOutput])
        {
            [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
            [session addOutput:stillImageOutput];
            [self setStillImageOutput:stillImageOutput];
        }
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    dispatch_async([self sessionQueue], ^{
        [self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
        [self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
        [self addObserver:self forKeyPath:@"movieFileOutput.recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
        
        __weak iPhone_MyCameraPreviewViewController *weakSelf = self;
        [self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
            iPhone_MyCameraPreviewViewController *strongSelf = weakSelf;
            dispatch_async([strongSelf sessionQueue], ^{
                // Manually restarting the session since it must have been stopped due to an error.
                [[strongSelf session] startRunning];
                //[[strongSelf recordButton] setTitle:NSLocalizedString(@"Record", @"Recording button record title") forState:UIControlStateNormal];
            });
        }]];
        [[self session] startRunning];
    });
}

- (void)viewDidDisappear:(BOOL)animated
{
    dispatch_async([self sessionQueue], ^{
        [[self session] stopRunning];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
        [[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
        
        [self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
        [self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
        [self removeObserver:self forKeyPath:@"movieFileOutput.recording" context:RecordingContext];
    });
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [[(AVCaptureVideoPreviewLayer *)[[self myCameraSessionView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == CapturingStillImageContext)
    {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        
        if (isCapturingStillImage)
        {
            [self runStillImageCaptureAnimation];
        }
    }
    else if (context == RecordingContext)
    {
        BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isRecording)
            {
                //[[self cameraButton] setEnabled:NO];
                //[[self recordButton] setTitle:NSLocalizedString(@"Stop", @"Recording button stop title") forState:UIControlStateNormal];
                //[[self recordButton] setEnabled:YES];
            }
            else
            {
                //[[self cameraButton] setEnabled:YES];
                //[[self recordButton] setTitle:NSLocalizedString(@"Record", @"Recording button record title") forState:UIControlStateNormal];
                //[[self recordButton] setEnabled:YES];
            }
        });
    }
    else if (context == SessionRunningAndDeviceAuthorizedContext)
    {
        BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isRunning)
            {
                //[[self cameraButton] setEnabled:YES];
                //[[self recordButton] setEnabled:YES];
                //[[self stillButton] setEnabled:YES];
            }
            else
            {
                //[[self cameraButton] setEnabled:NO];
                //[[self recordButton] setEnabled:NO];
                //[[self stillButton] setEnabled:NO];
            }
        });
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Actions
/*
 - (IBAction)toggleMovieRecording:(id)sender
 {
 [[self recordButton] setEnabled:NO];
 
 dispatch_async([self sessionQueue], ^{
 if (![[self movieFileOutput] isRecording])
 {
 [self setLockInterfaceRotation:YES];
 
 if ([[UIDevice currentDevice] isMultitaskingSupported])
 {
 // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
 [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
 }
 
 // Update the orientation on the movie file output video connection before starting recording.
 [[[self movieFileOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self myCameraSessionView] layer] connection] videoOrientation]];
 
 // Turning OFF flash for video recording
 [AVCamViewController setFlashMode:AVCaptureFlashModeOff forDevice:[[self videoDeviceInput] device]];
 
 // Start recording to a temporary file.
 NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[@"movie" stringByAppendingPathExtension:@"mov"]];
 [[self movieFileOutput] startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
 }
 else
 {
 [[self movieFileOutput] stopRecording];
 }
 });
 }
 */

/*
 - (IBAction)changeCamera:(id)sender
 {
 [[self cameraButton] setEnabled:NO];
 [[self recordButton] setEnabled:NO];
 [[self stillButton] setEnabled:NO];
 
 dispatch_async([self sessionQueue], ^{
 AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
 AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
 AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
 
 switch (currentPosition)
 {
 case AVCaptureDevicePositionUnspecified:
 preferredPosition = AVCaptureDevicePositionBack;
 break;
 case AVCaptureDevicePositionBack:
 preferredPosition = AVCaptureDevicePositionFront;
 break;
 case AVCaptureDevicePositionFront:
 preferredPosition = AVCaptureDevicePositionBack;
 break;
 }
 
 AVCaptureDevice *videoDevice = [AVCamViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
 AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
 
 [[self session] beginConfiguration];
 
 [[self session] removeInput:[self videoDeviceInput]];
 if ([[self session] canAddInput:videoDeviceInput])
 {
 [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
 
 [AVCamViewController setFlashMode:AVCaptureFlashModeAuto forDevice:videoDevice];
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
 
 [[self session] addInput:videoDeviceInput];
 [self setVideoDeviceInput:videoDeviceInput];
 }
 else
 {
 [[self session] addInput:[self videoDeviceInput]];
 }
 
 [[self session] commitConfiguration];
 
 dispatch_async(dispatch_get_main_queue(), ^{
 [[self cameraButton] setEnabled:YES];
 [[self recordButton] setEnabled:YES];
 [[self stillButton] setEnabled:YES];
 });
 });
 }
 */

/*
 - (IBAction)snapStillImage:(id)sender
 {
 dispatch_async([self sessionQueue], ^{
 // Update the orientation on the still image output video connection before capturing.
 [[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self myCameraSessionView] layer] connection] videoOrientation]];
 
 // Flash set to Auto for Still Capture
 [AVCamViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[[self videoDeviceInput] device]];
 
 // Capture a still image.
 [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
 
 if (imageDataSampleBuffer)
 {
 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
 UIImage *image = [[UIImage alloc] initWithData:imageData];
 [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];
 }
 }];
 });
 }
 */

/*
 - (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
 {
 CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[[self myCameraSessionView] layer] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
 [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
 }
 */


- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

#pragma mark File Output Delegate
/*
 - (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
 {
 if (error)
 NSLog(@"%@", error);
 
 [self setLockInterfaceRotation:NO];
 
 // Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
 UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
 [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
 
 [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
 if (error)
 NSLog(@"%@", error);
 
 [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
 
 if (backgroundRecordingID != UIBackgroundTaskInvalid)
 [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
 }];
 }
 */

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *device = [[self videoDeviceInput] device];
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
            {
                [device setFocusMode:focusMode];
                [device setFocusPointOfInterest:point];
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
            {
                [device setExposureMode:exposureMode];
                [device setExposurePointOfInterest:point];
            }
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    });
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ([device hasFlash] && [device isFlashModeSupported:flashMode])
    {
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            [device setFlashMode:flashMode];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    }
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

#pragma mark UI

- (void)runStillImageCaptureAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[self myCameraSessionView] layer] setOpacity:0.0];
        [UIView animateWithDuration:.25 animations:^{
            [[[self myCameraSessionView] layer] setOpacity:1.0];
        }];
    });
}

- (void)checkDeviceAuthorizationStatus
{
    NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (granted)
        {
            //Granted access to mediaType
            [self setDeviceAuthorized:YES];
        }
        else
        {
            //Not granted access to mediaType
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"AVCam!"
                                            message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                [self setDeviceAuthorized:NO];
            });
        }
    }];
}


- (BOOL)isSessionRunningAndDeviceAuthorized
{
    return [[self session] isRunning] && [self isDeviceAuthorized];
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
    return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}

#pragma mark - crop adjusting
- (void) adjustCropView:(id)sender
{
    CGPoint touchPoint = [(UIPanGestureRecognizer *)sender locationInView:self.myCameraSessionView];
    
    if ( touchPoint.x < 30 )
        touchPoint.x = 30;
    if ( touchPoint.y < 30 )
        touchPoint.y = 30;
    
    if ( touchPoint.x > (self.myCameraSessionView.frame.size.width - 30))
        touchPoint.x = self.myCameraSessionView.frame.size.width - 30;
    if ( touchPoint.y > (self.myCameraSessionView.frame.size.height - 30))
        touchPoint.y = self.myCameraSessionView.frame.size.height - 30;
    
    if ( sender == self.cropAdjusterGestureTopLeft )
    {
        if ( touchPoint.x > self.cropAdjusterBottomRight.frame.origin.x )
            touchPoint.x = self.cropAdjusterBottomRight.frame.origin.x;
        if ( touchPoint.y > self.cropAdjusterBottomRight.frame.origin.y )
            touchPoint.y = self.cropAdjusterBottomRight.frame.origin.y;
        
        self.cropAdjusterTopLeft.frame = CGRectMake(touchPoint.x - self.cropAdjusterTopLeft.frame.size.width/2,
                                                    touchPoint.y - self.cropAdjusterTopLeft.frame.size.height/2,
                                                    self.cropAdjusterTopLeft.frame.size.width,
                                                    self.cropAdjusterTopLeft.frame.size.height);
    }
    else if ( sender == self.cropAdjusterGestureBottomRight )
    {
        if ( touchPoint.x <= (self.cropAdjusterTopLeft.frame.origin.x + self.cropAdjusterTopLeft.frame.size.width) )
            touchPoint.x = self.cropAdjusterTopLeft.frame.origin.x + self.cropAdjusterTopLeft.frame.size.width;
        if ( touchPoint.y <= (self.cropAdjusterTopLeft.frame.origin.y + self.cropAdjusterTopLeft.frame.size.height) )
            touchPoint.y = self.cropAdjusterTopLeft.frame.origin.y + self.cropAdjusterTopLeft.frame.size.height;
        
        self.cropAdjusterBottomRight.frame = CGRectMake(touchPoint.x - self.cropAdjusterBottomRight.frame.size.width/2,
                                                        touchPoint.y - self.cropAdjusterBottomRight.frame.size.height/2,
                                                        self.cropAdjusterBottomRight.frame.size.width,
                                                        self.cropAdjusterBottomRight.frame.size.height);
    }
    
    self.cropView.frame = CGRectMake(self.cropAdjusterTopLeft.frame.origin.x + self.cropAdjusterTopLeft.frame.size.width - 22,
                                     self.cropAdjusterTopLeft.frame.origin.y + self.cropAdjusterTopLeft.frame.size.height - 22,
                                     (self.cropAdjusterBottomRight.frame.origin.x + 44) - (self.cropAdjusterTopLeft.frame.origin.x + self.cropAdjusterTopLeft.frame.size.width),
                                     (self.cropAdjusterBottomRight.frame.origin.y + 44) - (self.cropAdjusterTopLeft.frame.origin.y + self.cropAdjusterTopLeft.frame.size.height));
    
    self.cropAlphaViewTop.frame = CGRectMake(self.myCameraSessionView.frame.origin.x,
                                             self.cropAlphaViewTop.frame.origin.y,
                                             self.myCameraSessionView.frame.size.width,
                                             self.cropAdjusterTopLeft.frame.origin.y + self.cropAdjusterTopLeft.frame.size.height - 22);
    
    self.cropAlphaViewLeft.frame = CGRectMake(self.myCameraSessionView.frame.origin.x,
                                              self.cropView.frame.origin.y,
                                              self.cropView.frame.origin.x,
                                              self.cropView.frame.size.height);
    
    self.cropAlphaViewRight.frame = CGRectMake(self.cropView.frame.origin.x + self.cropView.frame.size.width,
                                               self.cropView.frame.origin.y,
                                               self.myCameraSessionView.frame.size.width - self.cropAdjusterBottomRight.frame.origin.x,
                                               self.cropView.frame.size.height);
    
    self.cropAlphaViewBottom.frame = CGRectMake(self.myCameraSessionView.frame.origin.x,
                                                self.cropAdjusterBottomRight.frame.origin.y + 22,
                                                self.myCameraSessionView.frame.size.width,
                                                self.myCameraSessionView.frame.size.height - self.cropAdjusterBottomRight.frame.origin.y);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    dispatch_async([self sessionQueue], ^
                   {
                       // Update the orientation on the still image output video connection before capturing.
                       [[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self myCameraSessionView] layer] connection] videoOrientation]];
                       
                       // Flash set to Auto for Still Capture
                       [iPhone_MyCameraPreviewViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[[self videoDeviceInput] device]];
                       
                       // Capture a still image.
                       [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error)
                        {
                            if (imageDataSampleBuffer)
                            {
                                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                UIImage *image = [[UIImage alloc] initWithData:imageData];
                                //[[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];
                                
                                //-- the above code was taken from the apple example application AVCam or something. the below code is what has been added
                                //upright image
                                UIImage * uprightImage = [self rotateImage:[[UIImage alloc] initWithCGImage:image.CGImage scale:1 orientation:UIImageOrientationUp] byDegree:90];
                                
                                //crop the image
                                CGRect cropRect = CGRectMake(self.cropView.frame.origin.x * (image.size.width/self.myCameraSessionView.frame.size.width),
                                                             self.cropView.frame.origin.y * (image.size.height/self.myCameraSessionView.frame.size.height),
                                                             self.cropView.frame.size.width * (image.size.width/self.myCameraSessionView.frame.size.width),
                                                             self.cropView.frame.size.height * (image.size.height/self.myCameraSessionView.frame.size.height));
                                
                                CGImageRef imageRef = CGImageCreateWithImageInRect([uprightImage CGImage], cropRect);
                                UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
                                CGImageRelease(imageRef);
                                
                                [[(iPhone_AcceptPictureViewController *)segue.destinationViewController myImageView] setImage:croppedImage];
                                //--
                            }
                        }];
                   });
}

#define DegreesToRadians(x) (M_PI * (x) / 180.0)
- (UIImage *)rotateImage:(UIImage*)image byDegree:(CGFloat)degrees
{
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(90));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(bitmap, rotatedSize.width, rotatedSize.height);
    CGContextRotateCTM(bitmap, DegreesToRadians(90));
    
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width, -image.size.height, image.size.width, image.size.height), [image CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - misc.
- (IBAction)cancelAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    //self.navigationController.navigationBarHidden = NO;
}


@end
