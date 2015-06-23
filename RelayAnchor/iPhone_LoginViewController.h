//
//  iPhone_LoginViewController.h
//  RelayAnchor
//
//  Created by chuck johnston on 5/21/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iPhone_LoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UISwitch *rememberEmailSwitch;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;

- (IBAction)rememberEmailAction:(id)sender;
- (IBAction)loginAction:(id)sender;

- (IBAction)emailTextFieldChanged:(id)sender;
- (IBAction)passwordTextFieldChanged:(id)sender;

@end
