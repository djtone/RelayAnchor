//
//  AcceptPictureViewController.h
//  RelayAnchor
//
//  Created by chuck johnston on 3/10/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AcceptPictureViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *myImageView;

- (IBAction)retakeAction:(id)sender;
- (IBAction)usePhotoAction:(id)sender;

@end
