//
//  OrderDetailViewController.m
//  RelayAnchor
//
//  Created by chuck on 8/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "OrderDetailViewController.h"
#import "ItemTableCell.h"
#import "OrdersViewController.h"
#import "ItemDetailViewController.h"
#import "SVProgressHUD.h"
#import "HomeViewController.h"

@implementation OrderDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.myOrderManager = [OrderManager sharedInstanceWithDelegate:self];
    [self.myOrderManager loadOrderDetailsForOrder:self.myOrder];
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(refreshDetails) userInfo:nil repeats:YES];
    
    //printing
    self.myPrintManager = [PrintManager sharedPrintManager];
    
    //ui stuff
    [self setNeedsStatusBarAppearanceUpdate];
    self.OrderDetailTableView.delaysContentTouches = NO;
    self.swipedProducts = [[NSMutableArray alloc] init];
    
    //top view
    self.myTopView = [[[NSBundle mainBundle] loadNibNamed:@"TopView" owner:self options:nil] firstObject];
    self.myTopView.delegate = self;
    [self.view addSubview:self.myTopView];
    
    //bottom view
    self.myBottomView = [[[NSBundle mainBundle] loadNibNamed:@"BottomView" owner:self options:nil] firstObject];
    self.myBottomView.delegate = self;
    [self.view addSubview:self.myBottomView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.OrderDetailTableView reloadData];
}

#pragma mark - tableview delegate/datasource
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView * headerView = [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectMake(0, 0, 1000, 50)];
    headerView.clipsToBounds = YES;
    [[headerView contentView] setBackgroundColor:[UIColor whiteColor]];
    
    UILabel * headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 0, 1000, 50)];
    [headerTitleLabel setBackgroundColor:[UIColor whiteColor]];
    [headerTitleLabel setFont:[UIFont systemFontOfSize:24]];
    [headerTitleLabel setTextColor:[UIColor colorWithRed:(float)238/255 green:(float)118/255 blue:(float)36/255 alpha:1]];
    [headerTitleLabel setText:[NSString stringWithFormat:@"Order %@", self.myOrder.orderId]];
    [headerView addSubview:headerTitleLabel];
    
    UILabel * orderPriceLabel = [[UILabel alloc] initWithFrame:CGRectMake(900, 0, 1000, 50)];
    [orderPriceLabel setBackgroundColor:[UIColor whiteColor]];
    [orderPriceLabel setFont:[UIFont systemFontOfSize:20]];
    [orderPriceLabel setTextColor:[UIColor colorWithRed:(float)238/255 green:(float)118/255 blue:(float)36/255 alpha:1]];
    [orderPriceLabel setText:[NSString stringWithFormat:@"$%.2f", [self.myOrder.totalPrice floatValue]]];
    [headerView addSubview:orderPriceLabel];
    
    UIView * borderLine = [[UIView alloc] initWithFrame:CGRectMake(0, 48, 1000, 2)];
    [borderLine setBackgroundColor:[UIColor colorWithRed:.85 green:.85 blue:.85 alpha:1]];
    [headerView addSubview:borderLine];
    
    UIButton * printButton = [[UIButton alloc] initWithFrame:CGRectMake(220, 9, 35, 35)];
    [printButton setImage:[UIImage imageNamed:@"printerIcon.png"] forState:UIControlStateNormal];
    [printButton addTarget:self action:@selector(printAction:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:printButton];
    
    return headerView;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( self.myOrderManager.isLoadingOrderDetails )
        return 1;
    return self.productsForTableView.count;
}


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        if ( tmpProduct.isSubstitute )
            cell.statusIssueSubstituteImage.hidden = NO;
        if ( tmpProduct.isReturn )
            cell.statusIssueReturnImage.hidden = NO;
        
        UISwipeGestureRecognizer * swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
        swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        [cell addGestureRecognizer:swipeLeft];
        
        if ( [self.swipedProducts containsObject:tmpProduct.productId] )
            cell.setStatusButtonsView.frame = CGRectMake(700, cell.setStatusButtonsView.frame.origin.y, cell.setStatusButtonsView.frame.size.width, cell.setStatusButtonsView.frame.size.height);
        else
            cell.setStatusButtonsView.frame = CGRectMake(1000, cell.setStatusButtonsView.frame.origin.y, cell.setStatusButtonsView.frame.size.width, cell.setStatusButtonsView.frame.size.height);
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.OrderDetailTableView deselectRowAtIndexPath:[self.OrderDetailTableView indexPathForSelectedRow] animated:YES];
    if ( [(ItemTableCell *)[self.OrderDetailTableView cellForRowAtIndexPath:indexPath] loadingIndicator].hidden == YES ) //make sure its not a loading cell
    {
        Product * product = [self.myOrder.products objectAtIndex:indexPath.row];
        
        if ( [self.swipedProducts containsObject:product.productId] )
        {
            ItemTableCell * cell = (ItemTableCell *)[self.OrderDetailTableView cellForRowAtIndexPath:indexPath];
            [UIView animateWithDuration:.5 animations:^
             {
                 cell.setStatusButtonsView.frame = CGRectMake(1000, cell.setStatusButtonsView.frame.origin.y, cell.setStatusButtonsView.frame.size.width, cell.setStatusButtonsView.frame.size.height);
             }];
            [self.swipedProducts removeObject:product.productId];
        }
        else
        {
            [self.refreshTimer invalidate];
            ItemDetailViewController * modalItemDetailViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"itemDetailPage"];
            modalItemDetailViewController.myProduct = product;
            modalItemDetailViewController.tmpOrderNumber = [self.myTopView.orderNumberLabel.text intValue];
            modalItemDetailViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:modalItemDetailViewController animated:YES completion:nil];
        }
    }
}

