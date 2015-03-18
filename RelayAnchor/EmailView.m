//
//  EmailView.m
//  RelayAnchor
//
//  Created by chuck on 9/15/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "EmailView.h"
#import "ContactManager.h"
#import "SVProgressHUD.h"
#import "CreateAPIStrings.h"

@implementation EmailView

- (void) awakeFromNib
{
    [super layoutSubviews];
    self.frame = CGRectMake(262, 80, 500, 323);
}

- (IBAction)sendAction:(id)sender
{
    [self.delegate didStartSendingEmail];
    [ContactManager sendEmailTo:self.emailLabel.text withSubject:self.subjectTextField.text andBody:self.bodyTextView.text completion:^(BOOL success)
    {
        if ( success )
            [self.delegate didSendEmail];
        else
            [self.delegate didReceiveError];
    }];
    
}

- (IBAction)cancelAction:(id)sender
{
    [self.delegate didCancelEmail];
}

@end
