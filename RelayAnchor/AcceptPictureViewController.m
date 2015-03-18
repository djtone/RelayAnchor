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

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)retakeAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    //[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)usePhotoAction:(id)sender
{
    UIImage * tmpReceiptImage = [[UIImage alloc] init];
    tmpReceiptImage = self.myImageView.image;
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    ItemDetailViewController * tmpItemDetailVC = (ItemDetailViewController *)[[self presentingViewController ] presentingViewController];
    [tmpItemDetailVC dismissViewControllerAnimated:YES completion:^
    {
        [tmpItemDetailVC didFinishTakingPicture:tmpReceiptImage];
    }];
    /*
    iPhone_StoreFrontCategoryViewController * tmpVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-3];
    [self.navigationController popToViewController:tmpVC animated:YES];
    [tmpVC didFinishTakingPicture:tmpStoreFrontImage];
     */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
