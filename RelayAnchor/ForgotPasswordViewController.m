//
//  ForgotPasswordViewController.m
//  RelayAnchor
//
//  Created by chuck on 9/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "ForgotPasswordViewController.h"
#import "AccountManager.h"
#import "SVProgressHUD.h"
#import "UIAlertView+Blocks.h"
#import "LoginViewController.h"

@implementation ForgotPasswordViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.emailTextField.text = self.emailFromSegue;
}

- (IBAction)sendAction:(id)sender
{
    if ( [self.emailTextField.text length] == 0 )
        [SVProgressHUD showErrorWithStatus:@"No Email Provided"];
    else
    {
        [SVProgressHUD showWithStatus:@"Validating Email"];
        [AccountManager forgotPasswordForUser:self.emailTextField.text completion:^(BOOL success)
        {
            if ( success )
            {
                [SVProgressHUD dismiss];
                [[[UIAlertView alloc] initWithTitle:@"Password Reset"
                                            message:@"Password Has Been Reset Successfully"
                                   cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^
                                                     {
                                                         [(LoginViewController *)self.presentingViewController emailTextField].text = self.emailTextField.text;
                                                         [self dismissViewControllerAnimated:YES completion:nil];
                                                     }]
                                   otherButtonItems:nil] show];
            }
            else
            {
                [SVProgressHUD showErrorWithStatus:@"Invalid Email"];
            }
        }];
    }
}

- (IBAction)backAction:(id)sender
{
    [(LoginViewController *)self.presentingViewController emailTextField].text = self.emailTextField.text;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
