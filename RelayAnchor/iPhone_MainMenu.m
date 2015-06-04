//
//  iPhone_MainMenu.m
//  RelayAnchor
//
//  Created by chuck johnston on 5/21/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_MainMenu.h"

@implementation iPhone_MainMenu

- (void)viewDidLoad
{
    [super viewDidLoad];
    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL) prefersStatusBarHidden
{
    return NO;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [[[(UIButton*)sender titleLabel] text] isEqualToString:@"View Orders"] )
        [(UITabBarController *)[segue destinationViewController] setSelectedIndex:0];
    else if ( [[[(UIButton*)sender titleLabel] text] isEqualToString:@"Chat"] )
        [(UITabBarController *)[segue destinationViewController] setSelectedIndex:1];
    else if ( [[[(UIButton*)sender titleLabel] text] isEqualToString:@"Runners"] )
        [(UITabBarController *)[segue destinationViewController] setSelectedIndex:2];
}

- (IBAction)changeMallAction:(id)sender
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Change Mall" message:[NSString stringWithFormat:@"Please sign in to %@", @"'mall name'"] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [alert show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