- (void) handleSwipeLeft:(UITapGestureRecognizer *)tapGesture
{
    ItemTableCell * cell = (ItemTableCell *)[tapGesture view];
    [UIView animateWithDuration:.3 animations:^
    {
        cell.setStatusButtonsView.frame = CGRectMake(700, cell.setStatusButtonsView.frame.origin.y, cell.setStatusButtonsView.frame.size.width, cell.setStatusButtonsView.frame.size.height);
    }];
    
    Product * product = [self.myOrder.products objectAtIndex:[[self.OrderDetailTableView indexPathForCell:cell] row]];
    [self.swipedProducts addObject:product.productId];
}

#pragma mark - set status actions
- (IBAction)setStatusReturnPendingAction:(id)sender
{
    [SVProgressHUD showImage:nil status:@"?"];
    /*
    ItemTableCell * cell;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
        cell = (ItemTableCell *)[[[sender superview] superview] superview];
    else
        cell = (ItemTableCell *)[[[[sender superview] superview] superview] superview];
    Product * product = [self.myOrder.products objectAtIndex:[[self.OrderDetailTableView indexPathForCell:cell] row]];
     
    [SVProgressHUD showWithStatus:@"Saving Status"];
    [self.myOrderManager confirmProductReturnByCustomer:product completion:^(BOOL success)
    {
        if ( success )
            [SVProgressHUD showSuccessWithStatus:@"Status Saved"]; //animate the side menu back
        else
            [SVProgressHUD showErrorWithStatus:@"Issue Saving Status"];
    }];
     */
}

- (IBAction)setStatusReturnConfirmedAction:(id)sender
{
    ItemTableCell * cell;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
        cell = (ItemTableCell *)[[[sender superview] superview] superview];
    else
        cell = (ItemTableCell *)[[[[sender superview] superview] superview] superview];
    Product * product = [self.myOrder.products objectAtIndex:[[self.OrderDetailTableView indexPathForCell:cell] row]];
    
    if ( product.returnReceiptImage == nil )
        [SVProgressHUD showErrorWithStatus:@"Return Receipt Required"];
    else
    {
        [SVProgressHUD showWithStatus:@"Saving Status"];
        [self.myOrderManager confirmProductReturnToStore:product completion:^(BOOL success)
        {
            if ( success )
                [SVProgressHUD showSuccessWithStatus:@"Status Saved"]; //animate the side menu back
            else
                [SVProgressHUD showErrorWithStatus:@"Issue Saving Status"];
        }];
    }
}

- (IBAction)setStatusReturnRejectedAction:(id)sender
{
    ItemTableCell * cell;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
        cell = (ItemTableCell *)[[[sender superview] superview] superview];
    else
        cell = (ItemTableCell *)[[[[sender superview] superview] superview] superview];
    Product * product = [self.myOrder.products objectAtIndex:[[self.OrderDetailTableView indexPathForCell:cell] row]];
    
    [SVProgressHUD showWithStatus:@"Saving Status"];
    [self.myOrderManager confirmProductReturnRejected:product completion:^(BOOL success)
    {
        if ( success )
            [SVProgressHUD showSuccessWithStatus:@"Status Saved"]; //animate the side menu back
        else
            [SVProgressHUD showErrorWithStatus:@"Issue Saving Status"];
    }];
}

