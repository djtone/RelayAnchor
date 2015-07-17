//
//  iPhone_SideMenuViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 7/17/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_SideMenuViewController.h"
#import "OrderManager.h"
#import "MFSideMenu.h"

@implementation iPhone_SideMenuViewController

- (IBAction)logoutAction:(id)sender
{
    OrderManager * tmpOrderManager = [OrderManager sharedInstance];
    [tmpOrderManager cancelLoadOrders:nil];
    [tmpOrderManager stopAutoRefreshOrders:nil];
    UIViewController * loginViewController = [[[self.parentViewController.childViewControllers objectAtIndex:1] childViewControllers] objectAtIndex:0];
    [loginViewController.navigationController popToViewController:loginViewController animated:NO];
    
    MFSideMenuContainerViewController * rootController = (MFSideMenuContainerViewController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [rootController toggleLeftSideMenuCompletion:^
    {
        
    }];
}

@end
