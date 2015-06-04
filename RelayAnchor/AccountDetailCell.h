//
//  AccountDetailCell.h
//  RelayAnchor
//
//  Created by chuck johnston on 5/26/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AccountDetailCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UITextField *detailTextField;

@end
