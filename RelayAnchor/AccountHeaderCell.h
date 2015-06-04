//
//  AccountHeaderCell.h
//  RelayAnchor
//
//  Created by chuck johnston on 5/26/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AccountHeaderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UIButton *myButton;
@property (weak, nonatomic) IBOutlet UIImageView *plusMinusImageView;

@end
