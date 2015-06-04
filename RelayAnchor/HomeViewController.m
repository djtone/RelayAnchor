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
#import "AccountManager.h"

@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.myOrderManager = [OrderManager sharedInstanceWithDelegate:self];
    self.myDate = [NSDate date];
    self.myDateFormatter = [[NSDateFormatter alloc] init];
    [self.myOrderManager startAutoRefreshOrdersWithStatus:kLoadOrderStatusAll timeInterval:10];
    
    //ui stuff
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.myTopView = [[[NSBundle mainBundle] loadNibNamed:@"TopView" owner:self options:nil] firstObject];
    self.myTopView.delegate = self;
    self.myTopView.searchView.hidden = YES;
    self.myTopView.searchSeparator.hidden = YES;
    self.myTopView.hideBackButton = YES;
    self.myTopView.printerButton.hidden = YES;
    self.myTopView.keynoteOrdersButton.hidden = YES;
    self.myTopView.keynoteOrdersSwitch.hidden = YES;
    [self.view addSubview:self.myTopView];
    
    self.myBottomView = [[[NSBundle mainBundle] loadNibNamed:@"BottomView" owner:self options:nil] firstObject];
    self.myBottomView.delegate = self;
    [self.view addSubview:self.myBottomView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self updateMallName];
    [self updateTopBarMallName];
    [self updateWelcomeImage];
    [self.myBottomView resetButtons];
}

- (void) updateTopBarMallName
{
    [self.myTopView.mallNameButton setTitle:[[[AccountManager sharedInstance] selectedMall] name] forState:UIControlStateNormal];
}

- (void) updateMallName
{
    NSString * mallName = [[[AccountManager sharedInstance] selectedMall] name];
    if ( !mallName || [mallName class] == [NSNull class] )
        return;
    
    UIFont * bold = [UIFont fontWithName:@"Helvetica-Bold" size:58];
    NSDictionary * arialDict = [NSDictionary dictionaryWithObject:bold forKey:NSFontAttributeName];
    NSMutableAttributedString * aAttrString = [[NSMutableAttributedString alloc] initWithString:[mallName stringByReplacingOccurrencesOfString:@" Mall" withString:@""] attributes:arialDict];
    
    UIFont * normal = [UIFont systemFontOfSize:58];
    NSDictionary * verdanaDict = [NSDictionary dictionaryWithObject:normal forKey:NSFontAttributeName];
    [aAttrString appendAttributedString:[[NSMutableAttributedString alloc]initWithString:@" Mall" attributes:verdanaDict]];
    
    self.mallNameLabel.attributedText = aAttrString;
}

- (void) updateWelcomeImage
{
    if ( [[[[AccountManager sharedInstance] selectedMall] name] isEqualToString:@"Oakbrook Mall"] )
        self.welcomeImageView.image = [UIImage imageNamed:@"Welcome_oakbrook.png"];
    else if ( [[[[AccountManager sharedInstance] selectedMall] name] isEqualToString:@"Water Tower Mall"] )
        self.welcomeImageView.image = [UIImage imageNamed:@"Welcome_waterTower.png"];
}

#pragma mark - top view delegate
- (void) didPressLogout
{
    [self.myOrderManager stopAutoRefreshOrders:nil];
    UIViewController * modalToDismissFrom = self;
    while ( ! [[[modalToDismissFrom presentingViewController] restorationIdentifier] isEqualToString:@"loginPage"] )
        modalToDismissFrom = [modalToDismissFrom presentingViewController];
    [modalToDismissFrom dismissViewControllerAnimated:YES completion:nil];
}

- (void) didPressAlertButton
{
    [self.myBottomView openButtonAction:nil];
}

- (void) didChangeMall
{
    self.ordersForTableView = @[];
    [self.myOrderManager stopAutoRefreshOrders:^
    {
        [self.myOrderManager startAutoRefreshOrdersWithStatus:kLoadOrderStatusAll timeInterval:10];
        [self forceRefreshOrders];
        [UIView animateWithDuration:.2 animations:^
        {
            self.mallNameLabel.alpha = 0;
            self.welcomeImageView.alpha = 0;
            self.myTopView.mallNameButton.alpha = 0;
        }
        completion:^(BOOL finished)
        {
            [self updateMallName];
            [self updateWelcomeImage];
            [self updateTopBarMallName];
            [UIView animateWithDuration:.2 animations:^
            {
                self.mallNameLabel.alpha = 1;
                self.welcomeImageView.alpha = 1;
                self.myTopView.mallNameButton.alpha = 1;
            }];
        }];
    }];
}

