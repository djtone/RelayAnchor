//
//  iPhone_LoginViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 5/21/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_LoginViewController.h"
#import "SVProgressHUD.h"
#import "AccountManager.h"
#import "CreateAPIStrings.h"

@implementation iPhone_LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    self.signInButton.layer.borderColor = [[UIColor colorWithWhite:1 alpha:.5] CGColor];
    
    NSString * version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
    if ( [[CreateAPIStrings baseUrl] isEqualToString:@"http://shopyourwaylocal.com/SYWRelayServices"] )
        self.versionLabel.text = version;
    else
        self.versionLabel.text = [NSString stringWithFormat:@"QA %@", version];
    
    self.emailTextField.text = [[AccountManager sharedInstance] rememberedEmail];
    if ( [[AccountManager sharedInstance] rememberedEmail] != nil )
        [self.rememberEmailSwitch setOn:YES];
    else
        [self.rememberEmailSwitch setOn:NO];
}


- (IBAction)rememberEmailAction:(id)sender
{
    if ( [self.rememberEmailSwitch isOn] )
        [self.rememberEmailSwitch setOn:NO animated:YES];
    else
        [self.rememberEmailSwitch setOn:YES animated:YES];
}

- (IBAction)loginAction:(id)sender
{
    if ( [self.emailTextField.text length] == 0 )
    {
        [SVProgressHUD showErrorWithStatus:@"No Login Provided"];
        [self.emailTextField becomeFirstResponder];
    }
    else
    {
        [SVProgressHUD show];
        [AccountManager loginWithUser:self.emailTextField.text password:self.passwordTextField.text rememberEmail:self.rememberEmailSwitch.on andPushToken:@"" completion:^(BOOL success)
         {
             if ( success )
             {
                 self.editing = NO;
                 [SVProgressHUD dismiss];
                 [self performSegueWithIdentifier:@"login" sender:self];
                 
                 self.passwordTextField.text = @"";
                 if ( ! [self.rememberEmailSwitch isOn] )
                     self.emailTextField.text = @"";
             }
             else
                 [SVProgressHUD showErrorWithStatus:@"Invalid Login"];
         }];
    }
}

- (IBAction)emailTextFieldChanged:(id)sender
{
    if ( self.passwordTextField.text.length && self.emailTextField.text.length )
    {
        self.signInButton.enabled = YES;
        self.signInButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    }
    else
    {
        self.signInButton.enabled = NO;
        self.signInButton.layer.borderColor = [[UIColor colorWithWhite:1 alpha:.5] CGColor];
    }
}

- (IBAction)passwordTextFieldChanged:(id)sender
{
    if ( self.passwordTextField.text.length && self.emailTextField.text.length )
    {
        self.signInButton.enabled = YES;
        self.signInButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    }
    else
    {
        self.signInButton.enabled = NO;
        self.signInButton.layer.borderColor = [[UIColor colorWithWhite:1 alpha:.5] CGColor];
    }
}

#pragma mark - text field
- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if ( textField == self.emailTextField )
        [self.passwordTextField becomeFirstResponder];
    else if ( textField == self.passwordTextField )
    {
        [textField resignFirstResponder];
        [self loginAction:nil];
    }
    
    return NO;
}

@end
