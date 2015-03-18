//
//  ItemTableCell.m
//  RelayAnchor
//
//  Created by chuck on 8/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "ItemTableCell.h"

@implementation ItemTableCell

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
