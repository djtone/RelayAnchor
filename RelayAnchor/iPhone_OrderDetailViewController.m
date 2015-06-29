//
//  iPhone_OrderDetailViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 6/23/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_OrderDetailViewController.h"
#import "iPhone_ViewOrdersViewController.h"

@implementation iPhone_OrderDetailViewController

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - tab bar
- (void) tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    iPhone_ViewOrdersViewController * viewOrdersController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
    UITabBarItem * itemToSelect = [viewOrdersController.myTabBar.items objectAtIndex:[[tabBar items] indexOfObject:item]];
    [viewOrdersController.myTabBar setSelectedItem:itemToSelect];
    [viewOrdersController tabBar:viewOrdersController.myTabBar didSelectItem:itemToSelect];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewDidLoad{
    
    [super viewDidLoad];

    self.myOrderManager = [OrderManager sharedInstanceWithDelegate:self];
    [self.myOrderManager loadOrderDetailsForOrder:self.myOrder completion:nil];
    
    self.OrderDetailTableView.backgroundColor = [UIColor clearColor];
    self.OrderDetailTableView.backgroundView = nil;
    
    self.topBackView.layer.cornerRadius = 6.0;
    self.topBackView.layer.masksToBounds = YES;
    self.topBackView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.topBackView.layer.borderWidth = 1.0;
    
    self.OrderDetailTableView.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    
    self.orderNumberLabel.text = [NSString stringWithFormat:@"Order %@", self.myOrder.wcsOrderId];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd, hh:mma"];
    
    self.orderDateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:self.myOrder.placeTime]];
    self.orderRunnerLabel.text = self.myOrder.runnerName;
    self.orderStatusLabel.text = self.myOrder.stringFromStatus;
}

#pragma mark - order manager delegate
- (void) didFinishLoadingOrderDetails:(Order *)order
{
    
    self.myOrder = order;

    self.productsForTableView = [NSArray array];
    self.productsForTableView = self.myOrder.products;
    
    [self.OrderDetailTableView reloadData];
    self.OrderDetailTableView.hidden = NO;

}

