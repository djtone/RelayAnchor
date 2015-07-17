//
//  ReceiptPopup.m
//  RelayAnchor
//
//  Created by chuck johnston on 7/12/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "ReceiptPopup.h"

@implementation ReceiptPopup

- (IBAction)cancelAction:(id)sender
{
    [self.delegate didPressCancel];
}

- (IBAction)uploadAction:(id)sender
{
    [self.delegate didPressUpload];
}

@end
