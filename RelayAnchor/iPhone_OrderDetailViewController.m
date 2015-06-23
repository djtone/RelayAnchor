//
//  iPhone_OrderDetailViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 6/23/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_OrderDetailViewController.h"
#import "iPhone_ViewOrdersViewController.h"

@implementation iPhone_OrderDetailViewController

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - tab bar
- (void) tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    iPhone_ViewOrdersViewController * viewOrdersController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
    UITabBarItem * itemToSelect = [viewOrdersController.myTabBar.items objectAtIndex:[[tabBar items] indexOfObject:item]];
    [viewOrdersController.myTabBar setSelectedItem:itemToSelect];
    [viewOrdersController tabBar:viewOrdersController.myTabBar didSelectItem:itemToSelect];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
