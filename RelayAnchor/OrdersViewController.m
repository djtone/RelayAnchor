//
//  OrdersViewController.m
//  RelayAnchor
//
//  Created by chuck on 8/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "OrdersViewController.h"
#import "OrderTableCell.h"
#import "CreateAPIStrings.h"
#import "OrderDetailViewController.h"
#import "SVProgressHUD.h"
#import "UIAlertView+Blocks.h"
#import "HomeViewController.h"
#import "AccountManager.h"

@implementation OrdersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.myOrderManager = [OrderManager sharedInstanceWithDelegate:self];
    self.myDateFormatter = [[NSDateFormatter alloc] init];
    self.myDate = [NSDate date];
    self.statusesFirstLoad = YES;
    self.searchesFirstLoad = NO;
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:self.view.window];
    
    //ui stuff
    [self setNeedsStatusBarAppearanceUpdate];
    self.swipedOrderIds = [[NSMutableArray alloc] init];
    
    self.myTopView = [[[NSBundle mainBundle] loadNibNamed:@"TopView" owner:self options:nil] firstObject];
    self.myTopView.delegate = self;
    self.myTopView.printerButton.hidden = YES;
    if ( self.myOrderManager.showKeynoteOrders )
        [self.myTopView.keynoteOrdersSwitch setOn:YES];
    else
        [self.myTopView.keynoteOrdersSwitch setOn:NO];
    [self.view addSubview:self.myTopView];
    
    self.myBottomView = [[[NSBundle mainBundle] loadNibNamed:@"BottomView" owner:self options:nil] firstObject];
    self.myBottomView.delegate = self;
    [self.view addSubview:self.myBottomView];
    
    //set sort button title & arrow image
    NSArray * sortPreferences = [[AccountManager sharedInstance] orderSortPreferences];
    NSArray * sortPreference = [sortPreferences firstObject];
    NSString * sortPreferenceString = [sortPreference firstObject];
    
    if ( [sortPreferenceString isEqualToString:@"Order Date"] )
        self.lastSortedButton = self.orderDateButton;
    else if ( [sortPreferenceString isEqualToString:@"Order ID"] )
        self.lastSortedButton = self.orderIDButton;
    else if ( [sortPreferenceString isEqualToString:@"Buyer Name"] )
        self.lastSortedButton = self.buyerNameButton;
    else if ( [sortPreferenceString isEqualToString:@"Buyer Email"] )
        self.lastSortedButton = self.buyerEmailButton;
    else if ( [sortPreferenceString isEqualToString:@"Buyer Phone"] )
        self.lastSortedButton = self.buyerPhoneButton;
    else if ( [sortPreferenceString isEqualToString:@"Runner"] )
        self.lastSortedButton = self.runnerButton;
    else if ( [sortPreferenceString isEqualToString:@"Status"] )
        self.lastSortedButton = self.statusButton;
    
    [self.lastSortedButton setTitle:[NSString stringWithFormat:@" %@", sortPreferenceString] forState:UIControlStateNormal];
    if ( (BOOL)[sortPreference lastObject] )
        [self.lastSortedButton setImage:[UIImage imageNamed:@"sortTriangleUp"] forState:UIControlStateNormal];
    else
        [self.lastSortedButton setImage:[UIImage imageNamed:@"sortTriangleDown"] forState:UIControlStateNormal];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.orderTableView reloadData];
    [self.myTopView.mallNameButton setTitle:[[[AccountManager sharedInstance] selectedMall] name] forState:UIControlStateNormal];
}

#pragma mark - top view delegate
- (void) searchBarTextDidChange:(NSString *)searchString
{
    if ( ! [self.searchedText isEqualToString:searchString] )
    {//this is required becuase the clear button calls textFieldDidChange twice (im guessing its an iOS bug)
        self.searchedText = searchString;
        
        self.noOrdersLabel.hidden = YES;
        self.searchesFirstLoad = YES;
        [self.myTopView.searchBarTextField setClearButtonMode:UITextFieldViewModeNever];
        
        if ( ! [self refreshOrders ] )
            [self.orderTableView reloadData];
    }
}

- (void) didPressAlertButton
{
    [self.myBottomView openButtonAction:nil];
}

