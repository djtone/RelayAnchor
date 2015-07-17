//
//  StatusTrackingBar.m
//  RelayAnchor
//
//  Created by chuck johnston on 7/10/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "StatusTrackingBar.h"

@implementation StatusTrackingBar

- (id) initWithProduct:(Product *)product
{
    if ( [product.runnerStatus isEqualToString:@"Running"] || [product.runnerStatus isEqualToString:@"Picked Up"] || [product.runnerStatus isEqualToString:@"At Station"] || [product.anchorStatus isEqualToString:@"Delivered"] )
        self.runningCheckMark.hidden = NO;
    if ( [product.runnerStatus isEqualToString:@"Picked Up"] || [product.runnerStatus isEqualToString:@"At Station"] || [product.anchorStatus isEqualToString:@"Delivered"] )
        self.pickedUpCheckMark.hidden = NO;
    if ( [product.anchorStatus isEqualToString:@"At Station"] || [product.anchorStatus isEqualToString:@"Delivered"] || [product.anchorStatus isEqualToString:@"Return Initiated"] )
        self.atStationCheckMark.hidden = NO;
    if ( [product.anchorStatus isEqualToString:@"Delivered"] || [product.anchorStatus isEqualToString:@"Return Initiated"] )
        self.deliveredCheckMark.hidden = NO;
    
    return self;
}

@end
