//
//  iPhone_OrderDetailViewController.h
//  RelayAnchor
//
//  Created by chuck johnston on 6/23/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OrderManager.h"
#import "iPhone_AcceptPictureViewController.h"
#import "ReceiptPopup.h"

@interface iPhone_OrderDetailViewController : UIViewController <UITabBarDelegate, UITableViewDelegate, UITableViewDataSource, iPhoneReceiptCameraDelegate, ReceiptPopupDelegate, OrderManagerDelegate>

@property OrderManager * myOrderManager;
@property Order * myOrder;
@property NSArray * productsForTableView;
@property NSMutableArray * swipedProductIds;
@property Product * activeProduct;
@property (weak, nonatomic) IBOutlet UITableView * OrderDetailTableView;
@property (weak, nonatomic) IBOutlet UIView *topBackView;
@property (weak, nonatomic) IBOutlet UILabel *orderNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderRunnerLabel;
@property (weak, nonatomic) IBOutlet UIView *colorDot;
@property (weak, nonatomic) IBOutlet UIButton *myButton;
@property UIButton * receiptOverlay;
@property ReceiptPopup * myReceiptPopup;

- (IBAction)receiptButtonAction:(id)sender;
- (IBAction)myButtonAction:(id)sender;
- (IBAction)backButtonAction:(id)sender;
- (IBAction)atStationAction:(id)sender;

@end
