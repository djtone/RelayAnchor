//
//  iPhone_ItemDetailViewController.h
//  RelayAnchor
//
//  Created by chuck johnston on 7/9/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Product.h"
#import "OrderManager.h"
#import "StatusTrackingBar.h"

@interface iPhone_ItemDetailViewController : UIViewController <UIScrollViewDelegate, UITabBarDelegate>

@property OrderManager * myOrderManager;
@property Product *  myProduct;
@property (weak, nonatomic) IBOutlet UILabel *productNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *productImageView;
@property int originalImageYCoord;


@property (weak, nonatomic) IBOutlet UIScrollView *myScrollView;

@property (weak, nonatomic) IBOutlet UIView *descriptionView;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *colorLabel;
@property (weak, nonatomic) IBOutlet UILabel *storeNameLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;

@property (weak, nonatomic) IBOutlet UIView *trackingOrderView;
@property (weak, nonatomic) IBOutlet UIView *superViewForStatusBar;
@property StatusTrackingBar * myStatusTrackingBar;

- (IBAction)backButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *atStationButton;
- (IBAction)atStationAction:(id)sender;

@end
