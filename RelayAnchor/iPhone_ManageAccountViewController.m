//
//  iPhone_ManageAccountViewController.m
//  RelayAnchor
//
//  Created by chuck johnston on 5/22/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "iPhone_ManageAccountViewController.h"
#import "UIAlertView+Blocks.h"
#import "AccountHeaderCell.h"
#import "AccountDetailCell.h"

@implementation iPhone_ManageAccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.myAccountManager = [AccountManager sharedInstance];
    self.tableDictionary = [self.myAccountManager.selectedMall.details valueForKey:[[self.myAccountManager.selectedMall.details allKeys] objectAtIndex:[self.mySegmentedControl selectedSegmentIndex]]];
    self.openSections = [[NSMutableDictionary alloc] init];
    for ( int i = 0; i < [[self.myAccountManager.selectedMall.details allKeys] count]; i++ )
    {
        //make the first section open by default
        NSMutableArray * tmpMutableArray = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:0], nil];
        [self.openSections setValue:tmpMutableArray forKey:[[self.myAccountManager.selectedMall.details allKeys] objectAtIndex:i]];
    }
    [self.myTableView reloadData];
    self.maxTableHeight = self.myTableView.frame.size.height;
    [self adjustTableHeightWithAnimation:NO];
    
    //nav bar
    [[self.navigationController navigationBar] setBarTintColor:[UIColor colorWithRed:(float)239/255 green:(float)118/255 blue:(float)37/255 alpha:1]];
    self.navigationController.navigationBar.translucent = NO;
    [[self navigationItem] setTitleView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iPhone_topLogo.png"]]];
}

- (IBAction)segmentedControlDidChange:(id)sender
{
    self.tableDictionary = [self.myAccountManager.selectedMall.details valueForKey:[[self.myAccountManager.selectedMall.details allKeys] objectAtIndex:[self.mySegmentedControl selectedSegmentIndex]]];
    [self.myTableView reloadData];
    [self adjustTableHeightWithAnimation:YES];
    //[self performSelector:@selector(adjustTableHeightWithAnimation:) withObject:NO afterDelay:0];
}

- (void) adjustTableHeightWithAnimation:(BOOL)animation
{
    int tableHeight = 0;
    for ( int i = 0; i < [[self.tableDictionary allKeys] count]; i++ )
    {
        tableHeight += 64;
        if ( [[self.openSections valueForKey:[[self.openSections allKeys] objectAtIndex:self.mySegmentedControl.selectedSegmentIndex]] containsObject:[NSNumber numberWithInt:i]] )
        {
            tableHeight += [[[self.tableDictionary valueForKey:[[self.tableDictionary allKeys] objectAtIndex:i]] allKeys] count] * 44;
        }
    }
    
    if ( tableHeight > self.maxTableHeight )
        tableHeight = self.maxTableHeight;
    
    if ( animation )
    {
        [UIView animateWithDuration:.3 animations:^
         {
             self.myTableView.frame = CGRectMake(self.myTableView.frame.origin.x, self.myTableView.frame.origin.y, self.myTableView.frame.size.width, tableHeight);
         }];
    }
    else
        self.myTableView.frame = CGRectMake(self.myTableView.frame.origin.x, self.myTableView.frame.origin.y, self.myTableView.frame.size.width, tableHeight);
}

