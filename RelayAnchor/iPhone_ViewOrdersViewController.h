//
//  iPhone_ViewOrdersViewController.h
//  RelayAnchor
//
//  Created by chuck johnston on 5/22/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OrderManager.h"

@interface iPhone_ViewOrdersViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITabBarDelegate, OrderManagerDelegate, UITextFieldDelegate, UIActionSheetDelegate>

@property OrderManager * myOrderManager;
@property NSArray * ordersForTableView;
@property NSDateFormatter * myDateFormatter;
@property LoadOrderStatus selectedOrderStatus;
@property float lastContentOffset;
@property Order * myOrderToSend;

@property (weak, nonatomic) IBOutlet UIImageView *mallImageView;
@property (weak, nonatomic) IBOutlet UIView *mallImageOverlay;
@property (weak, nonatomic) IBOutlet UITableView * myTableView;
@property (weak, nonatomic) IBOutlet UITabBar * myTabBar;
@property (weak, nonatomic) IBOutlet UITextField * searchTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

- (IBAction)searchAction:(id)sender;
- (IBAction)sortByAction:(id)sender;
- (IBAction)sideMenuAction:(id)sender;
- (IBAction)changeMallAction:(id)sender;

@end