- (IBAction)atStationAction:(id)sender
{
    ItemTableCell * cell;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
        cell = (ItemTableCell *)[[[sender superview] superview] superview];
    else
        cell = (ItemTableCell *)[[[[sender superview] superview] superview] superview];
    
    self.activeProduct = [self.productsForTableView objectAtIndex:[[self.OrderDetailTableView indexPathForCell:cell] row]];
    
    if ( self.activeProduct.purchaseReceiptImage == nil )
        [SVProgressHUD showErrorWithStatus:@"No Receipt Provided"];
    else
    {
        if ( [self.myOrderManager isLastProductToApprove:self.activeProduct] )
        {
            [SVProgressHUD showWithStatus:@"Uploading Receipt"];
            UIImage * purchaseReceiptImage = [self.myOrderManager mergeReceiptImagesWithType:@"purchase" forOrder:self.myOrder];
            [self.myOrderManager uploadReceiptImage:purchaseReceiptImage withType:@"purchase" forOrder:self.myOrder];
        }
        else
        {
            [SVProgressHUD showWithStatus:@"Setting Status"];
            __weak typeof(self) weakSelf = self;
            [self.myOrderManager confirmProductAtStation:self.activeProduct completion:^(BOOL success)
            {
                if ( success )
                {
                    [SVProgressHUD showSuccessWithStatus:@"Status Saved"];
                    [weakSelf animateStatusButtonsForCell:cell toStatus:@"At Station"];
                }
                else
                    [SVProgressHUD showErrorWithStatus:@"Error Saving Status"];
            }];
        }
    }
}

- (IBAction)deliveredAction:(id)sender
{
    if ( [self.myOrderManager allItemsAreAtStationForOrder:self.myOrder] )
    {
        [SVProgressHUD showWithStatus:@"Setting Status"];
        [self.myOrderManager confirmDeliveryForOrder:self.myOrder completion:^(BOOL success)
        {
            if ( success )
            {
                [SVProgressHUD showSuccessWithStatus:@"Status Saved"];
                
                NSMutableArray * tmpOrdersForTableView = [[(OrdersViewController *)[self presentingViewController] ordersForTableView] mutableCopy];
                [tmpOrdersForTableView removeObject:self.myOrder];
                [(OrdersViewController *)[self presentingViewController] setOrdersForTableView:tmpOrdersForTableView];
                
                for ( int i = 0; i < [self.productsForTableView count]; i++ )
                    [self animateStatusButtonsForCell:(ItemTableCell *)[self.OrderDetailTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]] toStatus:@"Delivered"];
            }
            else
                [SVProgressHUD showErrorWithStatus:@"Error Changing Status"];
        }];
    }
    else
        [SVProgressHUD showErrorWithStatus:@"All Items Must Be\nAtStation"];
}

- (void) animateStatusButtonsForCell:(ItemTableCell *)cell toStatus:(NSString *)status
{
    if ( [status isEqualToString:@"At Station"] )
    {
        cell.deliveredButton.alpha = 0;
        cell.deliveredButton.hidden = NO;
        cell.statusAtStationCheckMark.alpha = 0;
        cell.statusAtStationCheckMark.hidden = NO;
        [UIView animateWithDuration:.3 animations:^
        {
            cell.atStationButton.alpha = 0;
            cell.deliveredButton.alpha = 1;
            cell.statusAtStationCheckMark.alpha = 1;
        }
        completion:^(BOOL finished)
        {
            cell.atStationButton.hidden = YES;
            cell.atStationButton.alpha = 1;
        }];
    }
    else if ( [status isEqualToString:@"Delivered"] )
    {
        cell.statusDeliveredCheckMark.alpha = 0;
        cell.statusDeliveredCheckMark.hidden = NO;
        [UIView animateWithDuration:.3 animations:^
        {
            cell.deliveredButton.alpha = 0;
            cell.statusDeliveredCheckMark.alpha = 1;
        }
        completion:^(BOOL finished)
        {
            cell.deliveredButton.hidden = YES;
            cell.deliveredButton.alpha = 1;
        }];
    }
}

