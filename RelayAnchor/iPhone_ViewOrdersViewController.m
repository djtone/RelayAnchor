//
//  iPhone_ViewOrdersViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 5/22/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_ViewOrdersViewController.h"
#import "iPhone_OrderDetailViewController.h"
#import "iPhone_OrderCell.h"
#import "AccountManager.h"
#import "MFSideMenu.h"
#import "SVProgressHUD.h"
#import "UIAlertView+Blocks.h"

@implementation iPhone_ViewOrdersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.ordersForTableView = @[];
    self.swipedOrderIds = [[NSMutableArray alloc] init];
    self.myDateFormatter = [[NSDateFormatter alloc] init];
    [self.myDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    self.myOrderManager = [OrderManager sharedInstanceWithDelegate:self];
    self.myTableView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:@"UITextFieldTextDidChangeNotification" object:self.searchTextField];
    [self.myTabBar setSelectedItem:[[self.myTabBar items] objectAtIndex:0]];
    self.selectedOrderStatus = kLoadOrderStatusOpen;
    [self.myOrderManager startAutoRefreshOrdersWithStatus:kLoadOrderStatusOpen timeInterval:15];
    self.myTableView.backgroundColor = [UIColor clearColor];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self updateMallName];
    [self updateWelcomeImage];
}

- (void) updateWelcomeImage
{
    if ( [[[[AccountManager sharedInstance] selectedMall] name] isEqualToString:@"Oakbrook Mall"] )
        self.mallImageView.image = [UIImage imageNamed:@"Welcome_oakbrook.png"];
    else if ( [[[[AccountManager sharedInstance] selectedMall] name] isEqualToString:@"Water Tower Mall"] )
        self.mallImageView.image = [UIImage imageNamed:@"Welcome_waterTower.png"];
    else if ( [[[[AccountManager sharedInstance] selectedMall] name] isEqualToString:@"Woodfield Mall"] )
        self.mallImageView.image = [UIImage imageNamed:@"Welcome_woodfield.png"];
}

- (void) updateMallName
{
    NSString * mallName = [[[AccountManager sharedInstance] selectedMall] name];
    if ( !mallName || [mallName class] == [NSNull class] )
        return;
    
    self.mallNameLabel.text = mallName;
}

#pragma mark - table view
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if ( self.ordersForTableView.count )
    {
        self.noOrdersLabel.hidden = YES;
        [self showTable];
        [self.loadingIndicator stopAnimating];
        return self.ordersForTableView.count;
    }
    else
    {
        [self hideTable];
        
        if ( self.myOrderManager.isLoadingOrders )
            [self.loadingIndicator startAnimating];
        else
        {
            self.noOrdersLabel.alpha = 0;
            self.noOrdersLabel.hidden = NO;
            [UIView animateWithDuration:.2 animations:^
            {
                self.noOrdersLabel.alpha = 1;
            }];
        }
        
        return 0;
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    iPhone_OrderCell * cell = [tableView dequeueReusableCellWithIdentifier:@"iPhoneOrderCell"];
    cell.layer.borderColor = [[UIColor colorWithRed:(float)170/255 green:(float)170/255 blue:(float)170/255 alpha:1] CGColor];
    Order * tmpOrder = [self.ordersForTableView objectAtIndex:indexPath.section];
    
    CGSize textSize;
    cell.orderIdLabel.text = [NSString stringWithFormat:@"Order %@", tmpOrder.wcsOrderId];
    cell.statusLabel.text = tmpOrder.displayStatus;
    cell.dot.backgroundColor = tmpOrder.displayColor;
    textSize = [cell.statusLabel.text sizeWithAttributes:@{NSFontAttributeName:[cell.statusLabel font]}];
    if ( textSize.width > cell.statusLabel.frame.size.width )
        textSize.width = cell.statusLabel.frame.size.width;
    [cell.dot setFrame:CGRectMake((self.myTableView.frame.size.width - 26) - textSize.width, cell.dot.frame.origin.y, cell.dot.frame.size.width, cell.dot.frame.size.height)];
    cell.dateLabel.text = [self.myDateFormatter stringFromDate:tmpOrder.placeTime];
    
    if ( tmpOrder.runnerName.length )
    {
        [cell.runnerNameLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]];
        [cell.runnerNameLabel setTextColor:[UIColor blackColor]];
        cell.runnerNameLabel.text = tmpOrder.runnerName;
        cell.assignRunnerButton.hidden = YES;
    }
    else
    {
        [cell.runnerNameLabel setFont:[UIFont boldSystemFontOfSize:13]];
        [cell.runnerNameLabel setTextColor:[UIColor orangeColor]];
        cell.runnerNameLabel.text = @"Not Assigned";
        cell.assignRunnerButton.hidden = NO;
    }
    textSize = [cell.runnerNameLabel.text sizeWithAttributes:@{NSFontAttributeName:[cell.runnerNameLabel font]}];
    if ( textSize.width > cell.runnerNameLabel.frame.size.width )
        textSize.width = cell.runnerNameLabel.frame.size.width;
    [cell.runnerImageView setFrame:CGRectMake((self.myTableView.frame.size.width - 24) - textSize.width, cell.runnerImageView.frame.origin.y, cell.runnerImageView.frame.size.width, cell.runnerImageView.frame.size.height)];
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
    
    //swipe/longPress menu
    for ( UIGestureRecognizer * gesture in [[cell contentView] gestureRecognizers] )
        [[cell contentView] removeGestureRecognizer:gesture];
    
    //only open orders should have override option
    if ( [tmpOrder.displayStatus isEqualToString:@"Open"] )
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
    
    if ( [self.swipedOrderIds containsObject:tmpOrder.wcsOrderId] )
        cell.swipeButton.frame = CGRectMake(cell.contentView.frame.size.width - cell.swipeButton.frame.size.width, cell.swipeButton.frame.origin.y, cell.swipeButton.frame.size.width, cell.swipeButton.frame.size.height);
    else
        cell.swipeButton.frame = CGRectMake(cell.contentView.frame.size.width, cell.swipeButton.frame.origin.y, cell.swipeButton.frame.size.width, cell.swipeButton.frame.size.height);
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.myOrderToSend = [self.ordersForTableView objectAtIndex:indexPath.section];
    [self performSegueWithIdentifier:@"goDetails" sender:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) handleLongPressGesture:(UILongPressGestureRecognizer *)gesture
{
    if ( gesture.state == UIGestureRecognizerStateBegan )
    {
        iPhone_OrderCell * cell;
        if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
            cell = (iPhone_OrderCell *)[[gesture view] superview];
        else
            cell = (iPhone_OrderCell *)[[[gesture view] superview] superview];
        
        [self toggleSwipeMenuForCell:cell];
    }
}

