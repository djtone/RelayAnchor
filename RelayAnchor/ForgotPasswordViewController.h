//
//  ForgotPasswordViewController.h
//  RelayAnchor
//
//  Created by chuck on 9/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ForgotPasswordViewController : UIViewController

@property NSString * emailFromSegue;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

- (IBAction)sendAction:(id)sender;
- (IBAction)backAction:(id)sender;

@end
