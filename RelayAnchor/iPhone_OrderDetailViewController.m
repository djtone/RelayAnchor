//
//  iPhone_OrderDetailViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 6/23/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_OrderDetailViewController.h"
#import "iPhone_ViewOrdersViewController.h"
#import "iPhone_ItemDetailViewController.h"
#import "StatusTrackingBar.h"
#import "UIAlertView+Blocks.h"
#import "SVProgressHUD.h"

@implementation iPhone_OrderDetailViewController

-(void)viewDidLoad
{
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
    self.swipedProductIds = [[NSMutableArray alloc] init];
    
    self.myReceiptPopup = [[[NSBundle mainBundle] loadNibNamed:@"ReceiptPopup" owner:self options:nil] firstObject];
    self.myReceiptPopup.delegate = self;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self.myReceiptPopup.frame = CGRectMake(screenRect.size.width/2 - self.myReceiptPopup.frame.size.width/2, self.OrderDetailTableView.frame.origin.y, self.myReceiptPopup.frame.size.width, self.myReceiptPopup.frame.size.height);
    self.myReceiptPopup.hidden = YES;
    self.receiptOverlay = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    [self.receiptOverlay addTarget:self action:@selector(hideReceiptPopup) forControlEvents:UIControlEventTouchUpInside];
    [self.receiptOverlay setBackgroundColor:[UIColor colorWithWhite:.5 alpha:.5]];
    self.receiptOverlay.hidden = YES;
    [self.view addSubview:self.receiptOverlay];
    [self.view addSubview:self.myReceiptPopup];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.orderNumberLabel.text = [NSString stringWithFormat:@"Order %@", self.myOrder.wcsOrderId];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd, hh:mma"];
    
    self.orderDateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:self.myOrder.placeTime]];
    self.orderRunnerLabel.text = self.myOrder.runnerName;
    self.orderStatusLabel.text = self.myOrder.displayStatus;
    self.colorDot.backgroundColor = self.myOrder.displayColor;
    
    CGSize textSize = [self.orderStatusLabel.text sizeWithAttributes:@{NSFontAttributeName:[self.orderStatusLabel font]}];
    if ( textSize.width > self.orderStatusLabel.frame.size.width )
        textSize.width = self.orderStatusLabel.frame.size.width;
    [self.colorDot setFrame:CGRectMake(([self.colorDot superview].frame.size.width - 64) - textSize.width, self.colorDot.frame.origin.y, self.colorDot.frame.size.width, self.colorDot.frame.size.height)];
}

#pragma mark - order manager delegate
- (void) didFinishLoadingOrderDetails:(Order *)order
{
    //retain receipt (im assuming i need to do this)
    NSURL * tmpReceiptURL = self.myOrder.purchaseReceiptUrl;
    UIImage * tmpReceiptImage = self.myOrder.purchaseReceiptImage;
    self.myOrder = order;
    self.myOrder.purchaseReceiptUrl = tmpReceiptURL;
    self.myOrder.purchaseReceiptImage = tmpReceiptImage;

    self.productsForTableView = [NSArray array];
    self.productsForTableView = self.myOrder.products;
    
    [self.OrderDetailTableView reloadData];
    [self showTable];
    
    if ( self.myOrder.runnerStatus == kRunnerStatusAtStation && self.myOrder.anchorStatus == kAnchorStatusAtStation )
    {
        //set mybutton to confirm delivery
        [self.myButton setTitle:@"Delivered" forState:UIControlStateNormal];
        [self.myButton setBackgroundColor:[UIColor colorWithRed:109/255.0 green:202/255.0 blue:72/255.0 alpha:1]];
        [self showButton];
    }
    else if ( [self.myOrder.displayStatus isEqualToString:@"Open"] )
    {
        //set myButton to override action
        [self.myButton setTitle:@"Override Ready Status" forState:UIControlStateNormal];
        [self.myButton setBackgroundColor:[UIColor colorWithRed:255/255.0 green:174/255.0 blue:18/255.0 alpha:1]];
        [self showButton];
    }
    else
        [self hideButton];
}

