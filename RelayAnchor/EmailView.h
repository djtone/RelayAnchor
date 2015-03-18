//
//  EmailView.h
//  RelayAnchor
//
//  Created by chuck on 9/15/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EmailViewDelegate <NSObject>

- (void) didCancelEmail;
- (void) didStartSendingEmail;
- (void) didSendEmail;
- (void) didReceiveError;

@end


@interface EmailView : UIView

@property id <EmailViewDelegate> delegate;
- (IBAction)sendAction:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UITextField *subjectTextField;
@property (weak, nonatomic) IBOutlet UITextView *bodyTextView;

@end
