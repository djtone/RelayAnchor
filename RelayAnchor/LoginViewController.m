//
//  LoginViewController.m
//  RelayAnchor
//
//  Created by chuck on 8/8/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "LoginViewController.h"
#import "HomeViewController.h"
#import "CreateAPIStrings.h"
#import "AccountManager.h"
#import "SVProgressHUD.h"
#import "ForgotPasswordViewController.h"

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //ui stuff
    NSString * version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
    if ( [[CreateAPIStrings baseUrl] isEqualToString:@"http://shopyourwaylocal.com/SYWRelayServices"] )
        self.versionLabel.text = version;
    else
        self.versionLabel.text = [NSString stringWithFormat:@"QA %@", version];
}

- (void) viewWillAppear:(BOOL)animated
{
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:self.view.window];
    
    //ui stuff
    NSUserDefaults * preferences = [NSUserDefaults standardUserDefaults];
    if ( [preferences valueForKey:@"sellerEmail"] == nil )
        [self.rememberEmailSwitch setOn:NO];
    else
    {
        [self.rememberEmailSwitch setOn:YES];
        self.emailTextField.text = [preferences valueForKey:@"sellerEmail"];
    }
}

- (IBAction)loginAction:(id)sender
{
    NSUserDefaults * preferences = [NSUserDefaults standardUserDefaults];
    if ( [self.rememberEmailSwitch isOn] )
        [preferences setValue:self.emailTextField.text forKey:@"sellerEmail"];
    else
        [preferences setValue:nil forKey:@"sellerEmail"];
    [preferences synchronize];
    
    if ( [self.emailTextField.text length] == 0 )
        [SVProgressHUD showErrorWithStatus:@"No Login Provided"];
    else
    {
        [SVProgressHUD show];
        [AccountManager loginWithUser:self.emailTextField.text password:self.passwordTextField.text andPushToken:@"" completion:^(BOOL success)
        {
            if ( success )
            {
                [SVProgressHUD dismiss];
                HomeViewController * modalHomeViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"homePage"];
                modalHomeViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                [self presentViewController:modalHomeViewController animated:YES completion:nil];
                
                self.passwordTextField.text = @"";
                if ( ! [self.rememberEmailSwitch isOn] )
                    self.emailTextField.text = @"";
            }
            else
                [SVProgressHUD showErrorWithStatus:@"Invalid Login"];
        }];
    }
}

- (IBAction)rememberEmailAction:(id)sender
{
    if ( [self.rememberEmailSwitch isOn] )
        [self.rememberEmailSwitch setOn:NO animated:YES];
    else
        [self.rememberEmailSwitch setOn:YES animated:YES];
}

#pragma mark - textfield
- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if ( textField == self.passwordTextField )
    {
        [textField resignFirstResponder];
        [self loginAction:nil];
    }
    
    return YES;
}

- (void) keyboardWillShow
{
    CGRect offsetRectOrientationRight;
    CGRect offsetRectOrientationLeft;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
    {
        offsetRectOrientationRight = CGRectMake(0, -100, 768, 1024);
        offsetRectOrientationLeft = CGRectMake(0, 100, 768, 1024);
    }
    else
    {
        offsetRectOrientationRight = CGRectMake(-100, 0, 768, 1024);
        offsetRectOrientationLeft = CGRectMake(100, 0, 768, 1024);
    }
    
    [UIView animateWithDuration:.3 animations:^
    {
        if ( [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight || self.interfaceOrientation == 4 )
            self.view.frame = offsetRectOrientationRight;
        else
            self.view.frame = offsetRectOrientationLeft;
    }];
}

- (void) keyboardWillHide
{
    [UIView animateWithDuration:.3 animations:^
    {
        self.view.frame = CGRectMake(0, 0, 768, 1024);
    }];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"forgotPassword"] )
        [(ForgotPasswordViewController *)segue.destinationViewController setEmailFromSegue:self.emailTextField.text];
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
@end
