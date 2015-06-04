//
//  OrderTableCell.h
//  RelayAnchor
//
//  Created by chuck on 8/8/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrderTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyerEmail;
@property (weak, nonatomic) IBOutlet UILabel *buyerPhoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *runnerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIView *colorDot;
@property (weak, nonatomic) IBOutlet UILabel *keynoteOrderLabel;
@property (weak, nonatomic) IBOutlet UILabel *hasDeliveryItemsLabel;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIButton *confirmDeliveryButton;

@property (weak, nonatomic) IBOutlet UIView *swipeLeftMenu;
@property (weak, nonatomic) IBOutlet UIButton *overrideReadyStatusButton;

@end
