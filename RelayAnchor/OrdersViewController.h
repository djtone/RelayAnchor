//
//  OrdersViewController.h
//  RelayAnchor
//
//  Created by chuck on 8/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TopView.h"
#import "BottomView.h"
#import "OrderManager.h"
#import "PrintManager.h"

@interface OrdersViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIPrinterPickerControllerDelegate, TopViewDelegate, BottomViewDelegate, OrderManagerDelegate, UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *orderTableView;
@property NSMutableArray * swipedOrders;

@property TopView * myTopView;
@property BottomView * myBottomView;

@property OrderManager * myOrderManager;

- (void) keyboardWillHide;
- (void) keyboardWillShow;

@property NSArray * ordersForTableView;
- (void) refreshOrders;
@property (weak, nonatomic) IBOutlet UILabel *noOrdersLabel;
@property NSDateFormatter * myDateFormatter;
@property float lastContentOffset;

//this is to keep track of the last time a call was made to update the table
@property NSDate * myDate;

@property NSTimer * updateOrdersTimer;

- (IBAction)confirmOrderDelivery:(id)sender;
- (void) overrideOrderReady:(UILongPressGestureRecognizer *)gesture;
@property NSIndexPath * indexPathForOverrideOrder;
@property Order * orderForOverrideOrder;

- (IBAction)sortOrders:(id)sender;
@property UIButton * lastSortedButton;
@property (weak, nonatomic) IBOutlet UIButton *orderDateButton;
@property (weak, nonatomic) IBOutlet UIButton *orderIDButton;
@property (weak, nonatomic) IBOutlet UIButton *buyerNameButton;
@property (weak, nonatomic) IBOutlet UIButton *buyerEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *buyerPhoneButton;
@property (weak, nonatomic) IBOutlet UIButton *runnerButton;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;

#pragma mark - printing
@property Order * orderForPrinting;
@property PrintManager * myPrintManager;
@property UIPrinter * myPrinter;
- (IBAction)manualPrintAction:(id)sender;

@end
