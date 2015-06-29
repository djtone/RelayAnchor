//
//  iPhone_OrderDetailViewController.h
//  RelayAnchor
//
//  Created by chuck johnston on 6/23/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OrderManager.h"
@interface iPhone_OrderDetailViewController : UIViewController <UITabBarDelegate>


@property OrderManager * myOrderManager;
@property Order * myOrder;
@property NSArray * productsForTableView;
@property (weak, nonatomic) IBOutlet UITableView * OrderDetailTableView;
@property (weak, nonatomic) IBOutlet UIView *topBackView;
@property (weak, nonatomic) IBOutlet UILabel *orderNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderRunnerLabel;

@end
