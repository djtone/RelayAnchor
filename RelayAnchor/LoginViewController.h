//
//  LoginViewController.h
//  RelayAnchor
//
//  Created by chuck on 8/8/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

- (IBAction)loginAction:(id)sender;
- (void) keyboardWillHide;
- (void) keyboardWillShow;

@property (weak, nonatomic) IBOutlet UISwitch *rememberEmailSwitch;
- (IBAction)rememberEmailAction:(id)sender;
@end
