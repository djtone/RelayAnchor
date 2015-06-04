//
//  iPhone_ManageAccountViewController.h
//  RelayAnchor
//
//  Created by chuck johnston on 5/22/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountManager.h"

@interface iPhone_ManageAccountViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property AccountManager * myAccountManager;

@property (weak, nonatomic) IBOutlet UISegmentedControl *mySegmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property NSMutableDictionary * tableDictionary;
@property NSMutableDictionary * openSections;
@property int maxTableHeight;

- (IBAction)headerAction:(id)sender;
- (IBAction)backButtonAction:(id)sender;
- (IBAction)segmentedControlDidChange:(id)sender;
- (IBAction)logoutAction:(id)sender;

@end
