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
    self.updateOrdersTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(refreshOrders) userInfo:nil repeats:YES];
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:self.view.window];
    
    //printing
    self.myPrintManager = [PrintManager sharedPrintManager];
    
    //ui stuff
    [self setNeedsStatusBarAppearanceUpdate];
    self.swipedOrders = [[NSMutableArray alloc] init];
    
    self.myTopView = [[[NSBundle mainBundle] loadNibNamed:@"TopView" owner:self options:nil] firstObject];
    self.myTopView.delegate = self;
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
}

#pragma mark - top view delegate
- (void) searchBarTextDidChange:(NSString *)searchString
{
    [self refreshOrders];
}

- (void) didPressAlertButton
{
    [self.myBottomView openButtonAction:nil];
}

- (void) didChangeKeynoteSwitch
{
    [self refreshOrders];
    
    //the below /*code*/ works

    /*
    UIPrintInteractionController * printInteractionController = [UIPrintInteractionController sharedPrintController];
    printInteractionController.showsNumberOfCopies = NO;
    printInteractionController.showsPageRange = NO;
    printInteractionController.printingItem = [NSURL URLWithString:@"https://www.google.com/images/nav_logo195.png"];
    
    [printInteractionController presentFromRect:CGRectMake(100, 100, 300, 300) inView:self.view animated:YES completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error)
    {
        //
    }];
     */
    
    /*
    if ( ! self.myPrinter )
    {
        //getting the printer
        UIPrinterPickerController * myPrinterPicker = [UIPrinterPickerController printerPickerControllerWithInitiallySelectedPrinter:nil];
        myPrinterPicker.delegate = self;
        
        [myPrinterPicker presentFromRect:CGRectMake(100, 100, 300, 300) inView:self.view animated:YES completionHandler:^(UIPrinterPickerController *printerPickerController, BOOL userDidSelect, NSError *error)
        {
            if ( userDidSelect )
            {
                self.myPrinter = printerPickerController.selectedPrinter;
            }
        }];
    }
    else
    {
        UIPrintInteractionController * printInteractionController = [UIPrintInteractionController sharedPrintController];
        printInteractionController.printingItem = [NSURL URLWithString:@"https://www.google.com/images/nav_logo195.png"];
        
        [printInteractionController printToPrinter:self.myPrinter completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error)
        {
            //
        }];
    }
     */
}

- (void) didPressLogout
{
    [self.updateOrdersTimer invalidate];
    UIViewController * modalToDismissFrom = self;
    while ( ! [[[modalToDismissFrom presentingViewController] restorationIdentifier] isEqualToString:@"loginPage"] )
        modalToDismissFrom = [modalToDismissFrom presentingViewController];
    modalToDismissFrom = [modalToDismissFrom presentingViewController];
    [modalToDismissFrom dismissViewControllerAnimated:YES completion:nil];
}

