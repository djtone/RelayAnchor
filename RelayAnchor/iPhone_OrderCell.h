//
//  iPhone_OrderCell.h
//  RelayAnchor
//
//  Created by chuck johnston on 6/5/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iPhone_OrderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *orderIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIView *dot;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *runnerNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *runnerImageView;
@property (weak, nonatomic) IBOutlet UILabel *memberNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *fulfillmentImageView;
@property (weak, nonatomic) IBOutlet UILabel *fulfillmentAddressLabel;
@property (weak, nonatomic) IBOutlet UIButton *assignRunnerButton;

@end
