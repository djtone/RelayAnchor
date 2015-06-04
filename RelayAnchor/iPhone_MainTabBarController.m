//
//  iPhone_MainTabBarController.m
//  RelayAnchor
//
//  Created by chuck johnston on 5/22/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_MainTabBarController.h"

@implementation iPhone_MainTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UITabBar appearance] setTintColor:[UIColor orangeColor]];
    
    UITabBarItem * item0 = [self.tabBar.items objectAtIndex:0];
    [item0 setImage:[[UIImage imageNamed:@"iPhone_TabBarIcon_Orders.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [item0 setSelectedImage:[[UIImage imageNamed:@"iPhone_TabBarIcon_Orders_Selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    UITabBarItem * item1 = [self.tabBar.items objectAtIndex:1];
    [item1 setImage:[[UIImage imageNamed:@"iPhone_TabBarIcon_Chat.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [item1 setSelectedImage:[[UIImage imageNamed:@"iPhone_TabBarIcon_Chat_Selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    UITabBarItem * item2 = [self.tabBar.items objectAtIndex:2];
    [item2 setImage:[[UIImage imageNamed:@"iPhone_TabBarIcon_Runners.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [item2 setSelectedImage:[[UIImage imageNamed:@"iPhone_TabBarIcon_Runners_Selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
