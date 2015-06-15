//
//  iPhone_ViewOrdersViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 5/22/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_ViewOrdersViewController.h"
#import "iPhone_OrderCell.h"
#import "AccountManager.h"
#import "MFSideMenu.h"

@implementation iPhone_ViewOrdersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.ordersForTableView = @[];
    self.myDateFormatter = [[NSDateFormatter alloc] init];
    [self.myDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    self.myOrderManager = [OrderManager sharedInstanceWithDelegate:self];
    self.myTableView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:@"UITextFieldTextDidChangeNotification" object:self.searchTextField];
}

- (void) viewWillAppear:(BOOL)animated
{
    self.selectedOrderStatus = kLoadOrderStatusOpen;
    [self.myTabBar setSelectedItem:[[self.myTabBar items] objectAtIndex:0]];
    [self.myOrderManager startAutoRefreshOrdersWithStatus:kLoadOrderStatusOpen timeInterval:15];
}

#pragma mark - table view
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if ( self.ordersForTableView.count )
    {
        self.myTableView.hidden = NO;
        [self.loadingIndicator stopAnimating];
        return 1;
    }
    else
    {
        self.myTableView.hidden = YES;
        return 0;
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( self.ordersForTableView.count )
        return self.ordersForTableView.count;
    else
        return 50;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    iPhone_OrderCell * cell = [tableView dequeueReusableCellWithIdentifier:@"iPhoneOrderCell"];
    Order * tmpOrder = [self.ordersForTableView objectAtIndex:indexPath.row];
    
    CGSize textSize;
    cell.orderIdLabel.text = [NSString stringWithFormat:@"Order %@", tmpOrder.wcsOrderId];
    cell.statusLabel.text = tmpOrder.displayStatus;
    cell.dot.backgroundColor = tmpOrder.displayColor;
    textSize = [cell.statusLabel.text sizeWithAttributes:@{NSFontAttributeName:[cell.statusLabel font]}];
    if ( textSize.width > cell.statusLabel.frame.size.width )
        textSize.width = cell.statusLabel.frame.size.width;
    [cell.dot setFrame:CGRectMake((self.myTableView.frame.size.width - 26) - textSize.width, cell.dot.frame.origin.y, cell.dot.frame.size.width, cell.dot.frame.size.height)];
    cell.dateLabel.text = [self.myDateFormatter stringFromDate:tmpOrder.placeTime];
    cell.runnerNameLabel.text = tmpOrder.runnerName;
    textSize = [cell.runnerNameLabel.text sizeWithAttributes:@{NSFontAttributeName:[cell.runnerNameLabel font]}];
    if ( textSize.width > cell.runnerNameLabel.frame.size.width )
        textSize.width = cell.runnerNameLabel.frame.size.width;
    [cell.runnerImageView setFrame:CGRectMake((self.myTableView.frame.size.width - 25) - textSize.width, cell.runnerImageView.frame.origin.y, cell.runnerImageView.frame.size.width, cell.runnerImageView.frame.size.height)];
    if ( tmpOrder.runnerName.length )
        cell.runnerImageView.hidden = NO;
    else
        cell.runnerImageView.hidden = YES;
    cell.memberNameLabel.text = [NSString stringWithFormat:@"%@ %@", tmpOrder.buyerFirstName, tmpOrder.buyerLastName];
    cell.priceLabel.text = [NSString stringWithFormat:@"$%.2f", [tmpOrder.totalPrice floatValue]];
    cell.fulfillmentAddressLabel.text = [tmpOrder.pickupLocation capitalizedString];
    int imageDiff;
    if ( tmpOrder.hasDeliveryItems )
    {
        [cell.fulfillmentImageView setImage:[UIImage imageNamed:@"iPhone_OrderCell_DeliveryIcon.png"]];
        imageDiff = 7;
    }
    else
    {
        [cell.fulfillmentImageView setImage:[UIImage imageNamed:@"iPhone_OrderCell_LocationIcon.png"]];
        imageDiff = 0;
    }
    textSize = [cell.fulfillmentAddressLabel.text sizeWithAttributes:@{NSFontAttributeName:[cell.fulfillmentAddressLabel font]}];
    if ( textSize.width > cell.fulfillmentAddressLabel.frame.size.width )
        textSize.width = cell.fulfillmentAddressLabel.frame.size.width;
    [cell.fulfillmentImageView setFrame:CGRectMake((self.myTableView.frame.size.width - (29 + imageDiff)) - textSize.width, cell.fulfillmentImageView.frame.origin.y, cell.fulfillmentImageView.frame.size.width, cell.fulfillmentImageView.frame.size.height)];
    
    return cell;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ( scrollView.contentOffset.y < -scrollView.contentInset.top || scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.size.height + scrollView.contentInset.top )
        return;
    
    
    if ( self.lastContentOffset < scrollView.contentOffset.y ) // scrolling up
    {
        if ( self.myTableView.frame.origin.y > 115 )
        {
            self.myTableView.frame = CGRectMake(self.myTableView.frame.origin.x, self.myTableView.frame.origin.y-5, self.myTableView.frame.size.width, self.myTableView.frame.size.height+5);
            
            if ( self.mallImageView.alpha > 0 )
            {
                self.mallImageView.alpha -= .1;
                self.mallImageOverlay.alpha -= .1;
            }
        }
    }
    else //scrolling down
    {
        if ( self.myTableView.frame.origin.y < 185 )
        {
            self.myTableView.frame = CGRectMake(self.myTableView.frame.origin.x, self.myTableView.frame.origin.y+5, self.myTableView.frame.size.width, self.myTableView.frame.size.height-5);
            
            if ( self.mallImageView.alpha < 1 )
            {
                self.mallImageView.alpha += .1;
                self.mallImageOverlay.alpha += .1;
            }
        }
    }
    
    self.lastContentOffset = scrollView.contentOffset.y;
}

