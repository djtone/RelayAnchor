//
//  BottomView.m
//  RelayAnchor
//
//  Created by chuck on 8/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "BottomView.h"

@implementation BottomView

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    self.frame = CGRectMake(0, 688, 1024, 80);
}

- (IBAction)openButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didPressOpen)])
    {
        self.triangleSelectionIcon.frame = CGRectMake(79, self.triangleSelectionIcon.frame.origin.y, self.triangleSelectionIcon.frame.size.width, self.triangleSelectionIcon.frame.size.height);
        self.triangleSelectionIcon.hidden = NO;
        [self resetButtonColors];
        [self.openButton setImage:[UIImage imageNamed:@"BottomView_Open_Selected.png"] forState:UIControlStateNormal];
        [self.delegate didPressOpen];
        self.selectedStatus = @"open";
    }
    else
        NSLog(@"delegate did not implement didPressOpen");
}

- (IBAction)readyButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didPressReady)])
    {
        self.triangleSelectionIcon.frame = CGRectMake(302, self.triangleSelectionIcon.frame.origin.y, self.triangleSelectionIcon.frame.size.width, self.triangleSelectionIcon.frame.size.height);
        self.triangleSelectionIcon.hidden = NO;
        [self resetButtonColors];
        [self.readyButton setImage:[UIImage imageNamed:@"BottomView_Ready_Selected.png"] forState:UIControlStateNormal];
        [self.delegate didPressReady];
        self.selectedStatus = @"ready";
    }
    else
        NSLog(@"delegate did not implement didPressReady");
}

- (IBAction)deliveredButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didPressDelivered)])
    {
        self.triangleSelectionIcon.frame = CGRectMake(559, self.triangleSelectionIcon.frame.origin.y, self.triangleSelectionIcon.frame.size.width, self.triangleSelectionIcon.frame.size.height);
        self.triangleSelectionIcon.hidden = NO;
        [self resetButtonColors];
        [self.deliveredButton setImage:[UIImage imageNamed:@"BottomView_Delivered_Selected.png"] forState:UIControlStateNormal];
        [self.delegate didPressDelivered];
        self.selectedStatus = @"delivered";
    }
    else
        NSLog(@"delegate did not implement didPressDelivered");
}

- (IBAction)cancelledReturnedButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didPressCancelledReturned)])
    {
        self.triangleSelectionIcon.frame = CGRectMake(848, self.triangleSelectionIcon.frame.origin.y, self.triangleSelectionIcon.frame.size.width, self.triangleSelectionIcon.frame.size.height);
        self.triangleSelectionIcon.hidden = NO;
        [self resetButtonColors];
        [self.cancelledReturnedButton setImage:[UIImage imageNamed:@"BottomView_CancelledReturned_Selected.png"] forState:UIControlStateNormal];
        [self.delegate didPressCancelledReturned];
        self.selectedStatus = @"cancelledReturned";
    }
    else
        NSLog(@"delegate did not implement didPressCancelledReturned");
}

- (void) resetButtonColors
{
    [self.openButton setImage:[UIImage imageNamed:@"BottomView_Open.png"] forState:UIControlStateNormal];
    [self.readyButton setImage:[UIImage imageNamed:@"BottomView_Ready.png"] forState:UIControlStateNormal];
    [self.deliveredButton setImage:[UIImage imageNamed:@"BottomView_Delivered.png"] forState:UIControlStateNormal];
    [self.cancelledReturnedButton setImage:[UIImage imageNamed:@"BottomView_CancelledReturned.png"] forState:UIControlStateNormal];
}

@end
