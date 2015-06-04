//
//  OrderDetailViewController.h
//  RelayAnchor
//
//  Created by chuck on 8/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TopView.h"
#import "BottomView.h"
#import "OrderManager.h"
#import "Order.h"
#import "PrintManager.h"

@interface OrderDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, TopViewDelegate, BottomViewDelegate, OrderManagerDelegate>

@property Order * myOrder;
@property OrderManager * myOrderManager;
@property TopView * myTopView;
@property BottomView * myBottomView;

@property BOOL didNavigateFromHomeScreen;
@property (weak, nonatomic) IBOutlet UITableView * OrderDetailTableView;
@property NSMutableArray * swipedProducts;
@property NSArray * productsForTableView;
@property Product * activeProduct;

@property NSTimer * refreshTimer;
- (void) refreshDetails;

- (IBAction)setStatusReturnConfirmedAction:(id)sender;
- (IBAction)setStatusReturnRejectedAction:(id)sender;

- (IBAction)atStationAction:(id)sender;
- (IBAction)deliveredAction:(id)sender;

@property PrintManager * myPrintManager;

@end
