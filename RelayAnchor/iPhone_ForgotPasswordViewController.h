//
//  iPhone_ForgotPasswordViewController.h
//  RelayAnchor
//
//  Created by chuck johnston on 6/22/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iPhone_ForgotPasswordViewController : UIViewController

@property NSString * emailFromSegue;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

- (IBAction)sendAction:(id)sender;
- (IBAction)backButtonAction:(id)sender;
@end