- (void) didPressLogout
{
    //[self] specific stuff
    [self.myOrderManager stopAutoRefreshOrders:nil];
    
    //handling the UI
    UIViewController * homePage = self;
    while ( ! [[[homePage presentingViewController] restorationIdentifier] isEqualToString:@"loginPage"] )
        homePage = [homePage presentingViewController];
    UIViewController * loginPage = [homePage presentingViewController];
    
    UIGraphicsBeginImageContext(self.view.window.bounds.size);
    [self.view.window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView * imageOverlay = [[UIImageView alloc] initWithImage:overlayImage];
    
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] == NSOrderedAscending ) //iOS 7 and lesser
    {
        if ( [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight || self.interfaceOrientation == 4 )
            imageOverlay.transform = CGAffineTransformMakeRotation(M_PI_2);
        else
            imageOverlay.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }
    
    imageOverlay.frame = CGRectMake(0, 0, 1024, 768);
    [homePage.view addSubview:imageOverlay];
    [loginPage dismissViewControllerAnimated:YES completion:^
    {
        [loginPage dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void) didPressBackButton
{
    [self.myOrderManager stopAutoRefreshOrders:nil];
    
    HomeViewController * homeViewController = (HomeViewController *)self.presentingViewController;
    [homeViewController myTopView].orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
    self.myOrderManager.delegate = (HomeViewController *)self.presentingViewController;
    [homeViewController.myOrderManager stopAutoRefreshOrders:^
    {
        [homeViewController.myOrderManager startAutoRefreshOrdersWithStatus:kLoadOrderStatusAll timeInterval:10];
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) didChangeMall
{
    self.statusesFirstLoad = YES;
    self.ordersForTableView = @[];
    
    if ( ! [self refreshOrders] )
        [self.orderTableView reloadData];
}

- (void) didChangeKeynoteBoolean
{
    self.statusesFirstLoad = YES;
    self.ordersForTableView = @[];
    
    if ( ! [self refreshOrders] )
        [self.orderTableView reloadData];
}

#pragma mark - bottom view delegate
- (void) didChangeStatus:(BottomViewStatus)selectedStatus
{
    self.statusesFirstLoad = YES;
    self.ordersForTableView = @[];
    [self.myOrderManager stopAutoRefreshOrders:^
    {
        [self.myOrderManager startAutoRefreshOrdersWithStatus:[EnumTypes LoadOrderStatusFromBottomViewStatus:selectedStatus] timeInterval:10];
    }];
    
    switch (selectedStatus)
    {
        case kBottomViewStatusOpen:
            self.noOrdersLabel.text = @"No Open Orders";
            break;
            
        case kBottomViewStatusReady:
            self.noOrdersLabel.text = @"No Ready Orders";
            break;
            
        case kBottomViewStatusDelivered:
            self.noOrdersLabel.text = @"No Delivered Orders";
            break;
            
        case kBottomViewStatusCancelledReturned:
            self.noOrdersLabel.text = @"No Cancelled\nOr Returned Orders";
            break;
            
        default:
            self.noOrdersLabel.text = @"No Orders";
            NSLog(@"invalid selectedStatus");
    }
    
    self.noOrdersLabel.hidden = YES;
}

#pragma mark - tableview delegate/datasource
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 8;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if ( self.ordersForTableView.count > 0 || self.statusesFirstLoad || self.searchesFirstLoad )
        self.noOrdersLabel.hidden = YES;
    else
        self.noOrdersLabel.hidden = NO;
    
    self.statusesFirstLoad = NO;
    self.searchesFirstLoad = NO;
    
    if ( self.myOrderManager.isLoadingOrders )
        return [self.ordersForTableView count]+1;
    
    return [self.ordersForTableView count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if ( section == [self.ordersForTableView count] )
        return nil;
    else
    {
        UITableViewHeaderFooterView * footerView = [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectMake(0, 5, self.orderTableView.frame.size.width, 5)];
        
        footerView.layer.masksToBounds = YES;
        UIView * inside = [[UIView alloc] initWithFrame:CGRectMake(0, -6, self.orderTableView.frame.size.width-8, 5)];
    
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:inside.bounds];
        inside.layer.masksToBounds = NO;
        inside.layer.shadowColor = [UIColor blackColor].CGColor;
        inside.layer.shadowOffset = CGSizeMake(5, 0);
        inside.layer.shadowOpacity = .5;
        inside.layer.shadowPath = shadowPath.CGPath;
        
        [footerView addSubview:inside];
        
        return footerView;
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OrderTableCell * cell = [tableView dequeueReusableCellWithIdentifier:@"orderTableCell"];
    
    if ( indexPath.section == [self.ordersForTableView count] )
    {
        cell.backgroundColor = [UIColor clearColor];
        for ( UIView * view in [[cell contentView] subviews] )
            view.hidden = YES;
        cell.loadingIndicator.hidden = NO;
        [cell.loadingIndicator startAnimating];
    }
    else
    {
        cell.backgroundColor = [UIColor whiteColor];
        for ( UIView * view in [[cell contentView] subviews] )
            view.hidden = NO;
        cell.confirmDeliveryButton.hidden = YES;
        cell.loadingIndicator.hidden = YES;
        
        Order * tmpOrder;
        if ( [self.ordersForTableView count] > 0 )
            tmpOrder = (Order *)[self.ordersForTableView objectAtIndex:indexPath.section];
        else
        {
            cell.dateLabel.text = @"Error Loading Data";
            return cell;
        }
        
        //if the order is from today, display the time, otherwise display the date
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
        NSDate *today = [cal dateFromComponents:components];
        components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:tmpOrder.placeTime];
        if ( [[cal dateFromComponents:components] isEqualToDate:today] )
            [self.myDateFormatter setDateFormat:@"h:mm a"];
        else
            [self.myDateFormatter setDateFormat:@"M/d/yy"];
        
        cell.dateLabel.text = [self.myDateFormatter stringFromDate:tmpOrder.placeTime];
        cell.idLabel.text = [NSString stringWithFormat:@"%@", tmpOrder.wcsOrderId];
        cell.buyerNameLabel.text = [[NSString stringWithFormat:@"%@ %@", tmpOrder.buyerFirstName, tmpOrder.buyerLastName] capitalizedString];
        cell.buyerEmail.text = tmpOrder.buyerEmail;
        
        NSString * phoneString;
        if ( [tmpOrder.buyerPhoneNumber intValue] == 0 && [tmpOrder.deliveryPhoneNumber intValue] == 0 )
            cell.buyerPhoneLabel.text = @"No Phone Provided";
        else
        {
            if ( [tmpOrder.deliveryPhoneNumber intValue] != 0 && tmpOrder.hasDeliveryItems )
                phoneString = [NSString stringWithFormat:@"%@", tmpOrder.deliveryPhoneNumber];
            else
                phoneString = [NSString stringWithFormat:@"%@", tmpOrder.buyerPhoneNumber];
            
            if ( [phoneString length] == 11 )
                cell.buyerPhoneLabel.text = [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringWithRange:NSMakeRange(1, 3)], [phoneString substringWithRange:NSMakeRange(4, 3)], [phoneString substringWithRange:NSMakeRange(7, 4)]];
            else if ( [phoneString length] == 10 )
                cell.buyerPhoneLabel.text = [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringWithRange:NSMakeRange(0, 3)], [phoneString substringWithRange:NSMakeRange(3, 3)], [phoneString substringWithRange:NSMakeRange(6, 4)]];
            else
                cell.buyerPhoneLabel.text = phoneString;
        }
        
        cell.runnerNameLabel.text = [NSString stringWithFormat:@"%@", tmpOrder.runnerName];
        cell.statusLabel.text = [tmpOrder stringFromRunnerStatus];
        
        if ( tmpOrder.isKeynoteOrder )
            cell.keynoteOrderLabel.hidden = NO;
        else
            cell.keynoteOrderLabel.hidden = YES;
        
        cell.hasDeliveryItemsLabel.hidden = NO;
        if ( tmpOrder.hasDeliveryItems )
        {
            cell.hasDeliveryItemsLabel.text = @"Delivery";
            if ( [tmpOrder.deliverySlot length] > 0 )
                cell.hasDeliveryItemsLabel.text =  [@"Delivery : "  stringByAppendingString:tmpOrder.deliverySlot];
        }
        else
        {
            cell.hasDeliveryItemsLabel.text = @"Store Pickup";
            if ( [tmpOrder.pickupLocation length] > 0 )
                cell.hasDeliveryItemsLabel.text = [@"Store Pickup : " stringByAppendingString:tmpOrder.pickupLocation];
        }

        cell.statusLabel.text = tmpOrder.displayStatus;
        cell.colorDot.backgroundColor = tmpOrder.displayColor;
        
        if ( tmpOrder.runnerStatus == kRunnerStatusAtStation && tmpOrder.anchorStatus == kAnchorStatusAtStation )
            cell.confirmDeliveryButton.hidden = NO;
        
        
        //swipe/longPress menu
        for ( UIGestureRecognizer * gesture in [[cell contentView] gestureRecognizers] )
            [[cell contentView] removeGestureRecognizer:gesture];
        
        UILongPressGestureRecognizer * longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        [cell.contentView addGestureRecognizer:longPressGesture];
        
        UISwipeGestureRecognizer * swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
        swipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [cell.contentView addGestureRecognizer:swipeLeftGesture];
        
        UISwipeGestureRecognizer * swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
        swipeRightGesture.direction = UISwipeGestureRecognizerDirectionRight;
        [cell.contentView addGestureRecognizer:swipeRightGesture];
        
        //if the order is open, show override
        if ( self.myBottomView.selectedStatus == kBottomViewStatusOpen )
            cell.overrideReadyStatusButton.hidden = NO;
        else
            cell.overrideReadyStatusButton.hidden = YES;
            //the return buttons will show otherwise
        
        if ( [self.swipedOrderIds containsObject:tmpOrder.wcsOrderId] )
            cell.swipeLeftMenu.frame = CGRectMake(cell.contentView.frame.size.width - cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.origin.y, cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.size.height);
        else
            cell.swipeLeftMenu.frame = CGRectMake(cell.contentView.frame.size.width, cell.swipeLeftMenu.frame.origin.y, cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.size.height);
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.orderTableView deselectRowAtIndexPath:[self.orderTableView indexPathForSelectedRow] animated:YES];
    if ( [(OrderTableCell *)[self.orderTableView cellForRowAtIndexPath:indexPath] loadingIndicator].hidden == YES ) //make sure its not a loading cell
    {
        Order * tmpOrder = [self.ordersForTableView objectAtIndex:indexPath.section];
        
        if ( [self.swipedOrderIds containsObject:tmpOrder.wcsOrderId] )
        {
            OrderTableCell * cell = (OrderTableCell *)[self.orderTableView cellForRowAtIndexPath:indexPath];
            [UIView animateWithDuration:.5 animations:^
            {
                cell.swipeLeftMenu.frame = CGRectMake(1000, cell.swipeLeftMenu.frame.origin.y, cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.size.height);
            }];
            [self.swipedOrderIds removeObject:tmpOrder.wcsOrderId];
        }
        else
        {
            [self.myOrderManager stopAutoRefreshOrders:nil];
            OrderDetailViewController * modalOrderDetailViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderDetailPage"];
            modalOrderDetailViewController.didNavigateFromHomeScreen = NO;
            modalOrderDetailViewController.myOrder = tmpOrder;
            modalOrderDetailViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:modalOrderDetailViewController animated:YES completion:nil];
            modalOrderDetailViewController.myTopView.orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
        }
    }
}

- (void) handleLongPressGesture:(UILongPressGestureRecognizer *)gesture
{
    if ( gesture.state == UIGestureRecognizerStateBegan )
    {
        OrderTableCell * cell;
        if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
            cell = (OrderTableCell *)[[gesture view] superview];
        else
            cell = (OrderTableCell *)[[[gesture view] superview] superview];
        
        [self toggleSwipeMenuForCell:cell];
    }
}

- (void) handleSwipeGesture:(UISwipeGestureRecognizer *)gesture
{
    [self.orderTableView deselectRowAtIndexPath:[self.orderTableView indexPathForSelectedRow] animated:YES];
    OrderTableCell * cell;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
        cell = (OrderTableCell *)[[gesture view] superview];
    else
        cell = (OrderTableCell *)[[[gesture view] superview] superview];
    
    [self toggleSwipeMenuForCell:cell];
}

- (void) toggleSwipeMenuForCell:(OrderTableCell *)cell
{
    Order * tmpOrder = [self.ordersForTableView objectAtIndex:[[self.orderTableView indexPathForCell:cell] section]];
    
    if ( [self.swipedOrderIds containsObject:tmpOrder.wcsOrderId] )
    {
        [UIView animateWithDuration:.5 animations:^
        {
            cell.swipeLeftMenu.frame = CGRectMake(cell.contentView.frame.size.width, cell.swipeLeftMenu.frame.origin.y, cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.size.height);
        }];
        [self.swipedOrderIds removeObject:tmpOrder.wcsOrderId];
    }
    else
    {
        [UIView animateWithDuration:.5 animations:^
        {
            cell.swipeLeftMenu.frame = CGRectMake(cell.contentView.frame.size.width - cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.origin.y, cell.swipeLeftMenu.frame.size.width, cell.swipeLeftMenu.frame.size.height);
        }];
        [self.swipedOrderIds addObject:tmpOrder.wcsOrderId];
    }
}

- (IBAction)overrideReadyStatusAction:(id)sender
{
    NSIndexPath * indexPathOfOrder;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending) //iOS 8 and greater
        indexPathOfOrder = [self.orderTableView indexPathForCell:(OrderTableCell *)[[[sender superview] superview] superview]];
    else
        indexPathOfOrder = [self.orderTableView indexPathForCell:(OrderTableCell *)[[[[sender superview] superview] superview] superview]];
    
    __block Order * overrideOrder = [self.ordersForTableView objectAtIndex:[indexPathOfOrder section]];
    
    [[[UIAlertView alloc] initWithTitle:@"Override Status"
                                message:[NSString stringWithFormat:@"Override Order# %@\nStatus to Ready?", overrideOrder.wcsOrderId]
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"Yes" action:^
                                        {
                                            [SVProgressHUD show];
                                            [self.myOrderManager overrideConfirmOrderAtStation:overrideOrder completion:^(NSString * error)
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
                                                    for ( Order * tmpOrder in self.ordersForTableView )
                                                    {
                                                        if ( [tmpOrder.wcsOrderId isEqual:overrideOrder.wcsOrderId] )
                                                        {
                                                            overrideOrder = tmpOrder;
                                                            break;
                                                        }
                                                    }
                                                    
                                                    if ( [self.ordersForTableView containsObject:overrideOrder] )
                                                    {
                                                        NSIndexPath * overrideIndex = [NSIndexPath indexPathForItem:0 inSection:[self.ordersForTableView indexOfObject:overrideOrder]];
                                                        NSMutableArray * tmpOrders = [self.ordersForTableView mutableCopy];
                                                        [tmpOrders removeObject:overrideOrder];
                                                        self.ordersForTableView = tmpOrders;
                                                        [self.orderTableView deleteSections:[NSIndexSet indexSetWithIndex:[overrideIndex section]] withRowAnimation:UITableViewRowAnimationRight];
                                                        
                                                        for ( NSNumber * tmpOrderId in self.swipedOrderIds )
                                                        {
                                                            if ( [tmpOrderId isEqual:overrideOrder.wcsOrderId] )
                                                            {
                                                                [self.swipedOrderIds removeObject:tmpOrderId];
                                                                break;
                                                            }
                                                        }
                                                        [SVProgressHUD showSuccessWithStatus:@"Status Changed"];
                                                    }
                                                    else
                                                        [SVProgressHUD showErrorWithStatus:@"Issue Locating Order"];
                                                }
                                            }];
                                        }]
                       otherButtonItems:[RIButtonItem itemWithLabel:@"Cancel" action:^
                                        {
                                            //
                                        }], nil] show];
}