#pragma mark - order manager delegate
- (void) didFinishLoadingOrderDetails:(Order *)order
{
    self.myOrder = order;
    
    if ( [self.myTopView.searchBarTextField.text length] != 0 )
        self.productsForTableView = [self.myOrderManager searchOrders:self.productsForTableView withString:self.myTopView.searchBarTextField.text];
    else
        self.productsForTableView = self.myOrder.products;
    
    [self.OrderDetailTableView reloadData];
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

- (void) didFinishLoadingOrders:(NSArray *)orders withStatusOpen:(BOOL)open ready:(BOOL)ready delivered:(BOOL)delivered cancelledReturned:(BOOL)cancelledReturned
{
    // setting the top view bell thing number
    if ( open )
    {
        int numberOfOpenOrders = 0;
        for ( int i = 0; i < [orders count]; i++ )
        {
            if ( [[[orders objectAtIndex:i] status] isEqualToString:@"Open"] )
                numberOfOpenOrders++;
        }
        self.myTopView.orderNumberLabel.text = [NSString stringWithFormat:@"%i", numberOfOpenOrders];
    }
}

- (void) didFinishUploadingReceipt:(NSURL *)receiptUrl
{
    self.myOrder.purchaseReceiptUrl = receiptUrl;
    self.myOrder.purchaseReceiptImage =  self.activeProduct.purchaseReceiptImage;
    for ( int i = 0; i < [self.myOrder.products count]; i++ )
    {
        [(Product *)[self.myOrder.products objectAtIndex:i] setPurchaseReceiptImage:self.myOrder.purchaseReceiptImage];
        [(Product *)[self.myOrder.products objectAtIndex:i] setPurchaseReceiptUrl:receiptUrl];
    }
    
    __weak typeof(self) weakSelf = self;
    [self.myOrderManager confirmProductAtStation:self.activeProduct completion:^(BOOL success)
    {
        if ( success )
        {
            [SVProgressHUD showSuccessWithStatus:@"Status Saved"];
            ItemTableCell * cell = (ItemTableCell *)[weakSelf.OrderDetailTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[weakSelf.productsForTableView indexOfObject:weakSelf.activeProduct] inSection:0]];
            [weakSelf animateStatusButtonsForCell:cell toStatus:@"At Station"];
        }
        else
            [SVProgressHUD showErrorWithStatus:@"Error Saving Status"];
    }];
}

- (void) didFailUploadingReceipt:(NSString *)errorMessage
{
    [SVProgressHUD showErrorWithStatus:@"Issue Saving Receipt"];
}

- (void) didFinishPrintingReceiptForOrder:(Order *)order
{
    NSLog(@"receipt printed for order id : %@", order.orderId);
}

- (void) didFailPrintingReceiptForOrder:(Order *)order
{
    NSLog(@"failed printing receipt for order id : %@", order.orderId);
}


#pragma mark - contact view delegate
- (void) didPressCall
{
    [SVProgressHUD showImage:nil status:@"Coming Soon"];
}

- (void) didPressText
{
    [SVProgressHUD showImage:nil status:@"Coming Soon"];
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"sms://%@", self.myProduct.runnerPhoneNumber]]];
}

- (void) didPressMail
{
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"@mailto:%@", self.my]];
    [SVProgressHUD showImage:nil status:@"Coming Soon"];
}

#pragma mark - top view delegate
- (void) searchBarTextDidChange:(NSString *)searchString
{
    if ( [searchString length] == 0 )
        self.productsForTableView = self.myOrder.products;
    else
        self.productsForTableView = [self.myOrderManager searchProducts:self.myOrder.products withString:searchString];
    
    [self.OrderDetailTableView reloadData];
}

- (void) didPressAlertButton
{
    [self.myBottomView openButtonAction:nil];
}

- (void) didPressLogout
{
    UIViewController * modalToDismissFrom = self;
    while ( ! [[[modalToDismissFrom presentingViewController] restorationIdentifier] isEqualToString:@"loginPage"] )
        modalToDismissFrom = [modalToDismissFrom presentingViewController];
    modalToDismissFrom = [modalToDismissFrom presentingViewController];
    [modalToDismissFrom dismissViewControllerAnimated:YES completion:nil];
}

