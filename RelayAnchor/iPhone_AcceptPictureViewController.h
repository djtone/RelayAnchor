//
//  iPhone_AcceptPictureViewController.h
//  RelayAnchor
//
//  Created by chuck johnston on 7/6/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol iPhoneReceiptCameraDelegate <NSObject>

- (void) didFinishTakingReceiptPicture:(UIImage *)receiptImage;

@end

@interface iPhone_AcceptPictureViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *myImageView;

- (IBAction)retakeAction:(id)sender;
- (IBAction)usePhotoAction:(id)sender;

@end