- (IBAction)returnCompleteAction:(id)sender
{
    [SVProgressHUD showImage:nil status:@"Coming Soon"];
}

- (IBAction)returnRejectedAction:(id)sender
{
    [SVProgressHUD showImage:nil status:@"Coming Soon"];
}

#pragma mark - didScrollToBottom/forceRefreshOrders
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ( self.lastContentOffset < scrollView.contentOffset.y ) //scrolling down
    {
        float maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        if (maximumOffset - scrollView.contentOffset.y < 300.0 && ! self.myOrderManager.isLoadingOrders)
        {
            if ( [self.myDate timeIntervalSinceNow] + 3 < [[NSDate date] timeIntervalSinceNow] )
            {
                self.myDate = [NSDate date];
                [self forceRefreshOrders];
            }
        }
    }
    
    self.lastContentOffset = scrollView.contentOffset.x;
}

- (void) forceRefreshOrders
{
    [self.myOrderManager loadOrdersWithStatus:[EnumTypes LoadOrderStatusFromBottomViewStatus:self.myBottomView.selectedStatus] completion:nil];
    [self.orderTableView reloadData];
}

#pragma mark - order manager delegate
- (void) didStartLoadingOrdersWithStatus:(LoadOrderStatus)loadOrderStatus
{
    if ( self.myOrderManager.isUpdatingOrder ) //not sure if i this is necessary
        return;
    
    [self.orderTableView reloadData];
}

