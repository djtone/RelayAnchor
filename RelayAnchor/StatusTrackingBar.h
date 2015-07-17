//
//  StatusTrackingBar.h
//  RelayAnchor
//
//  Created by chuck johnston on 7/10/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Product.h"

@interface StatusTrackingBar : UIView

- (id) initWithProduct:(Product *)product;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *runningCheckMark;
@property (weak, nonatomic) IBOutlet UIImageView *pickedUpCheckMark;
@property (weak, nonatomic) IBOutlet UIImageView *atStationCheckMark;
@property (weak, nonatomic) IBOutlet UIImageView *deliveredCheckMark;

@end