- (void) didPressBackButton
{
    [self.updateOrdersTimer invalidate];
    
    HomeViewController * homeViewController = (HomeViewController *)self.presentingViewController;
    [homeViewController myTopView].orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
    self.myOrderManager.delegate = (HomeViewController *)self.presentingViewController;
    homeViewController.updateOrdersTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self.myOrderManager selector:@selector(loadAllOrders) userInfo:nil repeats:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - bottom view delegate
- (void) didPressOpen
{
    self.ordersForTableView = [[NSArray alloc] init];
    
    if ( [self.myTopView.searchBarTextField.text length] == 0 )
        [self.myOrderManager loadOpenOrders];
    else
        [self.myOrderManager loadOpenOrdersWithCompletion:^(NSArray *orders)
        {
            self.noOrdersLabel.text = @"No Open Orders"; // in case there are zero orders
            self.ordersForTableView = [self.myOrderManager searchOrders:orders withString:self.myTopView.searchBarTextField.text];
            [self.orderTableView reloadData];
        }];
    
    [self.orderTableView reloadData];
}

- (void) didPressReady
{
    self.ordersForTableView = [[NSArray alloc] init];
    
    if ( [self.myTopView.searchBarTextField.text length] == 0 )
        [self.myOrderManager loadReadyOrders];
    else
        [self.myOrderManager loadReadyOrdersWithCompletion:^(NSArray *orders)
        {
            self.noOrdersLabel.text = @"No Ready Orders"; // in case there are zero orders
            self.ordersForTableView = [self.myOrderManager searchOrders:orders withString:self.myTopView.searchBarTextField.text];
            [self.orderTableView reloadData];
        }];
    
    [self.orderTableView reloadData];
}

- (void) didPressDelivered
{
    self.ordersForTableView = [[NSArray alloc] init];
    
    if ( [self.myTopView.searchBarTextField.text length] == 0 )
        [self.myOrderManager loadDeliveredOrders];
    else
        [self.myOrderManager loadDeliveredOrdersWithCompletion:^(NSArray *orders)
        {
            self.noOrdersLabel.text = @"No Delivered Orders"; // in case there are zero orders
            self.ordersForTableView = [self.myOrderManager searchOrders:orders withString:self.myTopView.searchBarTextField.text];
            [self.orderTableView reloadData];
        }];
    
    [self.orderTableView reloadData];
}

- (void) didPressCancelledReturned
{
    self.ordersForTableView = [[NSArray alloc] init];
    
    if ( [self.myTopView.searchBarTextField.text length] == 0 )
        [self.myOrderManager loadCancelledReturnedOrders];
    else
        [self.myOrderManager loadCancelledReturnedOrdersWithCompletion:^(NSArray *orders)
        {
            self.noOrdersLabel.text = @"No Cancelled\nOr Returned Orders"; // in case there are zero orders
            self.ordersForTableView = [self.myOrderManager searchOrders:orders withString:self.myTopView.searchBarTextField.text];
            [self.orderTableView reloadData];
        }];
    
    [self.orderTableView reloadData];
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
    if ( self.ordersForTableView.count > 0 || self.myOrderManager.isLoadingOrders )
        self.noOrdersLabel.hidden = YES;
    else
        self.noOrdersLabel.hidden = NO;
    
    if ( self.myOrderManager.isLoadingOrders )
        return [self.ordersForTableView count]+1;
//    
//    if ( self.wasRefreshingOrdersBeforeOverride )
//    {
//        self.wasRefreshingOrdersBeforeOverride = NO;
//        return [self.ordersForTableView count]+1;
//    }
    
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
        
        Order * tmpOrder = (Order *)[self.ordersForTableView objectAtIndex:indexPath.section];
        
        //gesture recognizers
        for ( UIGestureRecognizer * gesture in [[cell contentView] gestureRecognizers] )
            [[cell contentView] removeGestureRecognizer:gesture];
        
        UILongPressGestureRecognizer * overrideReadyGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(overrideOrderReady:)];
        [cell.contentView addGestureRecognizer:overrideReadyGesture];
        
        UISwipeGestureRecognizer * swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
        swipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [cell.contentView addGestureRecognizer:swipeLeftGesture];
        
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
        cell.idLabel.text = [NSString stringWithFormat:@"%@", tmpOrder.orderId];
        cell.buyerNameLabel.text = [[NSString stringWithFormat:@"%@ %@", tmpOrder.buyerFirstName, tmpOrder.buyerLastName] capitalizedString];
        cell.buyerEmail.text = tmpOrder.buyerEmail;
        
        if ( [tmpOrder.buyerPhoneNumber intValue] == 0 )
            cell.buyerPhoneLabel.text = @"No Phone Provided";
        else
        {
            NSString * phoneString = [NSString stringWithFormat:@"%@", tmpOrder.buyerPhoneNumber];
            if ( [phoneString length] == 11 )
                cell.buyerPhoneLabel.text = [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringWithRange:NSMakeRange(1, 3)], [phoneString substringWithRange:NSMakeRange(4, 3)], [phoneString substringWithRange:NSMakeRange(7, 4)]];
            else if ( [phoneString length] == 10 )
                cell.buyerPhoneLabel.text = [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringWithRange:NSMakeRange(0, 3)], [phoneString substringWithRange:NSMakeRange(3, 3)], [phoneString substringWithRange:NSMakeRange(6, 4)]];
            else
                cell.buyerPhoneLabel.text = phoneString;
        }
        
        cell.runnerNameLabel.text = [NSString stringWithFormat:@"%@", tmpOrder.runnerId];
        cell.statusLabel.text = tmpOrder.runnerStatus;
        if ( tmpOrder.isKeynoteOrder )
            cell.keynoteOrderLabel.hidden = NO;
        else
            cell.keynoteOrderLabel.hidden = YES;
        
        if ( [tmpOrder.anchorStatus isEqualToString:@"Return Initiated"] )
        {
            cell.statusLabel.text = @"Return\nInitiated";
            cell.colorDot.backgroundColor = [UIColor colorWithRed:(float)82/255 green:(float)210/255 blue:(float)128/255 alpha:1];
        }
        else if ( [tmpOrder.status isEqualToString:@"Cancelled"] || [tmpOrder.status isEqualToString:@"Returned"] || [tmpOrder.status isEqualToString:@"Rejected"] )
        {
            cell.statusLabel.text = tmpOrder.status;
            cell.colorDot.backgroundColor = [UIColor lightGrayColor];
        }
        else if ( [tmpOrder.runnerStatus isEqualToString:@"Open"] )
            cell.colorDot.backgroundColor = [UIColor colorWithRed:(float)241/255 green:(float)68/255 blue:(float)51/255 alpha:1];
        else if ( [tmpOrder.runnerStatus isEqualToString:@"Running"] )
            cell.colorDot.backgroundColor = [UIColor colorWithRed:(float)254/255 green:(float)174/255 blue:(float)17/255 alpha:1];
        else if ( [tmpOrder.runnerStatus isEqualToString:@"Picked Up"] )
            cell.colorDot.backgroundColor = [UIColor colorWithRed:(float)254/255 green:(float)174/255 blue:(float)17/255 alpha:1];
        else if ( [tmpOrder.runnerStatus isEqualToString:@"At Station"] )
        {
            cell.statusLabel.text = @"Pending\nAt Station";
            cell.colorDot.backgroundColor = [UIColor colorWithRed:(float)82/255 green:(float)210/255 blue:(float)128/255 alpha:1];
            
            if ( [tmpOrder.anchorStatus isEqualToString:@"At Station"] )
            {
                cell.confirmDeliveryButton.hidden = NO;
                cell.statusLabel.text = @"At Station";
                cell.colorDot.backgroundColor = [UIColor colorWithRed:(float)239/255 green:(float)118/255 blue:(float)37/255 alpha:1];
            }
            else if ( [tmpOrder.anchorStatus isEqualToString:@"Delivered"] )
            {
                cell.statusLabel.text = @"Delivered";
                cell.colorDot.backgroundColor = [UIColor colorWithRed:(float)109/255 green:(float)202/255 blue:(float)72/255 alpha:1];
            }
        }
        
        if ( [self.swipedOrders containsObject:tmpOrder.orderId] )
            cell.setStatusButtons.frame = CGRectMake(550, cell.setStatusButtons.frame.origin.y, cell.setStatusButtons.frame.size.width, cell.setStatusButtons.frame.size.height);
        else
            cell.setStatusButtons.frame = CGRectMake(1000, cell.setStatusButtons.frame.origin.y, cell.setStatusButtons.frame.size.width, cell.setStatusButtons.frame.size.height);
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.orderTableView deselectRowAtIndexPath:[self.orderTableView indexPathForSelectedRow] animated:YES];
    if ( [(OrderTableCell *)[self.orderTableView cellForRowAtIndexPath:indexPath] loadingIndicator].hidden == YES ) //make sure its not a loading cell
    {
        Order * tmpOrder = [self.ordersForTableView objectAtIndex:indexPath.section];
        
        if ( [self.swipedOrders containsObject:tmpOrder.orderId] )
        {
            OrderTableCell * cell = (OrderTableCell *)[self.orderTableView cellForRowAtIndexPath:indexPath];
            [UIView animateWithDuration:.5 animations:^
            {
                cell.setStatusButtons.frame = CGRectMake(1000, cell.setStatusButtons.frame.origin.y, cell.setStatusButtons.frame.size.width, cell.setStatusButtons.frame.size.height);
            }];
            [self.swipedOrders removeObject:tmpOrder.orderId];
        }
        else
        {
            [self.updateOrdersTimer invalidate];
            OrderDetailViewController * modalOrderDetailViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderDetailPage"];
            modalOrderDetailViewController.didNavigateFromHomeScreen = NO;
            modalOrderDetailViewController.myOrder = tmpOrder;
            modalOrderDetailViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:modalOrderDetailViewController animated:YES completion:nil];
            modalOrderDetailViewController.myTopView.orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
        }
    }
}