- (void) didFinishLoadingOrders:(NSArray *)orders status:(LoadOrderStatus)loadOrderStatus error:(NSString *)error
{
    //i need to check for an error
    
    self.ordersForTableView = orders;
    self.myTopView.searchActivityIndicator.hidden = YES;
    self.myTopView.keynoteActivityIndicator.hidden = YES;
    [self.myTopView.searchActivityIndicator stopAnimating];
    [self.myTopView.keynoteActivityIndicator stopAnimating];
    [self.myTopView.searchBarTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    
    switch (loadOrderStatus)
    {
        case kLoadOrderStatusOpen:
            self.noOrdersLabel.text = @"No Open Orders";
            self.myTopView.orderNumberLabel.text = [NSString stringWithFormat:@"%i", (int)[orders count]];
            break;
            
        case kLoadOrderStatusReady:
            self.noOrdersLabel.text = @"No Ready Orders";
            break;
            
        case kLoadOrderStatusDelivered:
            self.noOrdersLabel.text = @"No Delivered Orders";
            break;
            
        case kLoadOrderStatusCancelledReturned:
            self.noOrdersLabel.text = @"No Cancelled\nOr Returned Orders";
            break;
            
        default:
            self.ordersForTableView = @[];
            NSLog(@"invalide loadOrderStatus returned from loadOrdersWithStatus");
    }
    
    if ( [self.myTopView.searchBarTextField.text length] != 0 )
    {
        self.ordersForTableView = [self.myOrderManager searchOrders:self.ordersForTableView withString:self.myTopView.searchBarTextField.text];
        self.noOrdersLabel.text = [NSString stringWithFormat:@"%@ Matching\n\"%@\"", self.noOrdersLabel.text, self.myTopView.searchBarTextField.text];
    }
    
    [self.orderTableView reloadData];
}

- (IBAction)confirmOrderDelivery:(id)sender
{
    OrderTableCell * cell;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
        cell = (OrderTableCell *)[[sender superview] superview];
    else
        cell = (OrderTableCell *)[[[sender superview] superview] superview];
    
    __block Order * confirmDeliveryOrder = [self.ordersForTableView objectAtIndex:[[self.orderTableView indexPathForCell:cell] section]];
    
    [SVProgressHUD showWithStatus:@"Setting Status"];
    [self.myOrderManager confirmDeliveryForOrder:confirmDeliveryOrder completion:^(BOOL success)
    {
        if ( success )
        {
            for ( Order * tmpOrder in self.ordersForTableView )
            {
                if ( [tmpOrder.wcsOrderId isEqual:confirmDeliveryOrder.wcsOrderId] )
                {
                    confirmDeliveryOrder = tmpOrder;
                    break;
                }
            }
            
            if ( [self.ordersForTableView containsObject:confirmDeliveryOrder] )
            {
                NSIndexPath * confirmDeliveryIndex = [NSIndexPath indexPathForItem:0 inSection:[self.ordersForTableView indexOfObject:confirmDeliveryOrder]];
                NSMutableArray * tmpOrders = [self.ordersForTableView mutableCopy];
                [tmpOrders removeObjectAtIndex:confirmDeliveryIndex.section];
                self.ordersForTableView = tmpOrders;
                [self.orderTableView deleteSections:[NSIndexSet indexSetWithIndex:[confirmDeliveryIndex section]] withRowAnimation:UITableViewRowAnimationRight];
                [SVProgressHUD showSuccessWithStatus:@"Status Saved"];
            }
            else
                [SVProgressHUD showErrorWithStatus:@"Issue Locating Order"];
        }
        else
            [SVProgressHUD showErrorWithStatus:@"Issue Changing Status"];
    }];
}

- (void) didFinishPrintingReceiptForOrder:(Order *)order
{
    NSLog(@"receipt printed for order id : %@", order.wcsOrderId);
}

- (void) didFailPrintingReceiptForOrder:(Order *)order
{
    NSLog(@"failed printing receipt for order id : %@", order.wcsOrderId);
}

#pragma mark - misc.
- (BOOL) refreshOrders
{
    if ( self.myOrderManager.isUpdatingOrder || self.myOrderManager.isLoadingOrders )
        return NO;
    
    [self.myOrderManager stopAutoRefreshOrders:^
    {
        [self.myOrderManager startAutoRefreshOrdersWithStatus:[EnumTypes LoadOrderStatusFromBottomViewStatus:self.myBottomView.selectedStatus] timeInterval:10];
    }];
    
    return YES;
}

- (void) keyboardWillShow
{
    [UIView animateWithDuration:.2 animations:^
    {
        self.orderTableView.frame = CGRectMake(12, 64, 1000, 275);
    }];
}

- (void) keyboardWillHide
{
    [UIView animateWithDuration:.5 animations:^
    {
        self.orderTableView.frame = CGRectMake(12, 64, 1000, 555);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)sortOrders:(id)sender
{
    NSMutableArray * sortPreferences = [[AccountManager sharedInstance] orderSortPreferences];
    NSString * sortPreferenceString = [[[(UIButton *)sender titleLabel] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSArray * sortPreference;
    for ( int i = 0; i < [sortPreferences count]; i++ )
    {
        if ( [[[sortPreferences objectAtIndex:i] firstObject] isEqualToString:sortPreferenceString] )
        {
            sortPreference = [sortPreferences objectAtIndex:i];
            [sortPreferences removeObject:sortPreference];
            if ( i == 0 )
            {
                //if the category is already selected, switch from ascending to descending or vice versa
                if ( [[sortPreference lastObject] boolValue] )
                    sortPreference = @[[sortPreference firstObject], @NO];
                else
                    sortPreference = @[[sortPreference firstObject], @YES];
            }
            
            [sortPreferences insertObject:sortPreference atIndex:0];
            
            break;
        }
    }
    
    [[AccountManager sharedInstance] setOrderSortPreferences:sortPreferences];
    [[NSUserDefaults standardUserDefaults] setValue:sortPreferences forKey:@"orderSortPreferences"];
    self.ordersForTableView = [OrderManager sortOrders:[self.ordersForTableView mutableCopy]];
    [self.orderTableView reloadData];
    
    //change old sort button's title & remove arrow image
    [self.lastSortedButton setTitle:[[[self.lastSortedButton titleLabel] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] forState:UIControlStateNormal];
    [self.lastSortedButton setImage:nil forState:UIControlStateNormal];
    
    //update new sort button's title & add arrow image
    [(UIButton *)sender setTitle:[NSString stringWithFormat:@" %@", sortPreferenceString] forState:UIControlStateNormal];
    if ( [[sortPreference lastObject] boolValue] )
        [(UIButton *)sender setImage:[UIImage imageNamed:@"sortTriangleUp"] forState:UIControlStateNormal];
    else
        [(UIButton *)sender setImage:[UIImage imageNamed:@"sortTriangleDown"] forState:UIControlStateNormal];
    
    self.lastSortedButton = (UIButton *)sender;
}


@end