- (void) didFinishLoadingImageType:(NSString *)type forProduct:(Product *)product
{
    for ( int i = 0; i < [self.myOrder.products count]; i++ )
    {
        Product * tmpProduct = [self.myOrder.products objectAtIndex:i];
        if ( tmpProduct.productId == product.productId )
            tmpProduct = product;
    }
    
    [self.OrderDetailTableView reloadData];
}

- (void) didFinishUploadingReceipt:(NSURL *)receiptUrl
{
    if ( receiptUrl != nil )
    {
        self.myOrder.purchaseReceiptUrl = receiptUrl;
        self.myOrder.purchaseReceiptImage =  self.activeProduct.purchaseReceiptImage;
        for ( int i = 0; i < [self.myOrder.products count]; i++ )
        {
            [(Product *)[self.myOrder.products objectAtIndex:i] setPurchaseReceiptImage:self.myOrder.purchaseReceiptImage];
            [(Product *)[self.myOrder.products objectAtIndex:i] setPurchaseReceiptUrl:receiptUrl];
        }
        [self didFinishLoadingOrderDetails:self.myOrder];
    }
    
    [self.myOrderManager confirmProductAtStation:self.activeProduct completion:^(BOOL success)
    {
        if ( success )
        {
            [SVProgressHUD showSuccessWithStatus:@"Status Saved"];
            [self didFinishLoadingOrderDetails:self.myOrder];
        }
        else
            [SVProgressHUD showErrorWithStatus:@"Error Saving Status"];
     }];
}

