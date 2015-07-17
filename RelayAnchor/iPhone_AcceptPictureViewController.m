//
//  iPhone_AcceptPictureViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 7/6/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_AcceptPictureViewController.h"


@implementation iPhone_AcceptPictureViewController

- (IBAction)retakeAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)usePhotoAction:(id)sender
{
    UIImage * tmpReceiptImage = [[UIImage alloc] init];
    tmpReceiptImage = self.myImageView.image;
    UIViewController <iPhoneReceiptCameraDelegate> * tmpVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-3];
    [self.navigationController popToViewController:tmpVC animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [tmpVC didFinishTakingReceiptPicture:tmpReceiptImage];
}

@end