- (void) tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( self.indexPathForOverrideOrder == indexPath )
    {
        self.orderForOverrideOrder = nil;
        self.indexPathForOverrideOrder = nil;
    }
}

- (void) handleSwipeLeft:(UISwipeGestureRecognizer *)gesture
{
    //returns are temporarily disabled
    /*
    if ( [self.myBottomView.selectedStatus isEqualToString:@"cancelledReturned"] )
    {
        OrderTableCell * cell = (OrderTableCell *)[[[gesture view] superview] superview];
        [UIView animateWithDuration:.5 animations:^
        {
            cell.setStatusButtons.frame = CGRectMake(550, cell.setStatusButtons.frame.origin.y, cell.setStatusButtons.frame.size.width, cell.setStatusButtons.frame.size.height);
        }];
        
        Order * tmpOrder = [self.ordersForTableView objectAtIndex:[[self.orderTableView indexPathForCell:cell] section]];
        [self.swipedOrders addObject:tmpOrder.orderId];
    }
     */
}

- (IBAction)returnPendingAction:(id)sender
{
    //Order * tmpOrder = [self.ordersForTableView objectAtIndex:[[self.orderTableView indexPathForCell:(OrderTableCell *)[[[[sender superview] superview] superview] superview]] section]];
    //[self.myOrderManager confirmProductReturnByCustomer: completion:<#^(BOOL success)callBack#>]
    
    [SVProgressHUD showImage:nil status:@"Coming Soon"];
}

