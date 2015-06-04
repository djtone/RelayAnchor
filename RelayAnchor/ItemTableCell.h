//
//  ItemTableCell.h
//  RelayAnchor
//
//  Created by chuck on 8/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ItemTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *statusOrderedCheckMark;
@property (weak, nonatomic) IBOutlet UIImageView *statusPickedUpCheckMark;
@property (weak, nonatomic) IBOutlet UIImageView *statusAtStationCheckMark;
@property (weak, nonatomic) IBOutlet UIImageView *statusDeliveredCheckMark;
@property (weak, nonatomic) IBOutlet UIImageView *statusIssueCancelImage;
@property (weak, nonatomic) IBOutlet UIImageView *statusIssueSubstituteImage;
@property (weak, nonatomic) IBOutlet UIImageView *statusIssueReturnImage;

@property (weak, nonatomic) IBOutlet UILabel *itemNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *storeNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imagePlaceholder;
@property (weak, nonatomic) IBOutlet UILabel *colorLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *quantityLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;

@property (weak, nonatomic) IBOutlet UIView *swipeLeftMenu;
@property (weak, nonatomic) IBOutlet UIButton *cancelItemButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIButton *atStationButton;
@property (weak, nonatomic) IBOutlet UIButton *deliveredButton;
@end
