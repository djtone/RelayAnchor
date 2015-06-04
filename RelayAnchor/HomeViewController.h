//
//  HomeViewController.h
//  RelayAnchor
//
//  Created by chuck on 8/8/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TopView.h"
#import "BottomView.h"
#import "OrderManager.h"

@interface HomeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, TopViewDelegate, BottomViewDelegate, OrderManagerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *welcomeImageView;
@property (weak, nonatomic) IBOutlet UILabel *mallNameLabel;
@property OrderManager * myOrderManager;
@property TopView * myTopView;
@property BottomView * myBottomView;
@property (weak, nonatomic) IBOutlet UITableView * orderTableView;
@property NSArray * ordersForTableView;
@property NSDateFormatter * myDateFormatter;
@property float lastContentOffset;

//this is to keep track of the last time a call was made to update the table
@property NSDate * myDate;

@property (weak, nonatomic) IBOutlet UILabel *noOrdersLabel;

@end
