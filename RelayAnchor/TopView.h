//
//  TopView.h
//  RelayAnchor
//
//  Created by chuck on 8/9/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OrderManager.h"
#import "PrintManager.h"

@protocol TopViewDelegate <NSObject>

- (void) didPressAlertButton;
- (void) didPressLogout;

@optional
- (void) didPressBackButton;
- (void) searchBarTextDidChange:(NSString *)searchString;

@end


@interface TopView : UIView <UITextFieldDelegate>

@property id <TopViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *searchView;
- (IBAction)searchButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *searchSeparator;
@property (weak, nonatomic) IBOutlet UITextField *searchBarTextField;
- (IBAction)alertButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *orderNumberLabel;
- (IBAction)logoutAction:(id)sender;
- (IBAction)mallNameAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *logoutView;

@property (weak, nonatomic) IBOutlet UIImageView *logo;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property BOOL hideBackButton;

@property OrderManager * myOrderManager;

//printing
@property PrintManager * myPrintManager;
@property (weak, nonatomic) IBOutlet UIButton *printerButton;
- (IBAction)printerAction:(id)sender;


- (IBAction)backButtonAction:(id)sender;

@end