#pragma mark - table view
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    UILabel *storeNameLabel = (UILabel *)[cell.contentView viewWithTag:2];
    
    UILabel *itemPriceLabel = (UILabel *)[cell.contentView viewWithTag:3];
    UIImageView *priceIcon = (UIImageView *)[cell.contentView viewWithTag:11];
    UIView *divider1 = [cell.contentView viewWithTag:12];
    
    UIImageView *imagePlaceholder = (UIImageView *)[cell.contentView viewWithTag:4];
    UIView *statusView = (UIView *)[cell.contentView viewWithTag:5];
    
    UILabel *colorLabel = (UILabel *)[cell.contentView viewWithTag:13];
    UIView *divider2 = [cell.contentView viewWithTag:16];
    UIImageView *sizeIcon = (UIImageView *)[cell.contentView viewWithTag:15];
    UILabel *sizeLabel = (UILabel *)[cell.contentView viewWithTag:14];
    
    UIButton *atStationButton = (UIButton *)[cell.contentView viewWithTag:17];
    
    CGSize textSize;
    Product * tmpProduct = [self.productsForTableView objectAtIndex:indexPath.row];
    itemNameLabel.text = [NSString stringWithFormat:@"%@", tmpProduct.name];
    
    //store and price labels
    itemPriceLabel.text = [NSString stringWithFormat:@"$%.2f", [tmpProduct.itemPrice floatValue]];
    textSize = [itemPriceLabel.text sizeWithAttributes:@{NSFontAttributeName:[itemPriceLabel font]}];
    itemPriceLabel.frame = CGRectMake(([itemPriceLabel superview].frame.size.width - 18) - textSize.width, itemPriceLabel.frame.origin.y, textSize.width, itemPriceLabel.frame.size.height);
    priceIcon.frame = CGRectMake((itemPriceLabel.frame.origin.x - 4) - priceIcon.frame.size.width, priceIcon.frame.origin.y, priceIcon.frame.size.width, priceIcon.frame.size.height);
    
    divider1.frame = CGRectMake(priceIcon.frame.origin.x - 8, divider1.frame.origin.y, divider1.frame.size.width, divider1.frame.size.height);
    
    storeNameLabel.text = tmpProduct.store;
    storeNameLabel.frame = CGRectMake(storeNameLabel.frame.origin.x, storeNameLabel.frame.origin.y, divider1.frame.origin.x - storeNameLabel.frame.origin.x, storeNameLabel.frame.size.height);
    
    textSize = [storeNameLabel.text sizeWithAttributes:@{NSFontAttributeName:[storeNameLabel font]}];
    if ( storeNameLabel.frame.origin.x + textSize.width + 8 < divider1.frame.origin.x )
    {
        storeNameLabel.frame = CGRectMake(storeNameLabel.frame.origin.x, storeNameLabel.frame.origin.y, textSize.width, storeNameLabel.frame.size.height);
        divider1.frame = CGRectMake(storeNameLabel.frame.origin.x + storeNameLabel.frame.size.width + 8, divider1.frame.origin.y, divider1.frame.size.width, divider1.frame.size.height);
        priceIcon.frame = CGRectMake(divider1.frame.origin.x + 9, priceIcon.frame.origin.y, priceIcon.frame.size.width, priceIcon.frame.size.height);
        itemPriceLabel.frame = CGRectMake(priceIcon.frame.origin.x + priceIcon.frame.size.width + 4, itemPriceLabel.frame.origin.y, itemPriceLabel.frame.size.width, itemPriceLabel.frame.size.height);
    }
    
    //color and size labels
    colorLabel.text = tmpProduct.color;
    textSize = [colorLabel.text sizeWithAttributes:@{NSFontAttributeName:[colorLabel font]}];
    colorLabel.frame = CGRectMake(colorLabel.frame.origin.x, colorLabel.frame.origin.y, textSize.width, colorLabel.frame.size.height);
    
    divider2.frame = CGRectMake(colorLabel.frame.origin.x + colorLabel.frame.size.width + 8, divider2.frame.origin.y, divider2.frame.size.width, divider2.frame.size.height);
    
    sizeIcon.frame = CGRectMake(divider2.frame.origin.x + 9, sizeIcon.frame.origin.y, sizeIcon.frame.size.width, sizeIcon.frame.size.height);
    sizeLabel.text = tmpProduct.size;
    textSize = [sizeLabel.text sizeWithAttributes:@{NSFontAttributeName:[sizeLabel font]}];
    sizeLabel.frame = CGRectMake(sizeIcon.frame.origin.x + sizeIcon.frame.size.width + 4, sizeLabel.frame.origin.y, textSize.width, sizeLabel.frame.size.height);
    
    imagePlaceholder.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    if ( tmpProduct.productImage )
        imagePlaceholder.image = tmpProduct.productImage;
    
    //status tracking bar
    statusView.layer.cornerRadius = 8.0;
    statusView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    statusView.layer.borderWidth = 1.0;
    for ( UIView * tmpView in [statusView subviews] )
            [tmpView removeFromSuperview];
    StatusTrackingBar * tmpStatusTrackingBar = [[[[NSBundle mainBundle] loadNibNamed:@"StatusTrackingBar" owner:self options:nil] firstObject] initWithProduct:tmpProduct];
    [statusView addSubview:tmpStatusTrackingBar];
    tmpStatusTrackingBar.frame = CGRectMake(0, 0, tmpStatusTrackingBar.frame.size.width, tmpStatusTrackingBar.frame.size.height);
    
    cell.contentView.layer.borderWidth = 1.0;
    cell.contentView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    //swipe/longPress menu
    for ( UIGestureRecognizer * gesture in [[cell contentView] gestureRecognizers] )
        [[cell contentView] removeGestureRecognizer:gesture];
    
    //only pending at station products should have swipe button
    if ( [tmpProduct.runnerStatus isEqualToString:@"At Station"] && ! [tmpProduct.anchorStatus isEqualToString:@"At Station"] && ! [tmpProduct.anchorStatus isEqualToString:@"Delivered"] && ! [tmpProduct.anchorStatus isEqualToString:@"Return Initiated"] )
    {
        UILongPressGestureRecognizer * longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        [cell.contentView addGestureRecognizer:longPressGesture];
        
        UISwipeGestureRecognizer * swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
        swipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [cell.contentView addGestureRecognizer:swipeLeftGesture];
        
        UISwipeGestureRecognizer * swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
        swipeRightGesture.direction = UISwipeGestureRecognizerDirectionRight;
        [cell.contentView addGestureRecognizer:swipeRightGesture];
    }
    
    if ( [self.swipedProductIds containsObject:tmpProduct.productId] )
        atStationButton.frame = CGRectMake(cell.contentView.frame.size.width - atStationButton.frame.size.width, atStationButton.frame.origin.y, atStationButton.frame.size.width, atStationButton.frame.size.height);
    else
        atStationButton.frame = CGRectMake(cell.contentView.frame.size.width, atStationButton.frame.origin.y, atStationButton.frame.size.width, atStationButton.frame.size.height);
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"toItemDetail" sender:[self.productsForTableView objectAtIndex:indexPath.row]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) handleLongPressGesture:(UILongPressGestureRecognizer *)gesture
{
    if ( gesture.state == UIGestureRecognizerStateBegan )
    {
        UITableViewCell * cell;
        if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
            cell = (UITableViewCell *)[[gesture view] superview];
        else
            cell = (UITableViewCell *)[[[gesture view] superview] superview];
        
        [self toggleSwipeMenuForCell:cell];
    }
}

