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
#import "AccountManager.h"

@protocol TopViewDelegate <NSObject>

- (void) didPressAlertButton;
- (void) didPressLogout;
- (void) didChangeMall;

@optional
- (void) didPressBackButton;
- (void) searchBarTextDidChange:(NSString *)searchString;
- (void) didChangeKeynoteBoolean;

@end


@interface TopView : UIView <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property id <TopViewDelegate> delegate;
@property AccountManager * sharedAccountManager;

//search bar
@property (weak, nonatomic) IBOutlet UIView *searchView;
- (IBAction)searchButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *searchSeparator;
@property (weak, nonatomic) IBOutlet UITextField *searchBarTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchActivityIndicator;

- (IBAction)alertButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *orderNumberLabel;
@property (weak, nonatomic) IBOutlet UIButton *mallNameButton;
- (IBAction)mallNameAction:(id)sender;
@property UIView * selectMallAndLogoutView;
@property UITableView * mallSelectTableView;
@property NSArray * mallsForTableView;

@property (weak, nonatomic) IBOutlet UIImageView *logo;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property BOOL hideBackButton;

@property OrderManager * myOrderManager;

//printing
@property PrintManager * myPrintManager;
@property (weak, nonatomic) IBOutlet UIButton *printerButton;
- (IBAction)printerAction:(id)sender;

//keynote orders
@property (weak, nonatomic) IBOutlet UIButton *keynoteOrdersButton;
@property (weak, nonatomic) IBOutlet UISwitch *keynoteOrdersSwitch;
- (IBAction)keynoteOrdersAction:(id)sender;
- (IBAction)keynoteOrdersSwitchChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *keynoteActivityIndicator;

- (IBAction)backButtonAction:(id)sender;

@end
