//
//  OrderTableCell.m
//  RelayAnchor
//
//  Created by chuck on 8/8/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "OrderTableCell.h"

@implementation OrderTableCell

- (void) awakeFromNib
{
    //needed to prevent the delay that happens in the button selection animation
    for ( UIView *currentView in self.subviews )
    {
        if ( [currentView isKindOfClass:[UIScrollView class]] )
        {
            ((UIScrollView *)currentView).delaysContentTouches = NO;
            break;
        }
    }
}

@end