#pragma mark - text field
- (void)textFieldDidChange :(NSNotification *)notif
{
    [self refreshOrders];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if ( textField == self.searchTextField )
        [textField resignFirstResponder];
    return YES;
}

#pragma mark - tab bar
- (void) tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if ( item == [self.myTabBar.items objectAtIndex:0 ] )
        self.selectedOrderStatus = kLoadOrderStatusOpen;
    else if ( item == [self.myTabBar.items objectAtIndex:1 ] )
        self.selectedOrderStatus = kLoadOrderStatusReady;
    else if ( item == [self.myTabBar.items objectAtIndex:2 ] )
        self.selectedOrderStatus = kLoadOrderStatusDelivered;
    else if ( item == [self.myTabBar.items objectAtIndex:3 ] )
        self.selectedOrderStatus = kLoadOrderStatusCancelledReturned;
    
    [self.myOrderManager stopAutoRefreshOrders:^
    {
        [self.myOrderManager startAutoRefreshOrdersWithStatus:self.selectedOrderStatus timeInterval:15];
    }];
    
    self.ordersForTableView = [self.myOrderManager.cachedOrders objectForKey:[EnumTypes stringFromLoadOrderStatus:self.selectedOrderStatus]];
    [self refreshOrders];
}

#pragma mark - order manager
- (void) didStartLoadingOrdersWithStatus:(LoadOrderStatus)loadOrderStatus
{
    if ( ! self.ordersForTableView.count )
    {
        self.myTableView.hidden = YES;
        [self.loadingIndicator startAnimating];
    }
}

- (void) didFinishLoadingOrders:(NSArray *)orders status:(LoadOrderStatus)loadOrderStatus error:(NSString *)error
{
    [self.loadingIndicator stopAnimating];
    self.myTableView.hidden = NO;
    [self refreshOrders];
}

#pragma mark - action sheet
- (IBAction)sortByAction:(id)sender
{
    UIActionSheet * testActionSheet = [[UIActionSheet alloc] initWithTitle:@"Sort Orders" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Newest", @"Oldest", @"Name", @"Status", nil];
    [testActionSheet showFromTabBar:self.myTabBar];
}


- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSArray * sortPreference;
    if ( buttonIndex == 0 )
        sortPreference = @[@"Order Date", @NO];
    else if ( buttonIndex == 1 )
        sortPreference = @[@"Order Date", @YES];
    else if ( buttonIndex == 2 )
        sortPreference = @[@"Buyer Name", @YES];
    else if ( buttonIndex == 3 )
        sortPreference = @[@"Status", @YES];
    
    NSMutableArray * sortPreferences = [[AccountManager sharedInstance] orderSortPreferences];
    for ( int i = 0; i < [sortPreferences count]; i++ )
    {
        if ( [[[sortPreferences objectAtIndex:i] firstObject] isEqualToString:[sortPreference firstObject]] )
        {
            [sortPreferences removeObjectAtIndex:i];
            [sortPreferences insertObject:sortPreference atIndex:0];
            break;
        }
    }
    
    [[AccountManager sharedInstance] setOrderSortPreferences:sortPreferences];
    [[NSUserDefaults standardUserDefaults] setValue:sortPreferences forKey:@"orderSortPreferences"];
    [self refreshOrders];
}

#pragma mark - misc.
- (void) refreshOrders
{
    self.ordersForTableView = [self.myOrderManager searchOrders:[OrderManager sortOrders:[self.myOrderManager.cachedOrders objectForKey:[EnumTypes stringFromLoadOrderStatus:self.selectedOrderStatus]]] withString:self.searchTextField.text];
    [self.myTableView reloadData];
}

- (IBAction)sideMenuAction:(id)sender
{
    MFSideMenuContainerViewController * rootController = (MFSideMenuContainerViewController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    [rootController toggleLeftSideMenuCompletion:^
    {
        //
    }];
}

- (IBAction)searchAction:(id)sender
{
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