- (IBAction)headerAction:(id)sender
{
    UIImageView * plusMinus;
    for ( UIView * tmpView in [[sender superview] subviews] )
    {
        if ( [tmpView class] == [UIImageView class] )
        {
            plusMinus = (UIImageView *)tmpView;
            break;
        }
    }
    
    NSMutableArray * indexArray = [[NSMutableArray alloc] init];
    for ( int i = 0; i < [[[self.tableDictionary valueForKey:[[self.tableDictionary allKeys] objectAtIndex:[sender tag]]] allKeys] count]; i++ )
        [indexArray addObject:[NSIndexPath indexPathForRow:i inSection:[sender tag]]];
    
    NSMutableArray * openSectionArray = [self.openSections valueForKey:[[self.openSections allKeys] objectAtIndex:self.mySegmentedControl.selectedSegmentIndex]];
    if ( [openSectionArray containsObject:[NSNumber numberWithInt:(int)[(UIButton *)sender tag]]] )
    {
        [openSectionArray removeObject:[NSNumber numberWithInt:(int)[(UIButton *)sender tag]]];
        [self.myTableView deleteRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationFade];
        
        [UIView animateWithDuration:.19 animations:^
        {
             plusMinus.alpha = .2;
        }
        completion:^(BOOL finished)
        {
            plusMinus.image = [UIImage imageNamed:@"iPhone_plusCircle"];
            [UIView animateWithDuration:.19 animations:^
            {
                plusMinus.alpha = 1;
            }];
        }];
    }
    else
    {
        [openSectionArray addObject:[NSNumber numberWithInt:(int)[(UIButton *)sender tag]]];
        [self.myTableView insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationFade];
        
        [UIView animateWithDuration:.19 animations:^
        {
            plusMinus.alpha = .2;
        }
        completion:^(BOOL finished)
        {
            plusMinus.image = [UIImage imageNamed:@"iPhone_minusCircle"];
            [UIView animateWithDuration:.19 animations:^
            {
                plusMinus.alpha = 1;
            }];
        }];
    }
    
    [self adjustTableHeightWithAnimation:YES];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.tableDictionary allKeys] count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 64;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    AccountHeaderCell * sectionHeaderView = [tableView dequeueReusableCellWithIdentifier:@"headerCell"];
    
    if ( [[self.openSections valueForKey:[[self.openSections allKeys] objectAtIndex:self.mySegmentedControl.selectedSegmentIndex]] containsObject:[NSNumber numberWithInt:(int)section]] )
        sectionHeaderView.plusMinusImageView.image = [UIImage imageNamed:@"iPhone_minusCircle.png"];
    else
        sectionHeaderView.plusMinusImageView.image = [UIImage imageNamed:@"iPhone_plusCircle.png"];
    
    sectionHeaderView.headerLabel.text = [[self.tableDictionary allKeys] objectAtIndex:section];
    
    while ( [sectionHeaderView.contentView.gestureRecognizers count] )
        [sectionHeaderView.contentView removeGestureRecognizer:[sectionHeaderView.contentView.gestureRecognizers firstObject]];
    
    sectionHeaderView.myButton.tag = section;
    
    return sectionHeaderView.contentView;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( [[self.openSections valueForKey:[[self.openSections allKeys] objectAtIndex:self.mySegmentedControl.selectedSegmentIndex]] containsObject:[NSNumber numberWithInt:(int)section]] )
        return [[[self.tableDictionary valueForKey:[[self.tableDictionary allKeys] objectAtIndex:section]] allKeys] count];
    else
        return 0;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44; //this gets rid of the compiler warning:
    //Warning once only: "Detected a case where constraints ambiguously suggest a height of zero for a tableview cell's content view. We're considering the collapse unintentional and using standard height instead."
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AccountDetailCell * cell = [tableView dequeueReusableCellWithIdentifier:@"detailCell"];
    
    NSDictionary * sectionDictionary = [self.tableDictionary valueForKey:[[self.tableDictionary allKeys] objectAtIndex:indexPath.section]];
    cell.detailLabel.text = [[sectionDictionary allKeys] objectAtIndex:indexPath.row];
    cell.detailTextField.text = [sectionDictionary valueForKey:cell.detailLabel.text];
    
    return cell;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    if ( [[self.openSections valueForKey:[[self.openSections allKeys] objectAtIndex:self.mySegmentedControl.selectedSegmentIndex]] containsObject:[NSNumber numberWithInt:(int)section]] )
//    return 1;
//    
//    return 0;
//}

- (IBAction)backButtonAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)logoutAction:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"Logout"
                                message:@"Are you sure you want to logout?"
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:^
                                        {
                                            //handle cancel
                                        }]
                       otherButtonItems:[RIButtonItem itemWithLabel:@"Yes" action:^
                                        {
                                            [self.navigationController popToRootViewControllerAnimated:YES];
                                        }], nil] show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