- (IBAction)returnCompleteAction:(id)sender
{
    [SVProgressHUD showImage:nil status:@"Coming Soon"];
}

- (IBAction)returnRejected:(id)sender
{
    [SVProgressHUD showImage:nil status:@"Coming Soon"];
}

#pragma mark - didScrollToBottom/loadMoreOrders
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
                [self loadMoreOrders];
            }
        }
    }
    
    self.lastContentOffset = scrollView.contentOffset.x;
}

- (void) loadMoreOrders
{
    if ( [self.myBottomView.selectedStatus isEqualToString:@"open"] )
        [self.myOrderManager loadOpenOrders];
    else if ( [self.myBottomView.selectedStatus isEqualToString:@"ready"] )
        [self.myOrderManager loadReadyOrders];
    else
        [self.myOrderManager loadDeliveredOrders];
    
    [self.orderTableView reloadData];
}

#pragma mark - order manager delegate
- (void) didFinishLoadingOrders:(NSArray *)orders withStatusOpen:(BOOL)open ready:(BOOL)ready delivered:(BOOL)delivered cancelledReturned:(BOOL)cancelledReturned
{
    if ( self.myOrderManager.isUpdatingOrder )
        return;
    
    if ( [self.myBottomView.selectedStatus isEqualToString:@"open"] && open == YES && ready == NO && delivered == NO )
    {
        self.noOrdersLabel.text = @"No Open Orders"; // in case there are zero orders
        self.ordersForTableView = orders;
        self.myTopView.orderNumberLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[orders count]];
    }
    else if ( [self.myBottomView.selectedStatus isEqualToString:@"ready"] && open == NO && ready == YES && delivered == NO )
    {
        self.noOrdersLabel.text = @"No Ready Orders"; // in case there are zero orders
        self.ordersForTableView = orders;
    }
    else if ( [self.myBottomView.selectedStatus isEqualToString:@"delivered"] && open == NO && ready == NO && delivered == YES )
    {
        self.noOrdersLabel.text = @"No Delivered Orders"; // in case there are zero orders
        self.ordersForTableView = orders;
    }
    else if ( [self.myBottomView.selectedStatus isEqualToString:@"cancelledReturned"] && open == NO && ready == NO && delivered == NO && cancelledReturned == YES )
    {
        self.noOrdersLabel.text = @"No Cancelled\nOr Returned Orders"; // in case there are zero orders
        self.ordersForTableView = orders;
    }
    else
    {
        // this is in case something funky happened
        [self refreshOrders];
        return;
    }
    
    if ( [self.myTopView.searchBarTextField.text length] != 0 )
        self.ordersForTableView = [self.myOrderManager searchOrders:self.ordersForTableView withString:self.myTopView.searchBarTextField.text];
    
    [self.orderTableView reloadData];
}

