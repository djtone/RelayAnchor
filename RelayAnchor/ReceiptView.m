//
//  ReceiptView.m
//  RelayAnchor
//
//  Created by chuck on 9/12/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "ReceiptView.h"

@implementation ReceiptView

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    self.frame = CGRectMake(300, 200, 380, 350);
    UITapGestureRecognizer * imageTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTap)];
    [self.receiptImageView addGestureRecognizer:imageTapGesture];
}

- (void) handleImageTap
{
    [self.delegate didPressImage:self];
}

- (IBAction)cancelAction:(id)sender
{
    [self.delegate didPressCancel:self];
}

- (IBAction)uploadAction:(id)sender
{
    [self.delegate didPressUpload:self];
}

@end
