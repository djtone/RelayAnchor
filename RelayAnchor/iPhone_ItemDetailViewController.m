//
//  iPhone_ItemDetailViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 7/9/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_ItemDetailViewController.h"
#import "iPhone_ViewOrdersViewController.h"
#import "SVProgressHUD.h"

@implementation iPhone_ItemDetailViewController

- (void) viewDidLoad
{
    self.myOrderManager = [OrderManager sharedInstanceWithDelegate:self];
    self.originalImageYCoord = self.productImageView.frame.origin.y;
    [self populateDetails];
}

- (void) populateDetails
{
    self.productNameLabel.text = self.myProduct.name;
    self.productImageView.image = self.myProduct.productImage;
    self.sizeLabel.text = self.myProduct.size;
    self.colorLabel.text = self.myProduct.color;
    self.storeNameLabel.text = self.myProduct.store;
    self.descriptionTextView.text = self.myProduct.productDescription;
    
    self.descriptionView.frame = CGRectMake(self.descriptionView.frame.origin.x, self.descriptionView.frame.origin.y, self.descriptionView.frame.size.width, self.descriptionTextView.frame.origin.y + [self.descriptionTextView  sizeThatFits:CGSizeMake(self.descriptionTextView.frame.size.width, 1000)].height + 5);
    self.trackingOrderView.frame = CGRectMake(self.trackingOrderView.frame.origin.x, self.descriptionView.frame.origin.y + self.descriptionView.frame.size.height, self.trackingOrderView.frame.size.width, self.trackingOrderView.frame.size.height);
    
    if ( [self.myProduct.runnerStatus isEqualToString:@"At Station"] && ! [self.myProduct.anchorStatus isEqualToString:@"At Station"] && ! [self.myProduct.anchorStatus isEqualToString:@"Delivered"] && ! [self.myProduct.anchorStatus isEqualToString:@"Return Initiated"] )
        [self showButton];
    else
        [self hideButton];
    
    //status tracking bar
    self.myStatusTrackingBar = [[[[NSBundle mainBundle] loadNibNamed:@"StatusTrackingBar" owner:self options:nil] firstObject] initWithProduct:self.myProduct];
    for ( UIView * tmpView in [self.superViewForStatusBar subviews] )
         [tmpView removeFromSuperview];
    [self.superViewForStatusBar addSubview:self.myStatusTrackingBar];
    self.myStatusTrackingBar.frame = CGRectMake(0, 0, self.myStatusTrackingBar.frame.size.width, self.myStatusTrackingBar.frame.size.height);
    
    self.myScrollView.contentSize = CGSizeMake(self.myScrollView.contentSize.width, self.trackingOrderView.frame.origin.y + self.trackingOrderView.frame.size.height);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    float maximumVerticalOffset = scrollView.contentSize.height - CGRectGetHeight(scrollView.frame);
    float currentVerticalOffset = scrollView.contentOffset.y;
    float percentageVerticalOffset = currentVerticalOffset / maximumVerticalOffset;
    
    [self scrollView:scrollView didScrollToPercentageOffset:percentageVerticalOffset];
}

- (void)scrollView:(UIScrollView *)scrollView didScrollToPercentageOffset:(float)percentageOffset
{
    self.productImageView.frame = CGRectMake(self.productImageView.frame.origin.x, self.originalImageYCoord - (percentageOffset*40), self.productImageView.frame.size.width, self.productImageView.frame.size.height);
}

- (void) tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    iPhone_ViewOrdersViewController * viewOrdersController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-3];
    UITabBarItem * itemToSelect = [viewOrdersController.myTabBar.items objectAtIndex:[[tabBar items] indexOfObject:item]];
    [viewOrdersController.myTabBar setSelectedItem:itemToSelect];
    [viewOrdersController.myOrderManager setDelegate:viewOrdersController];
    [viewOrdersController tabBar:viewOrdersController.myTabBar didSelectItem:itemToSelect];
    [self.navigationController popToViewController:viewOrdersController animated:YES];
}

- (IBAction)backButtonAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)atStationAction:(id)sender
{
    [SVProgressHUD show];
    [self.myOrderManager confirmProductAtStation:self.myProduct completion:^(BOOL success)
    {
        if ( success )
        {
            [SVProgressHUD showSuccessWithStatus:@"Product Updated\nSuccessfully"];
            [self populateDetails];
        }
        else
            [SVProgressHUD showErrorWithStatus:@"Error\nUpdating Status"];
    }];
}

- (void) showButton
{
    if ( self.atStationButton.hidden == NO )
        return;
    
    self.atStationButton.alpha = 0;
    self.atStationButton.hidden = NO;
    
    [UIView animateWithDuration:.2 animations:^
    {
        self.myScrollView.frame = CGRectMake(self.myScrollView.frame.origin.x, self.myScrollView.frame.origin.y, self.myScrollView.frame.size.width, (self.atStationButton.frame.origin.y ) - self.myScrollView.frame.origin.y);
    }
    completion:^(BOOL finished)
    {
        self.atStationButton.alpha = 1;
    }];
}

- (void) hideButton
{
    if ( self.atStationButton.hidden == YES )
        return;
    
    [UIView animateWithDuration:.2 animations:^
     {
         self.atStationButton.alpha = 0;
     }
                     completion:^(BOOL finished)
     {
         self.atStationButton.hidden = YES;
         self.atStationButton.alpha = 1;
         self.myScrollView.frame = CGRectMake(self.myScrollView.frame.origin.x, self.myScrollView.frame.origin.y, self.myScrollView.frame.size.width, (self.atStationButton.frame.origin.y + self.atStationButton.frame.size.height) - self.myScrollView.frame.origin.y);
     }];
}

@end