- (IBAction)confirmOrderDelivery:(id)sender
{
    self.myOrderManager.isUpdatingOrder = YES;
    
    OrderTableCell * cell;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
         cell = (OrderTableCell *)[[sender superview] superview];
    else
        cell = (OrderTableCell *)[[[sender superview] superview] superview];
    
    Order * tmpOrder = [self.ordersForTableView objectAtIndex:[[self.orderTableView indexPathForCell:cell] section]];
    
    [SVProgressHUD showWithStatus:@"Setting Status"];
    [self.myOrderManager confirmDeliveryForOrder:tmpOrder completion:^(BOOL success)
    {
        if ( success )
        {
            [SVProgressHUD showSuccessWithStatus:@"Status Saved"];
            [self.orderTableView reloadData];
            NSMutableArray * tmpOrders = [self.ordersForTableView mutableCopy];
            [tmpOrders removeObject:tmpOrder];
            self.ordersForTableView = tmpOrders;
            
            @try
            {
                [self.orderTableView deleteSections:[NSIndexSet indexSetWithIndex:[[self.orderTableView indexPathForCell:cell] section]] withRowAnimation:UITableViewRowAnimationRight];
            }
            @catch (NSException *exception)
            {
                NSLog(@"exception : %@", exception);
            }
        }
        else
        {
            [SVProgressHUD showErrorWithStatus:@"Issue Changing Status"];
        }
        
        self.myOrderManager.isUpdatingOrder = NO;
    }];
}

