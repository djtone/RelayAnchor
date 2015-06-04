//
//  TopView.m
//  RelayAnchor
//
//  Created by chuck on 8/9/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "TopView.h"
#import "UIAlertView+Blocks.h"
#import "SVProgressHUD.h"
#import "OrdersViewController.h"

@implementation TopView

- (void) awakeFromNib
{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:@"UITextFieldTextDidChangeNotification" object:self.searchBarTextField];
    
    self.sharedAccountManager = [AccountManager sharedInstance];
    self.myOrderManager = [OrderManager sharedInstance];
    self.myPrintManager = [PrintManager sharedPrintManager];
    
    //ui stuff
    if ([self.searchBarTextField respondsToSelector:@selector(setAttributedPlaceholder:)])
        self.searchBarTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchBarTextField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    else
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    
    //mall select / logout view
    [self.mallNameButton setTitle:self.sharedAccountManager.selectedMall.name forState:UIControlStateNormal];
    self.selectMallAndLogoutView = [[UIView alloc] initWithFrame:CGRectMake(800, 51, 194, 100)];
    
    UIImageView * triangleThing = [[UIImageView alloc] initWithFrame:CGRectMake(85, -3, 25, 15)];
    [triangleThing setImage:[UIImage imageNamed:@"BottomView_SelectionTriangle.png"]];
    [self.selectMallAndLogoutView addSubview:triangleThing];
    
    self.mallSelectTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 8, 194, 88)];
    self.mallSelectTableView.layer.cornerRadius = 4;
    self.mallSelectTableView.delegate = self;
    self.mallSelectTableView.dataSource = self;
    [self.selectMallAndLogoutView addSubview:self.mallSelectTableView];
    
    self.selectMallAndLogoutView.hidden = YES;
    [self addSubview:self.selectMallAndLogoutView];
    
    self.searchActivityIndicator.hidden = YES;
    self.keynoteActivityIndicator.hidden = YES;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    //for some reason i dont need to call the below line anymore. in fact it will cause an exception "layout subviews needs to call super" even though i am calling super
    //self.frame = CGRectMake(0, 0, 1024, 70);
    
    if ( self.hideBackButton )
    {
        self.backButton.hidden = YES;
        self.logo.frame = CGRectMake(27, 25, 222, 27);
    }
    
    if ( self.myPrintManager.myPrinterPicker.selectedPrinter )
    {
        [self.printerButton setTitle:[@" " stringByAppendingString:self.myPrintManager.myPrinterPicker.selectedPrinter.displayName] forState:UIControlStateNormal];
        [self.printerButton setImage:[UIImage imageNamed:@"TopView_printerIcon.png"] forState:UIControlStateNormal];
    }
    else
    {
        [self.printerButton setTitle:@" No Printer Selected" forState:UIControlStateNormal];
        [self.printerButton setImage:[UIImage imageNamed:@"TopView_printerIconX.png"] forState:UIControlStateNormal];
    }
    
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] == NSOrderedAscending )
        self.printerButton.hidden = YES;
}

//this method is required for the logout/select mall button - since it is outside the view bounds
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView* view in self.subviews)
    {
        if ( view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event] && !view.hidden )
            return YES;
    }
    return NO;
}

- (IBAction)mallNameAction:(id)sender
{
    if ( self.selectMallAndLogoutView.hidden )
    {
        self.selectMallAndLogoutView.hidden = NO;
        if ( ! self.mallsForTableView )
        {
            [AccountManager nearbyMalls:^(NSArray *malls)
            {
                self.mallsForTableView = malls;
                NSMutableArray * indexPaths = [[NSMutableArray alloc] init];
                for ( int i = 0; i < malls.count; i++ )
                    [indexPaths addObject:[NSIndexPath indexPathForRow:i+1 inSection:0]];
                
                self.selectMallAndLogoutView.frame = CGRectMake(self.selectMallAndLogoutView.frame.origin.x,
                                                                self.selectMallAndLogoutView.frame.origin.y,
                                                                self.selectMallAndLogoutView.frame.size.width,
                                                                ((self.mallsForTableView.count+1) * 44) + 8);
                [UIView animateWithDuration:.4 animations:^
                {
                    self.mallSelectTableView.frame = CGRectMake(self.mallSelectTableView.frame.origin.x,
                                                                self.mallSelectTableView.frame.origin.y,
                                                                self.mallSelectTableView.frame.size.width,
                                                                (self.mallsForTableView.count+1) * 44);
                }];
                
                [self.mallSelectTableView reloadData];
            }];
        }
    }
    else
        self.selectMallAndLogoutView.hidden = YES;
}

- (IBAction)backButtonAction:(id)sender
{
    if ( [self.delegate respondsToSelector:@selector(didPressBackButton)] )
        [self.delegate didPressBackButton];
}


- (IBAction)alertButtonAction:(id)sender
{
    [self.delegate didPressAlertButton];
}

#pragma mark - keynote
- (IBAction)keynoteOrdersAction:(id)sender
{
    [self updateKeynoteBoolean];
}

- (IBAction)keynoteOrdersSwitchChanged:(id)sender
{
    [self updateKeynoteBoolean];
}

- (void) updateKeynoteBoolean
{
    if ( self.myOrderManager.showKeynoteOrders )
    {
        self.myOrderManager.showKeynoteOrders = NO;
        [self.keynoteOrdersSwitch setOn:NO];
    }
    else
    {
        self.myOrderManager.showKeynoteOrders = YES;
        [self.keynoteOrdersSwitch setOn:YES];
    }
    
    if ( [self.delegate respondsToSelector:@selector(didChangeKeynoteBoolean)] )
    {
        [self.delegate didChangeKeynoteBoolean];
        self.keynoteActivityIndicator.hidden = NO;
        [self.keynoteActivityIndicator startAnimating];
    }
}

