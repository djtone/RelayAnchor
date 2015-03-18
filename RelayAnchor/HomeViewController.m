//
//  HomeViewController.m
//  RelayAnchor
//
//  Created by chuck on 8/8/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "HomeViewController.h"
#import "OrderTableCell.h"
#import "OrdersViewController.h"
#import "OrderDetailViewController.h"

@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.myOrderManager = [OrderManager sharedInstanceWithDelegate:self];
    [self.myOrderManager loadAllOrders];
    self.myDate = [NSDate date];
    self.myDateFormatter = [[NSDateFormatter alloc] init];
    self.updateOrdersTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self.myOrderManager selector:@selector(loadAllOrders) userInfo:nil repeats:YES];
    
    //ui stuff
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.myTopView = [[[NSBundle mainBundle] loadNibNamed:@"TopView" owner:self options:nil] firstObject];
    self.myTopView.delegate = self;
    self.myTopView.searchView.hidden = YES;
    self.myTopView.searchSeparator.hidden = YES;
    self.myTopView.hideBackButton = YES;
    self.myTopView.printerButton.hidden = YES;
    [self.view addSubview:self.myTopView];
    
    self.myBottomView = [[[NSBundle mainBundle] loadNibNamed:@"BottomView" owner:self options:nil] firstObject];
    self.myBottomView.delegate = self;
    [self.view addSubview:self.myBottomView];
}

#pragma mark - top view delegate
- (void) didPressLogout
{
    [self.updateOrdersTimer invalidate];
    UIViewController * modalToDismissFrom = self;
    while ( ! [[[modalToDismissFrom presentingViewController] restorationIdentifier] isEqualToString:@"loginPage"] )
        modalToDismissFrom = [modalToDismissFrom presentingViewController];
    [modalToDismissFrom dismissViewControllerAnimated:YES completion:nil];
}

- (void) didPressAlertButton
{
    [self.myBottomView openButtonAction:nil];
}

#pragma mark - bottom view delegate
- (void) didPressOpen
{
    [self.updateOrdersTimer invalidate];
    OrdersViewController * modalOrdersViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderPage"];
    modalOrdersViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:modalOrdersViewController animated:YES completion:nil];
    [[(OrdersViewController *)modalOrdersViewController myBottomView] performSelector:@selector(openButtonAction:) withObject:self afterDelay:0];
    modalOrdersViewController.myTopView.orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
}

- (void) didPressReady
{
    [self.updateOrdersTimer invalidate];
    OrdersViewController * modalOrdersViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderPage"];
    modalOrdersViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:modalOrdersViewController animated:YES completion:nil];
    [[(OrdersViewController *)modalOrdersViewController myBottomView] performSelector:@selector(readyButtonAction:) withObject:self afterDelay:0];
    modalOrdersViewController.myTopView.orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
}

- (void) didPressDelivered
{
    [self.updateOrdersTimer invalidate];
    OrdersViewController * modalOrdersViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderPage"];
    modalOrdersViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:modalOrdersViewController animated:YES completion:nil];
    [[(OrdersViewController *)modalOrdersViewController myBottomView] performSelector:@selector(deliveredButtonAction:) withObject:self afterDelay:0];
    modalOrdersViewController.myTopView.orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
}

- (void) didPressCancelledReturned
{
    [self.updateOrdersTimer invalidate];
    OrdersViewController * modalOrdersViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderPage"];
    modalOrdersViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:modalOrdersViewController animated:YES completion:nil];
    [[(OrdersViewController *)modalOrdersViewController myBottomView] performSelector:@selector(cancelledReturnedButtonAction:) withObject:self afterDelay:0];
    modalOrdersViewController.myTopView.orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
}

#pragma mark - table view delegate/datasource
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
        cell.loadingIndicator.hidden = YES;
        
        Order * tmpOrder = (Order *)[self.ordersForTableView objectAtIndex:indexPath.section];
        
        //if the order is from today, display the time, otherwise display the date
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
        NSDate *today = [cal dateFromComponents:components];
        components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:tmpOrder.placeTime];
        if ( [[cal dateFromComponents:components] isEqualToDate:today] )
            [self.myDateFormatter setDateFormat:@"h:ss a"];
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
        
        if ( [tmpOrder.status isEqualToString:@"Cancelled"] || [tmpOrder.status isEqualToString:@"Returned"] || [tmpOrder.status isEqualToString:@"Rejected"] )
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
                cell.statusLabel.text = @"At Station";
                cell.colorDot.backgroundColor = [UIColor colorWithRed:(float)239/255 green:(float)118/255 blue:(float)37/255 alpha:1];
            }
            else if ( [tmpOrder.anchorStatus isEqualToString:@"Delivered"] )
            {
                cell.statusLabel.text = @"Delivered";
                cell.colorDot.backgroundColor = [UIColor colorWithRed:(float)109/255 green:(float)202/255 blue:(float)72/255 alpha:1];
            }
        }
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.orderTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ( [(OrderTableCell *)[self.orderTableView cellForRowAtIndexPath:indexPath] loadingIndicator].hidden == YES ) //make sure its not a loading cell
    {
        [self.updateOrdersTimer invalidate];
        OrdersViewController * modalOrdersViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderPage"];
        modalOrdersViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
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
        [self presentViewController:modalOrdersViewController animated:NO completion:nil];
        [modalOrdersViewController.view addSubview:imageOverlay];
        
        OrderDetailViewController * modalOrderDetailViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderDetailPage"];
        modalOrderDetailViewController.didNavigateFromHomeScreen = YES;
        modalOrderDetailViewController.myOrder = [self.ordersForTableView objectAtIndex:indexPath.section];
        modalOrderDetailViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [modalOrdersViewController presentViewController:modalOrderDetailViewController animated:YES completion:^
        {
            [imageOverlay removeFromSuperview];
        }];
        modalOrderDetailViewController.myTopView.orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
    }
}

#pragma mark - didScrollToBottom/loadMoreOrders
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.lastContentOffset < scrollView.contentOffset.y) //scrolling down
    {
        float maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        if (maximumOffset - scrollView.contentOffset.y < 300.0 && ! self.myOrderManager.isLoadingOrders)
        {
            if ( [self.myDate timeIntervalSinceNow] + 3 < [[NSDate date] timeIntervalSinceNow] )
            {
                self.myDate = [NSDate date];
                [self.myOrderManager loadAllOrders];
                [self.orderTableView reloadData];
            }
        }
    }
    
    self.lastContentOffset = scrollView.contentOffset.x;
}

#pragma mark - order manager delegate
- (void) didFinishLoadingOrders:(NSArray *)orders withStatusOpen:(BOOL)open ready:(BOOL)ready delivered:(BOOL)delivered cancelledReturned:(BOOL)cancelledReturned
{
    if ( open && ready && delivered && cancelledReturned )
    {
        if ( [self.myTopView.searchBarTextField.text length] != 0 )
            self.ordersForTableView = [self.myOrderManager searchOrders:orders withString:self.myTopView.searchBarTextField.text];
        else
            self.ordersForTableView = orders;
        
        [self.orderTableView reloadData];
        
        // setting the top view bell thing number
        int numberOfOpenOrders = 0;
        for ( int i = 0; i < [orders count]; i++ )
        {
            if ( [[[orders objectAtIndex:i] status] isEqualToString:@"Open"] )
                numberOfOpenOrders++;
        }
        self.myTopView.orderNumberLabel.text = [NSString stringWithFormat:@"%i", numberOfOpenOrders];
    }
}

#pragma mark - misc.
-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
