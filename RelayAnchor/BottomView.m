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
    if ( self.selectedStatus != kBottomViewStatusOpen )
    {
        [self resetButtons];
        self.selectedStatus = kBottomViewStatusOpen;
        self.triangleSelectionIcon.frame = CGRectMake(79, self.triangleSelectionIcon.frame.origin.y, self.triangleSelectionIcon.frame.size.width, self.triangleSelectionIcon.frame.size.height);
        self.triangleSelectionIcon.hidden = NO;
        [self.openButton setImage:[UIImage imageNamed:@"BottomView_Open_Selected.png"] forState:UIControlStateNormal];
        
        if ( [self.delegate respondsToSelector:@selector(didChangeStatus:)] )
            [self.delegate didChangeStatus:self.selectedStatus];
    }
}

- (IBAction)readyButtonAction:(id)sender
{
    if ( self.selectedStatus != kBottomViewStatusReady )
    {
        [self resetButtons];
        self.selectedStatus = kBottomViewStatusReady;
        self.triangleSelectionIcon.frame = CGRectMake(302, self.triangleSelectionIcon.frame.origin.y, self.triangleSelectionIcon.frame.size.width, self.triangleSelectionIcon.frame.size.height);
        self.triangleSelectionIcon.hidden = NO;
        [self.readyButton setImage:[UIImage imageNamed:@"BottomView_Ready_Selected.png"] forState:UIControlStateNormal];
        
        if ( [self.delegate respondsToSelector:@selector(didChangeStatus:)] )
            [self.delegate didChangeStatus:self.selectedStatus];
    }
}

- (IBAction)deliveredButtonAction:(id)sender
{
    if ( self.selectedStatus != kBottomViewStatusDelivered )
    {
        [self resetButtons];
        self.selectedStatus = kBottomViewStatusDelivered;
        self.triangleSelectionIcon.frame = CGRectMake(559, self.triangleSelectionIcon.frame.origin.y, self.triangleSelectionIcon.frame.size.width, self.triangleSelectionIcon.frame.size.height);
        self.triangleSelectionIcon.hidden = NO;
        [self.deliveredButton setImage:[UIImage imageNamed:@"BottomView_Delivered_Selected.png"] forState:UIControlStateNormal];
        
        if ( [self.delegate respondsToSelector:@selector(didChangeStatus:)] )
            [self.delegate didChangeStatus:self.selectedStatus];
    }
}

- (IBAction)cancelledReturnedButtonAction:(id)sender
{
    if ( self.selectedStatus != kBottomViewStatusCancelledReturned )
    {
        [self resetButtons];
        self.selectedStatus = kBottomViewStatusCancelledReturned;
        self.triangleSelectionIcon.frame = CGRectMake(848, self.triangleSelectionIcon.frame.origin.y, self.triangleSelectionIcon.frame.size.width, self.triangleSelectionIcon.frame.size.height);
        self.triangleSelectionIcon.hidden = NO;
        [self.cancelledReturnedButton setImage:[UIImage imageNamed:@"BottomView_CancelledReturned_Selected.png"] forState:UIControlStateNormal];
        
        if ( [self.delegate respondsToSelector:@selector(didChangeStatus:)] )
            [self.delegate didChangeStatus:self.selectedStatus];
    }
}

- (void) resetButtons
{
    self.triangleSelectionIcon.hidden = YES;
    [self.openButton setImage:[UIImage imageNamed:@"BottomView_Open.png"] forState:UIControlStateNormal];
    [self.readyButton setImage:[UIImage imageNamed:@"BottomView_Ready.png"] forState:UIControlStateNormal];
    [self.deliveredButton setImage:[UIImage imageNamed:@"BottomView_Delivered.png"] forState:UIControlStateNormal];
    [self.cancelledReturnedButton setImage:[UIImage imageNamed:@"BottomView_CancelledReturned.png"] forState:UIControlStateNormal];
    self.selectedStatus = kBottomViewStatusNil;
}

@end