#pragma mark - search bar
- (void)textFieldDidChange :(NSNotification *)notif
{
    if ( [self.delegate respondsToSelector:@selector(searchBarTextDidChange:)] )
    {
        self.searchActivityIndicator.hidden = NO;
        [self.searchActivityIndicator startAnimating];
        [self.delegate searchBarTextDidChange:[(UITextField *)notif.object text]];
    }
}

- (IBAction)searchButtonAction:(id)sender
{
    [self.searchBarTextField becomeFirstResponder];
}

#pragma mark - table view
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( ! self.mallsForTableView )
        return 2;
    else
        return self.mallsForTableView.count + 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //create cell
    static NSString * cellIdentifier = @"cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    cell.backgroundColor = [UIColor colorWithWhite:(float)235/255 alpha:1];
    
    //configure cell
    if ( indexPath.row == 0 )
    {
        cell.backgroundColor = [UIColor colorWithWhite:(float)225/255 alpha:1];
        cell.textLabel.textColor = [UIColor blackColor];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        cell.textLabel.text = @"Logout";
    }
    else
    {
        if ( ! self.mallsForTableView )
        {
            UIActivityIndicatorView * loadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(90, 7, 30, 30)];
            loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
            [cell addSubview:loadingIndicator];
            [loadingIndicator startAnimating];
        }
        else
        {
            cell.textLabel.text = [self.mallsForTableView objectAtIndex:indexPath.row-1];
            if ( [cell.textLabel.text isEqualToString:[[[AccountManager sharedInstance] selectedMall] name]] )
                cell.backgroundColor = [UIColor colorWithWhite:(float)240/255 alpha:1];
        }
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.mallSelectTableView deselectRowAtIndexPath:indexPath animated:YES];
    [UIView animateWithDuration:.3 animations:^
    {
        self.selectMallAndLogoutView.hidden = YES;
    }
    completion:^(BOOL finished)
    {
        //logout cell
        if ( indexPath.row == 0 )
        {
            [AccountManager logout:^
            {
                if ( [self.delegate respondsToSelector:@selector(didPressLogout)] )
                    [self.delegate didPressLogout];
            }];
            return;
        }
        
        NSString * mallName = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
        
        if ( [[[[AccountManager sharedInstance] selectedMall] name] isEqualToString:mallName] )
            return;
        
        BOOL isAuthenticated = NO;
        for ( Mall * tmpMall in [[AccountManager sharedInstance] authenticatedMalls] )
        {
            if ( [mallName isEqualToString:tmpMall.name] )
            {
                isAuthenticated = YES;
                [[AccountManager sharedInstance] setSelectedMall:tmpMall];
                [self.mallNameButton setTitle:tmpMall.name forState:UIControlStateNormal];
                if ( [self.delegate respondsToSelector:@selector(didChangeMall)] )
                    [self.delegate didChangeMall];
                else
                    NSLog(@"delegate does not respond to didChangeMall");
                
                break;
            }
        }
        
        if ( ! isAuthenticated )
        {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:mallName message:[NSString stringWithFormat:@"Please sign in to %@", mallName] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
            alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
            [alert show];
        }
    }];
}

#pragma mark - alert view
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 0 ) //cancel button
        return;
    
    [SVProgressHUD show];
    BOOL rememberEmail = YES;
    if ( [[AccountManager sharedInstance] rememberedEmail] == nil )
        rememberEmail = NO;
    [AccountManager loginWithUser:[[alertView textFieldAtIndex:0] text] password:[[alertView textFieldAtIndex:1] text] rememberEmail:rememberEmail andPushToken:nil completion:^(BOOL success)
    {
        [SVProgressHUD dismiss];
        if ( success )
        {
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
            [self.mallNameButton setTitle:[[[AccountManager sharedInstance] selectedMall] name] forState:UIControlStateNormal];
            if ( [self.delegate respondsToSelector:@selector(didChangeMall)] )
                [self.delegate didChangeMall];
        }
        else
        {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Invalid Login" message:[alertView message] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
            alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
            [[alert textFieldAtIndex:0] setText:[[alertView textFieldAtIndex:0] text]];
            [[alert textFieldAtIndex:1] becomeFirstResponder];
            [alert show];
        }
    }];
}

- (BOOL) alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    if ( [[alertView textFieldAtIndex:0] text] > 0 && [[[alertView textFieldAtIndex:1] text] length] > 0 )
        return YES;
    
    return NO;
}

#pragma mark - printing
- (IBAction)printerAction:(id)sender
{
    //self.myPrintManager.myPrinterPicker.delegate = self.myPrintManager; //for some reason the delegate gets lost after one iteration of this printer selection shizzle
    [self.myPrintManager presentFromRect:[(UIButton *)sender frame] inView:self animated:YES completionHandler:^(UIPrinterPickerController *printerPickerController, BOOL userDidSelect, NSError *error)
    {
        //get main queue?
        if ( userDidSelect )
        {
            [self.printerButton setTitle:[@" " stringByAppendingString:self.myPrintManager.myPrinterPicker.selectedPrinter.displayName] forState:UIControlStateNormal];
            [self.printerButton setImage:[UIImage imageNamed:@"TopView_printerIcon.png"] forState:UIControlStateNormal];
        }
    }];
}
@end