- (void) handleSwipeGesture:(UISwipeGestureRecognizer *)gesture
{
    [self.myTableView deselectRowAtIndexPath:[self.myTableView indexPathForSelectedRow] animated:YES];
    iPhone_OrderCell * cell;
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending ) //iOS 8 and greater
        cell = (iPhone_OrderCell *)[[gesture view] superview];
    else
        cell = (iPhone_OrderCell *)[[[gesture view] superview] superview];
    
    [self toggleSwipeMenuForCell:cell];
}

- (void) toggleSwipeMenuForCell:(iPhone_OrderCell *)cell
{
    Order * tmpOrder = [self.ordersForTableView objectAtIndex:[[self.myTableView indexPathForCell:cell] section]];
    
    if ( [self.swipedOrderIds containsObject:tmpOrder.wcsOrderId] )
    {
        [UIView animateWithDuration:.5 animations:^
         {
             cell.swipeButton.frame = CGRectMake(cell.contentView.frame.size.width, cell.swipeButton.frame.origin.y, cell.swipeButton.frame.size.width, cell.swipeButton.frame.size.height);
         }];
        [self.swipedOrderIds removeObject:tmpOrder.wcsOrderId];
    }
    else
    {
        [UIView animateWithDuration:.5 animations:^
         {
             cell.swipeButton.frame = CGRectMake(cell.contentView.frame.size.width - cell.swipeButton.frame.size.width, cell.swipeButton.frame.origin.y, cell.swipeButton.frame.size.width, cell.swipeButton.frame.size.height);
         }];
        [self.swipedOrderIds addObject:tmpOrder.wcsOrderId];
    }
}


- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] init];
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10;
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
    
    [self refreshOrders];
}

#pragma mark - order manager
- (void) didStartLoadingOrdersWithStatus:(LoadOrderStatus)loadOrderStatus
{
    if ( ! self.ordersForTableView.count )
    {
        [self hideTable];
        self.noOrdersLabel.hidden = YES;
        [self.loadingIndicator startAnimating];
    }
}

- (void) didFinishLoadingOrders:(NSArray *)orders status:(LoadOrderStatus)loadOrderStatus error:(NSString *)error
{
    [self.loadingIndicator stopAnimating];
    [self showTable];
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
- (void) showTable
{
    if ( self.myTableView.hidden == NO )
        return;

    [self.myTableView.layer removeAllAnimations]; //sometimes [hidetable] and [showtable] were called too close together, and they would mess each other up
    self.myTableView.hidden = NO;
    self.myTableView.alpha = 0;
    self.myTableView.hidden = NO;
    [UIView animateWithDuration:.2 animations:^
    {
        self.myTableView.alpha = 1;
    }];
}

- (void) hideTable
{
    if ( self.myTableView.hidden == YES )
        return;

    [self.myTableView.layer removeAllAnimations]; //sometimes [hidetable] and [showtable] were called too close together, and they would mess each other up
    [UIView animateWithDuration:.2 animations:^
    {
        self.myTableView.alpha = 0;
    }
    completion:^(BOOL finished)
    {
        self.myTableView.hidden = YES;
        self.myTableView.alpha = 1;
    }];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.myOrderManager cancelLoadOrders:nil];
    [self.myOrderManager stopAutoRefreshOrders:nil];
    
    if ( [segue.identifier isEqualToString:@"goDetails"] )
    {
        iPhone_OrderDetailViewController *detailVc = [segue destinationViewController];
        detailVc.myOrder = self.myOrderToSend;
    }
}

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

- (IBAction)changeMallAction:(id)sender
{
   [SVProgressHUD showImage:nil status:@"change mall"];
}

- (IBAction)overrideAction:(id)sender
{
    NSIndexPath * indexPathOfOrder;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending) //iOS 8 and greater
        indexPathOfOrder = [self.myTableView indexPathForCell:(iPhone_OrderCell *)[[sender superview] superview]];
    else
        indexPathOfOrder = [self.myTableView indexPathForCell:(iPhone_OrderCell *)[[[sender superview] superview] superview]];
    
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
                                                          [self.myTableView deleteSections:[NSIndexSet indexSetWithIndex:[overrideIndex section]] withRowAnimation:UITableViewRowAnimationRight];
                                                          
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

- (IBAction)searchAction:(id)sender
{
    [self.view endEditing:YES];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
