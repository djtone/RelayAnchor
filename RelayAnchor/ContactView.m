//
//  ContactView.m
//  RelayAnchor
//
//  Created by chuck on 8/12/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "ContactView.h"

@implementation ContactView

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    self.frame = CGRectMake(262, 250, 500, 256);
}

- (IBAction)closeWindowAction:(id)sender
{
    [self.delegate didPressCloseWindow];
}

- (IBAction)textAction:(id)sender
{
    [self.delegate didPressText];
}

- (IBAction)mailAction:(id)sender
{
    [self.delegate didPressMail];
}

@end
