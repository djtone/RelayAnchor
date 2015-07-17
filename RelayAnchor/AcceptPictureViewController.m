//
//  AcceptPictureViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 3/10/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "AcceptPictureViewController.h"
#import "ItemDetailViewController.h"

@implementation AcceptPictureViewController

- (IBAction)retakeAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)usePhotoAction:(id)sender
{
    UIImage * tmpReceiptImage = [[UIImage alloc] init];
    tmpReceiptImage = self.myImageView.image;
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    UIViewController <receiptCameraDelegate> * tmpVC = (UIViewController <receiptCameraDelegate> *)[[self presentingViewController] presentingViewController];
    [tmpVC dismissViewControllerAnimated:YES completion:^
    {
        [tmpVC didFinishTakingReceiptPicture:tmpReceiptImage];
    }];
    
//    ItemDetailViewController * tmpItemDetailVC = (ItemDetailViewController *)[[self presentingViewController ] presentingViewController];
//    [tmpItemDetailVC dismissViewControllerAnimated:YES completion:^
//    {
//        [tmpItemDetailVC didFinishTakingPicture:tmpReceiptImage];
//    }];
}

@end