- (void) handleSwipeGesture:(UISwipeGestureRecognizer *)gesture
{
    [self.OrderDetailTableView deselectRowAtIndexPath:[self.OrderDetailTableView indexPathForSelectedRow] animated:YES];
    UITableViewCell * cell;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
        cell = (UITableViewCell *)[[gesture view] superview];
    else
        cell = (UITableViewCell *)[[[gesture view] superview] superview];
    
    [self toggleSwipeMenuForCell:cell];
}

- (void) toggleSwipeMenuForCell:(UITableViewCell *)cell
{
    Product * tmpProduct = [self.productsForTableView objectAtIndex:[[self.OrderDetailTableView indexPathForCell:cell] section]];
    UIButton * atStationButton = (UIButton *)[cell.contentView viewWithTag:17];
    
    if ( [self.swipedProductIds containsObject:tmpProduct.productId] )
    {
        [UIView animateWithDuration:.5 animations:^
        {
            atStationButton.frame = CGRectMake(cell.contentView.frame.size.width, atStationButton.frame.origin.y, atStationButton.frame.size.width, atStationButton.frame.size.height);
        }];
        [self.swipedProductIds removeObject:tmpProduct.productId];
    }
    else
    {
        [UIView animateWithDuration:.5 animations:^
        {
            atStationButton.frame = CGRectMake(cell.contentView.frame.size.width - atStationButton.frame.size.width, atStationButton.frame.origin.y, atStationButton.frame.size.width, atStationButton.frame.size.height);
        }];
        [self.swipedProductIds addObject:tmpProduct.productId];
    }
}

#pragma mark - tab bar
- (void) tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    iPhone_ViewOrdersViewController * viewOrdersController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
    UITabBarItem * itemToSelect = [viewOrdersController.myTabBar.items objectAtIndex:[[tabBar items] indexOfObject:item]];
    [viewOrdersController.myTabBar setSelectedItem:itemToSelect];
    [viewOrdersController.myOrderManager setDelegate:viewOrdersController];
    [viewOrdersController tabBar:viewOrdersController.myTabBar didSelectItem:itemToSelect];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - receipt stuff
- (IBAction)receiptButtonAction:(id)sender
{
    if ( self.myReceiptPopup.hidden )
        [self showReceiptPopup];
    else
        [self hideReceiptPopup];
}