- (void) didFinishLoadingImageType:(NSString *)type forProduct:(Product *)product
{
    for ( int i = 0; i < [self.myOrder.products count]; i++ )
    {
        Product * tmpProduct = [self.myOrder.products objectAtIndex:i];
        if ( tmpProduct.productId == product.productId )
            tmpProduct = product;
    }
    
    [self didFinishLoadingOrderDetails:self.myOrder];
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 200;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.productsForTableView.count;
}


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"productCell"];
    
    UILabel *itemNameLabel = (UILabel *)[cell.contentView viewWithTag:1];
    UILabel *storeNameLabel = (UILabel *)[cell.contentView viewWithTag:3];
    UILabel *itemPriceLabel = (UILabel *)[cell.contentView viewWithTag:2];
    UIImageView *imagePlaceholder = (UIImageView *)[cell.contentView viewWithTag:4];
    UIView *statusView = (UIView *)[cell.contentView viewWithTag:5];

    UIImageView *statusPickedUpCheckMark = (UIImageView *)[cell.contentView viewWithTag:7];
    UIImageView *statusAtStationCheckMark = (UIImageView *)[cell.contentView viewWithTag:8];
    UIImageView *statusDeliveredCheckMark = (UIImageView *)[cell.contentView viewWithTag:9];
    
    
    UILabel *statusLabel = (UILabel *)[cell.contentView viewWithTag:10];

    
    Product * tmpProduct = [self.productsForTableView objectAtIndex:indexPath.row];
    itemNameLabel.text = [NSString stringWithFormat:@"%@", tmpProduct.name];
    //cell.colorLabel.text = tmpProduct.color;
    //cell.sizeLabel.text = tmpProduct.size;
    itemPriceLabel.text = [NSString stringWithFormat:@"$%.2f", [tmpProduct.itemPrice floatValue]];
    //cell.priceLabel.text = [NSString stringWithFormat: @"%.2f", [tmpProduct.price floatValue]];
   // cell.quantityLabel.text = [NSString stringWithFormat:@"%i", [tmpProduct.quantity intValue]];
    storeNameLabel.text = tmpProduct.store;
    if ( tmpProduct.productImage )
        imagePlaceholder.image = tmpProduct.productImage;
    
 
    statusPickedUpCheckMark.hidden = YES;
    statusAtStationCheckMark.hidden = YES;
    statusDeliveredCheckMark.hidden = YES;
    
    statusView.layer.cornerRadius = 8.0;
    statusView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    statusView.layer.borderWidth = 1.0;
    
    cell.contentView.layer.borderWidth = 1.0;
    cell.contentView.layer.borderColor = [[UIColor lightGrayColor] CGColor];

    //check marks
    statusLabel.text = tmpProduct.runnerStatus;

    if ( [tmpProduct.runnerStatus isEqualToString:@"Picked Up"] || [tmpProduct.runnerStatus isEqualToString:@"At Station"] || [tmpProduct.anchorStatus isEqualToString:@"Delivered"] )
        statusPickedUpCheckMark.hidden = NO;
    if ( [tmpProduct.anchorStatus isEqualToString:@"At Station"] || [tmpProduct.anchorStatus isEqualToString:@"Delivered"] || [tmpProduct.anchorStatus isEqualToString:@"Return Initiated"] )
        statusAtStationCheckMark.hidden = NO;
    if ( [tmpProduct.anchorStatus isEqualToString:@"Delivered"] || [tmpProduct.anchorStatus isEqualToString:@"Return Initiated"] )
        statusDeliveredCheckMark.hidden = NO;
    
    
    //buttons
    /*
    if ( [tmpProduct.runnerStatus isEqualToString:@"At Station"] && ! [tmpProduct.anchorStatus isEqualToString:@"At Station"] && ! [tmpProduct.anchorStatus isEqualToString:@"Delivered"] && ! [tmpProduct.anchorStatus isEqualToString:@"Return Initiated"] )
        cell.atStationButton.hidden = NO;
    else if ( [tmpProduct.anchorStatus isEqualToString:@"At Station"] )
        cell.deliveredButton.hidden = NO;
     */
    //issue icons
    /*
    if ( [tmpProduct.status isEqualToString:@"Cancelled"] )
        cell.statusIssueCancelImage.hidden = NO;
    else if ( tmpProduct.isSubstitute )
        cell.statusIssueSubstituteImage.hidden = NO;
    if ( tmpProduct.isReturn )
        cell.statusIssueReturnImage.hidden = NO;
    */
    //swipe/longPress menu
    
    /*
    for ( UIGestureRecognizer * gesture in [[cell contentView] gestureRecognizers] )
        [[cell contentView] removeGestureRecognizer:gesture];
    
    UISwipeGestureRecognizer * swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [cell.contentView addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer * swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [cell.contentView addGestureRecognizer:swipeRight];
    
    UILongPressGestureRecognizer * longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [cell.contentView addGestureRecognizer:longPressGesture];
    
     */
    
    
    /*
    //if the order is open, show override
    if ( [tmpProduct.status isEqualToString:@"Open"] )
        cell.cancelItemButton.hidden = NO;
    else
        cell.cancelItemButton.hidden = YES;
    //the return buttons will show otherwise
    
    if ( [self.swipedProducts containsObject:tmpProduct.productId] )
        cell.swipeLeftMenu.frame = CGRectMake(cell.contentView.frame.size.width - cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.origin.y, cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.size.height);
    else
        cell.swipeLeftMenu.frame = CGRectMake(cell.contentView.frame.size.width, cell.swipeLeftMenu.frame.origin.y, cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.size.height);
    
    
    */
    
    return cell;
    /*
    ItemTableCell * cell = [tableView dequeueReusableCellWithIdentifier:@"itemTableCell"];
    
    if ( self.myOrderManager.isLoadingOrderDetails )
    {
        for ( UIView * view in [[cell contentView] subviews] )
            view.hidden = YES;
        cell.loadingIndicator.hidden = NO;
        [cell.loadingIndicator startAnimating];
    }
    else
    {
        for ( UIView * view in [[cell contentView] subviews] )
            view.hidden = NO;
        cell.loadingIndicator.hidden = YES;
        cell.statusPickedUpCheckMark.hidden = YES;
        cell.statusAtStationCheckMark.hidden = YES;
        cell.statusDeliveredCheckMark.hidden = YES;
        cell.atStationButton.hidden = YES;
        cell.deliveredButton.hidden = YES;
        cell.statusIssueCancelImage.hidden = YES;
        cell.statusIssueSubstituteImage.hidden = YES;
        cell.statusIssueReturnImage.hidden = YES;
        
        if ( indexPath.row %2 == 0 )
            [[cell contentView] setBackgroundColor:[UIColor colorWithRed:.985 green:.985 blue:.985 alpha:1]];
        else
            [[cell contentView] setBackgroundColor:[UIColor whiteColor]];
        
        Product * tmpProduct = [self.productsForTableView objectAtIndex:indexPath.row];
        cell.itemNameLabel.text = [NSString stringWithFormat:@"%@", tmpProduct.name];
        cell.colorLabel.text = tmpProduct.color;
        cell.sizeLabel.text = tmpProduct.size;
        cell.itemPriceLabel.text = [NSString stringWithFormat:@"$%.2f", [tmpProduct.itemPrice floatValue]];
        cell.priceLabel.text = [NSString stringWithFormat: @"%.2f", [tmpProduct.price floatValue]];
        cell.quantityLabel.text = [NSString stringWithFormat:@"%i", [tmpProduct.quantity intValue]];
        cell.storeNameLabel.text = tmpProduct.store;
        if ( tmpProduct.productImage )
            cell.imagePlaceholder.image = tmpProduct.productImage;
        
        //check marks
        if ( [tmpProduct.runnerStatus isEqualToString:@"Picked Up"] || [tmpProduct.runnerStatus isEqualToString:@"At Station"] || [tmpProduct.anchorStatus isEqualToString:@"Delivered"] )
            cell.statusPickedUpCheckMark.hidden = NO;
        if ( [tmpProduct.anchorStatus isEqualToString:@"At Station"] || [tmpProduct.anchorStatus isEqualToString:@"Delivered"] || [tmpProduct.anchorStatus isEqualToString:@"Return Initiated"] )
            cell.statusAtStationCheckMark.hidden = NO;
        if ( [tmpProduct.anchorStatus isEqualToString:@"Delivered"] || [tmpProduct.anchorStatus isEqualToString:@"Return Initiated"] )
            cell.statusDeliveredCheckMark.hidden = NO;
        //buttons
        if ( [tmpProduct.runnerStatus isEqualToString:@"At Station"] && ! [tmpProduct.anchorStatus isEqualToString:@"At Station"] && ! [tmpProduct.anchorStatus isEqualToString:@"Delivered"] && ! [tmpProduct.anchorStatus isEqualToString:@"Return Initiated"] )
            cell.atStationButton.hidden = NO;
        else if ( [tmpProduct.anchorStatus isEqualToString:@"At Station"] )
            cell.deliveredButton.hidden = NO;
        //issue icons
        if ( [tmpProduct.status isEqualToString:@"Cancelled"] )
            cell.statusIssueCancelImage.hidden = NO;
        else if ( tmpProduct.isSubstitute )
            cell.statusIssueSubstituteImage.hidden = NO;
        if ( tmpProduct.isReturn )
            cell.statusIssueReturnImage.hidden = NO;
        
        //swipe/longPress menu
        for ( UIGestureRecognizer * gesture in [[cell contentView] gestureRecognizers] )
            [[cell contentView] removeGestureRecognizer:gesture];
        
        UISwipeGestureRecognizer * swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
        swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        [cell.contentView addGestureRecognizer:swipeLeft];
        
        UISwipeGestureRecognizer * swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        [cell.contentView addGestureRecognizer:swipeRight];
        
        UILongPressGestureRecognizer * longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        [cell.contentView addGestureRecognizer:longPressGesture];
        
        //if the order is open, show override
        if ( [tmpProduct.status isEqualToString:@"Open"] )
            cell.cancelItemButton.hidden = NO;
        else
            cell.cancelItemButton.hidden = YES;
        //the return buttons will show otherwise
        
        if ( [self.swipedProducts containsObject:tmpProduct.productId] )
            cell.swipeLeftMenu.frame = CGRectMake(cell.contentView.frame.size.width - cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.origin.y, cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.size.height);
        else
            cell.swipeLeftMenu.frame = CGRectMake(cell.contentView.frame.size.width, cell.swipeLeftMenu.frame.origin.y, cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.size.height);
    }
    return cell;
     
     */
    
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
