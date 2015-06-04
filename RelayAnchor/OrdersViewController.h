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

@property OrderManager * myOrderManager;

@property TopView * myTopView;
@property BottomView * myBottomView;
@property NSDateFormatter * myDateFormatter;

@property (weak, nonatomic) IBOutlet UITableView *orderTableView;
@property NSArray * ordersForTableView;
@property float lastContentOffset;
@property NSMutableArray * swipedOrderIds;
- (BOOL) refreshOrders;
//this is to keep track of the last time a call was made to update the table
@property NSDate * myDate;

- (void) keyboardWillHide;
- (void) keyboardWillShow;

- (IBAction)confirmOrderDelivery:(id)sender;

- (IBAction)sortOrders:(id)sender;
@property UIButton * lastSortedButton;
@property (weak, nonatomic) IBOutlet UILabel *noOrdersLabel;
@property BOOL statusesFirstLoad;
@property BOOL searchesFirstLoad;
@property NSString * searchedText; //this is required becuase the clear button calls textFieldDidChange twice (im guessing its an iOS bug)
@property (weak, nonatomic) IBOutlet UIButton *orderDateButton;
@property (weak, nonatomic) IBOutlet UIButton *orderIDButton;
@property (weak, nonatomic) IBOutlet UIButton *buyerNameButton;
@property (weak, nonatomic) IBOutlet UIButton *buyerEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *buyerPhoneButton;
@property (weak, nonatomic) IBOutlet UIButton *runnerButton;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;


@end