- (void) showReceiptPopup
{
    if ( self.myOrder.purchaseReceiptImage )
        self.myReceiptPopup.receiptImageView.image = self.myOrder.purchaseReceiptImage;
    
    self.receiptOverlay.alpha = 0;
    self.myReceiptPopup.alpha = 0;
    self.receiptOverlay.hidden = NO;
    self.myReceiptPopup.hidden = NO;
    [UIView animateWithDuration:.2 animations:^
    {
        self.receiptOverlay.alpha = 1;
        self.myReceiptPopup.alpha = 1;
    }];
}

- (void) hideReceiptPopup
{
    [UIView animateWithDuration:.2 animations:^
    {
        self.receiptOverlay.alpha = 0;
        self.myReceiptPopup.alpha = 0;
    }
    completion:^(BOOL finished)
    {
        self.receiptOverlay.hidden = YES;
        self.myReceiptPopup.hidden = YES;
        self.receiptOverlay.alpha = 1;
        self.myReceiptPopup.alpha = 1;
    }];
}

#pragma mark - receipt xib delegate
- (void) didPressCancel
{
    [self hideReceiptPopup];
}

- (void) didPressUpload
{
    [self performSegueWithIdentifier:@"toReceiptCamera" sender:self];
}

#pragma mark - receipt camera delegate
- (void) didFinishTakingReceiptPicture:(UIImage *)receiptImage
{
    //[uploadReceiptImage completion:
    //{
    self.myReceiptPopup.receiptImageView.image = receiptImage;
    [self hideReceiptPopup];
    //}];
}

#pragma mark - misc.
- (void) showTable
{
    if ( self.OrderDetailTableView.hidden == NO )
        return;
    
    self.OrderDetailTableView.alpha = 0;
    self.OrderDetailTableView.hidden = NO;
    [UIView animateWithDuration:.2 animations:^
    {
        self.OrderDetailTableView.alpha = 1;
    }];
}

- (void) hideTable
{
    if ( self.OrderDetailTableView.hidden == YES )
        return;
    
    [UIView animateWithDuration:.2 animations:^
    {
        self.OrderDetailTableView.alpha = 0;
    }
    completion:^(BOOL finished)
    {
        self.OrderDetailTableView.hidden = YES;
        self.OrderDetailTableView.alpha = 1;
    }];
}

- (void) showButton
{
    if ( self.myButton.hidden == NO )
        return;
    
    self.myButton.alpha = 0;
    self.myButton.hidden = NO;
    
    [UIView animateWithDuration:.2 animations:^
    {
        self.OrderDetailTableView.frame = CGRectMake(self.OrderDetailTableView.frame.origin.x, self.OrderDetailTableView.frame.origin.y, self.OrderDetailTableView.frame.size.width, (self.myButton.frame.origin.y ) - self.OrderDetailTableView.frame.origin.y);
    }
    completion:^(BOOL finished)
    {
        self.myButton.alpha = 1;
    }];
}