- (void) overrideOrderReady:(UILongPressGestureRecognizer *)gesture
{
    if ( gesture.state == UIGestureRecognizerStateBegan && [self.myBottomView.selectedStatus isEqualToString:@"open"] )
    {
        self.myOrderManager.isUpdatingOrder = YES;
        if ([[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending) //iOS 8 and greater
            self.indexPathForOverrideOrder = [self.orderTableView indexPathForCell:(UITableViewCell *)[[gesture view] superview]];
        else
            self.indexPathForOverrideOrder = [self.orderTableView indexPathForCell:(UITableViewCell *)[[[gesture view] superview] superview]];
        
        self.orderForOverrideOrder = [self.ordersForTableView objectAtIndex:[self.indexPathForOverrideOrder section]];
        
        [[[UIAlertView alloc] initWithTitle:@"Override Status"
                                    message:[NSString stringWithFormat:@"Override Order# %@\nStatus to Ready?", self.orderForOverrideOrder.orderId]
                           cancelButtonItem:[RIButtonItem itemWithLabel:@"Yes" action:^
        {
            [SVProgressHUD show];
            [self.myOrderManager overrideConfirmOrderAtStation:self.orderForOverrideOrder completion:^(NSString * error)
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
                    [self.orderTableView reloadData];
                    NSMutableArray * tmpOrders = [[NSMutableArray alloc] initWithArray:self.ordersForTableView];
                    [tmpOrders removeObject:self.orderForOverrideOrder];
                    self.ordersForTableView = tmpOrders;
                    
                    @try
                    {
                        [self.orderTableView deleteSections:[NSIndexSet indexSetWithIndex:[self.indexPathForOverrideOrder section]] withRowAnimation:UITableViewRowAnimationRight];
                    }
                    @catch (NSException *exception) {
                        NSLog(@"%@", exception);
                    }
                    
                    [SVProgressHUD showSuccessWithStatus:@"Status Changed"];
                }
                
                self.myOrderManager.isUpdatingOrder = NO;
            }];
        }]
        otherButtonItems:[RIButtonItem itemWithLabel:@"Cancel" action:^
        {
            self.myOrderManager.isUpdatingOrder = NO;
        }], nil] show];
    }
}

- (void) didFinishPrintingReceiptForOrder:(Order *)order
{
    NSLog(@"receipt printed for order id : %@", order.orderId);
}

- (void) didFailPrintingReceiptForOrder:(Order *)order
{
    NSLog(@"failed printing receipt for order id : %@", order.orderId);
}

#pragma mark - misc.
- (void) refreshOrders
{
    if ( self.myOrderManager.isUpdatingOrder )
        return;
    
    if ( [[self.myBottomView selectedStatus] isEqualToString:@"open"] )
        [self.myOrderManager loadOpenOrders];
    else if ( [[self.myBottomView selectedStatus] isEqualToString:@"ready"] )
        [self.myOrderManager loadReadyOrders];
    else if ( [[self.myBottomView selectedStatus] isEqualToString:@"delivered"] )
        [self.myOrderManager loadDeliveredOrders];
    else if ( [[self.myBottomView selectedStatus] isEqualToString:@"cancelledReturned"] )
        [self.myOrderManager loadCancelledReturnedOrders];
    
    [self.orderTableView reloadData];
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

- (IBAction)manualPrintAction:(id)sender
{
    OrderTableCell * cell;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
        cell = (OrderTableCell *)[[sender superview] superview];
    else
        cell = (OrderTableCell *)[[[sender superview] superview] superview];
    
    Order * tmpOrder = [self.ordersForTableView objectAtIndex:[[self.orderTableView indexPathForCell:cell] section]];
    
    //basically a preview print
    /*[self.myPrintManager webViewForReceiptOrder:tmpOrder completion:^(UIWebView *webView)
    {
        [self.view addSubview:webView];
    }];*/
    
    
    //iOS 8 introduced printToPrinter method, bypassing additional dialog box
    [SVProgressHUD showWithStatus:@"Printing"];
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
    {
        [self.myPrintManager printReceiptForOrder:tmpOrder fromView:nil completion:^(BOOL success)
        {
            [SVProgressHUD showSuccessWithStatus:@"Printed Successfully"];
        }];
    }
    else
    {
        [self.myPrintManager printReceiptForOrder:tmpOrder fromView:(UIButton *)sender completion:^(BOOL success)
        {
            [SVProgressHUD showSuccessWithStatus:@"Printed Successfully"];
        }];
    }
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