- (void) didPressBackButton
{
    [self.refreshTimer invalidate];
    OrdersViewController * ordersViewController = (OrdersViewController *)self.presentingViewController;
    
    if ( self.didNavigateFromHomeScreen )
    {
        HomeViewController * homeViewController = (HomeViewController *)ordersViewController.presentingViewController;
        self.myOrderManager.delegate = homeViewController;
        [homeViewController myTopView].orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
        homeViewController.updateOrdersTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self.myOrderManager selector:@selector(loadAllOrders) userInfo:nil repeats:YES];
        
        UIGraphicsBeginImageContext(self.view.window.bounds.size);
        [self.view.window.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage * overlayImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        UIImageView * imageOverlay = [[UIImageView alloc] initWithImage:overlayImage];
        
        if ( [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight || self.interfaceOrientation == 4 )
            imageOverlay.transform = CGAffineTransformMakeRotation(M_PI_2);
        else
            imageOverlay.transform = CGAffineTransformMakeRotation(-M_PI_2);
        
        imageOverlay.frame = CGRectMake(0, 0, 1024, 768);
        [ordersViewController.view addSubview:imageOverlay];
        [self dismissViewControllerAnimated:NO completion:nil];
        [ordersViewController dismissViewControllerAnimated:YES completion:^
        {
            [imageOverlay removeFromSuperview];
        }];
    }
    else
    {
        [ordersViewController myTopView].orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
        ordersViewController.updateOrdersTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:ordersViewController selector:@selector(refreshOrders) userInfo:nil repeats:YES];
        if ( [ordersViewController myBottomView].selectedStatus == nil )
            [[ordersViewController myBottomView] openButtonAction:nil];
        self.myOrderManager.delegate = ordersViewController;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - bottom view delegate
- (void) didPressOpen
{
    [self.refreshTimer invalidate];
    UIViewController * modalToDismissFrom = self;
    while ( ! [[[modalToDismissFrom presentingViewController] restorationIdentifier] isEqualToString:@"homePage"] )
        modalToDismissFrom = [modalToDismissFrom presentingViewController];
    self.myOrderManager.delegate = (id<OrderManagerDelegate>)modalToDismissFrom;
    [[(OrdersViewController *)modalToDismissFrom myBottomView] performSelector:@selector(openButtonAction:) withObject:self afterDelay:0];
    [modalToDismissFrom dismissViewControllerAnimated:YES completion:nil];
}

- (void) didPressReady
{
    [self.refreshTimer invalidate];
    UIViewController * modalToDismissFrom = self;
    while ( ! [[[modalToDismissFrom presentingViewController] restorationIdentifier] isEqualToString:@"homePage"] )
        modalToDismissFrom = [modalToDismissFrom presentingViewController];
    self.myOrderManager.delegate = (id<OrderManagerDelegate>)modalToDismissFrom;
    [[(OrdersViewController *)modalToDismissFrom myBottomView] performSelector:@selector(readyButtonAction:) withObject:self afterDelay:0];
    [modalToDismissFrom dismissViewControllerAnimated:YES completion:nil];
}

- (void) didPressDelivered
{
    [self.refreshTimer invalidate];
    UIViewController * modalToDismissFrom = self;
    while ( ! [[[modalToDismissFrom presentingViewController] restorationIdentifier] isEqualToString:@"homePage"] )
        modalToDismissFrom = [modalToDismissFrom presentingViewController];
    self.myOrderManager.delegate = (id<OrderManagerDelegate>)modalToDismissFrom;
    [[(OrdersViewController *)modalToDismissFrom myBottomView] performSelector:@selector(deliveredButtonAction:) withObject:self afterDelay:0];
    [modalToDismissFrom dismissViewControllerAnimated:YES completion:nil];
}

- (void) didPressCancelledReturned
{
    [self.refreshTimer invalidate];
    UIViewController * modalToDismissFrom = self;
    while ( ! [[[modalToDismissFrom presentingViewController] restorationIdentifier] isEqualToString:@"homePage"] )
        modalToDismissFrom = [modalToDismissFrom presentingViewController];
    self.myOrderManager.delegate = (id<OrderManagerDelegate>)modalToDismissFrom;
    [[(OrdersViewController *)modalToDismissFrom myBottomView] performSelector:@selector(cancelledReturnedButtonAction:) withObject:self afterDelay:0];
    [modalToDismissFrom dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - printing
- (void) printAction:(id)sender
{
    [SVProgressHUD showWithStatus:@"Printing"];
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
    {
        [self.myPrintManager printReceiptForOrder:self.myOrder fromView:nil completion:^(BOOL success)
         {
             [SVProgressHUD showSuccessWithStatus:@"Printed Successfully"];
         }];
    }
    else
    {
        [self.myPrintManager printReceiptForOrder:self.myOrder fromView:(UIButton *)sender completion:^(BOOL success)
         {
             [SVProgressHUD showSuccessWithStatus:@"Printed Successfully"];
         }];
    }
}

#pragma mark - misc.
- (void) refreshDetails
{
    [self.myOrderManager loadOrderDetailsForOrder:self.myOrder];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