- (void) hideButton
{
    if ( self.myButton.hidden == YES )
        return;
    
    [UIView animateWithDuration:.2 animations:^
    {
        self.myButton.alpha = 0;
    }
    completion:^(BOOL finished)
    {
        self.myButton.hidden = YES;
        self.myButton.alpha = 1;
        self.OrderDetailTableView.frame = CGRectMake(self.OrderDetailTableView.frame.origin.x, self.OrderDetailTableView.frame.origin.y, self.OrderDetailTableView.frame.size.width, (self.myButton.frame.origin.y + self.myButton.frame.size.height) - self.OrderDetailTableView.frame.origin.y);
    }];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"toItemDetail"] )
        [(iPhone_ItemDetailViewController *)segue.destinationViewController setMyProduct:sender];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)myButtonAction:(id)sender
{
    NSString * buttonText = [(UIButton *)sender titleLabel].text;
    if ( [buttonText isEqualToString:@"Override Ready Status"] )
    {
        [[[UIAlertView alloc] initWithTitle:@"Override Status"
                                    message:[NSString stringWithFormat:@"Override Order# %@\nStatus to Ready?", self.myOrder.wcsOrderId]
                           cancelButtonItem:[RIButtonItem itemWithLabel:@"Yes" action:^
                                            {
                                                [SVProgressHUD show];
                                                [self.myOrderManager overrideConfirmOrderAtStation:self.myOrder completion:^(NSString * error)
                                                {
                                                    if ( error )
                                                    {
                                                        [SVProgressHUD dismiss];
                                                        [[[UIAlertView alloc] initWithTitle:@"Override Order Status"
                                                                                    message:[NSString stringWithFormat:@"Issue changing status:\n%@", error]
                                                                           cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^
                                                                                            {
                                                                                                //
                                                                                            }]
                                                                           otherButtonItems:nil] show];
                                                    }
                                                    else
                                                    {
                                                        [SVProgressHUD showSuccessWithStatus:@"Order Updated\nSuccessfully"];
                                                        [self didFinishLoadingOrderDetails:self.myOrder];
                                                    }
                                                }];
                                            }]
                           otherButtonItems:[RIButtonItem itemWithLabel:@"Cancel" action:^
                                            {
                                                //
                                            }], nil] show];
    }
    else if ( [buttonText isEqualToString:@"At Station"] )
    {
        
    }
    else if ( [buttonText isEqualToString:@"Delivered"] )
    {
        [SVProgressHUD show];
        [self.myOrderManager confirmDeliveryForOrder:self.myOrder completion:^(BOOL success)
        {
            if ( success )
            {
                [SVProgressHUD showSuccessWithStatus:@"Order Updated\nSuccessfully"];
                [self didFinishLoadingOrderDetails:self.myOrder];
            }
            else
                [SVProgressHUD showErrorWithStatus:@"Issue Changing Status"];
        }];
    }
}

- (IBAction)backButtonAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)atStationAction:(id)sender
{
    UITableViewCell * cell;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
        cell = (UITableViewCell *)[[[sender superview] superview] superview];
    else
        cell = (UITableViewCell *)[[[[sender superview] superview] superview] superview];
    
    self.activeProduct = [self.productsForTableView objectAtIndex:[[self.OrderDetailTableView indexPathForCell:cell] row]];
    
    if ( [self.myOrderManager isLastProductToApprove:self.activeProduct] )
    {
        if ( self.myOrder.purchaseReceiptImage == nil )
        {
            [[[UIAlertView alloc] initWithTitle:@"No Receipt Image"
                                        message:[NSString stringWithFormat:@"Proceed without receipt?"]
                               cancelButtonItem:[RIButtonItem itemWithLabel:@"Take receipt picture" action:^
                                                {
                                                    [self performSegueWithIdentifier:@"toReceiptCamera" sender:self];
                                                }]
                               otherButtonItems:[RIButtonItem itemWithLabel:@"Proceed" action:^
                                                {
                                                    [self didFinishUploadingReceipt:nil];
                                                }], nil] show];
        }
        else
        {
            [SVProgressHUD showWithStatus:@"Uploading Receipt"];
            [self.myOrderManager uploadReceiptImage:self.myOrder.purchaseReceiptImage withType:@"purchase" forOrder:self.myOrder];
        }
    }
    else
    {
        [SVProgressHUD showWithStatus:@"Setting Status"];
        [self.myOrderManager confirmProductAtStation:self.activeProduct completion:^(BOOL success)
         {
             if ( success )
             {
                 [SVProgressHUD showSuccessWithStatus:@"Status Saved"];
                 [self didFinishLoadingOrderDetails:self.myOrder];
             }
             else
                 [SVProgressHUD showErrorWithStatus:@"Error Saving Status"];
         }];
    }
}

@end