#pragma mark - bottom view delegate
- (void) didChangeStatus:(enum BottomViewStatus)selectedStatus
{
    [self.myOrderManager stopAutoRefreshOrders:^
    {
        OrdersViewController * modalOrdersViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderPage"];
        modalOrdersViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:modalOrdersViewController animated:YES completion:nil];
        modalOrdersViewController.myTopView.orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
        
        if ( selectedStatus == kBottomViewStatusOpen )
            [[(OrdersViewController *)modalOrdersViewController myBottomView] performSelector:@selector(openButtonAction:) withObject:self afterDelay:0];
        else if ( selectedStatus == kBottomViewStatusReady )
            [[(OrdersViewController *)modalOrdersViewController myBottomView] performSelector:@selector(readyButtonAction:) withObject:self afterDelay:0];
        else if ( selectedStatus == kBottomViewStatusDelivered )
            [[(OrdersViewController *)modalOrdersViewController myBottomView] performSelector:@selector(deliveredButtonAction:) withObject:self afterDelay:0];
        else if ( selectedStatus == kBottomViewStatusCancelledReturned )
            [[(OrdersViewController *)modalOrdersViewController myBottomView] performSelector:@selector(cancelledReturnedButtonAction:) withObject:self afterDelay:0];
    }];
}

#pragma mark - table view delegate/datasource
- (void) forceRefreshOrders
{
    [self.myOrderManager loadOrdersWithStatus:kLoadOrderStatusAll completion:nil];
    [self.orderTableView reloadData];
}

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
        cell.idLabel.text = [NSString stringWithFormat:@"%@", tmpOrder.wcsOrderId];
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
        cell.statusLabel.text = [tmpOrder stringFromRunnerStatus];
        if ( tmpOrder.isKeynoteOrder )
            cell.keynoteOrderLabel.hidden = NO;
        else
            cell.keynoteOrderLabel.hidden = YES;
        
        cell.statusLabel.text = tmpOrder.displayStatus;
        cell.colorDot.backgroundColor = tmpOrder.displayColor;
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.orderTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ( [(OrderTableCell *)[self.orderTableView cellForRowAtIndexPath:indexPath] loadingIndicator].hidden == YES ) //make sure its not a loading cell
    {
        [self.myOrderManager stopAutoRefreshOrders:nil];
        OrdersViewController * modalOrdersViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderPage"];
        modalOrdersViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
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
                [self forceRefreshOrders];
            }
        }
    }
    
    self.lastContentOffset = scrollView.contentOffset.x;
}

#pragma mark - order manager delegate
- (void) didStartLoadingOrdersWithStatus:(LoadOrderStatus)loadOrderStatus
{
    [self.orderTableView reloadData];
}

- (void) didFinishLoadingOrders:(NSArray *)orders status:(LoadOrderStatus)loadOrderStatus error:(NSString *)error
{
    //check if there is an error before doing the below stuff
    if ( loadOrderStatus == kLoadOrderStatusAll )
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
            if ( [(Order *)[orders objectAtIndex:i] status] == kStatusOpen )
                numberOfOpenOrders++;
        }
        self.myTopView.orderNumberLabel.text = [NSString stringWithFormat:@"%i", numberOfOpenOrders];
    }
}

- (void) didFinishLoadingOrders:(NSArray *)orders withStatusOpen:(BOOL)open ready:(BOOL)ready delivered:(BOOL)delivered cancelledReturned:(BOOL)cancelledReturned success:(BOOL)success
{
    if ( success )
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
                if ( [(Order *)[orders objectAtIndex:i] status] == kStatusOpen )
                    numberOfOpenOrders++;
            }
            self.myTopView.orderNumberLabel.text = [NSString stringWithFormat:@"%i", numberOfOpenOrders];
        }
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
