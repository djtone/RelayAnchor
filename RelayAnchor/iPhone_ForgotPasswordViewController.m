//
//  iPhone_ForgotPasswordViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 6/22/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_ForgotPasswordViewController.h"
#import "SVProgressHUD.h"
#import "AccountManager.h"
#import "UIAlertView+Blocks.h"
#import "iPhone_LoginViewController.h"

@implementation iPhone_ForgotPasswordViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
                                                          [(iPhone_LoginViewController *)self.presentingViewController emailTextField].text = self.emailTextField.text;
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

- (IBAction)backButtonAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
