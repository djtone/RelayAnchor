//
//  iPhone_OrderCell.m
//  RelayAnchor
//
//  Created by chuck johnston on 6/5/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_OrderCell.h"

@implementation iPhone_OrderCell

- (void) layoutSubviews
{
    self.swipeButton.titleLabel.numberOfLines = 2;
    self.swipeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}

@end
