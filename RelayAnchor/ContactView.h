//
//  ContactView.h
//  RelayAnchor
//
//  Created by chuck on 8/12/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ContactViewDelegate <NSObject>

- (void) didPressText;
- (void) didPressMail;
- (void) didPressCloseWindow;

@end


@interface ContactView : UIView

@property (nonatomic, assign) id <ContactViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIImageView *phoneIcon;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *stationLabel;
@property NSString * emailAddress; // this is a data holder - used to pass to the email view

- (IBAction)closeWindowAction:(id)sender;
- (IBAction)textAction:(id)sender;
- (IBAction)mailAction:(id)sender;

@end
