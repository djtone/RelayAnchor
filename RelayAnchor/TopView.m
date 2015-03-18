//
//  TopView.m
//  RelayAnchor
//
//  Created by chuck on 8/9/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "TopView.h"

@implementation TopView

- (void) awakeFromNib
{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:@"UITextFieldTextDidChangeNotification" object:self.searchBarTextField];
    
    if ([self.searchBarTextField respondsToSelector:@selector(setAttributedPlaceholder:)])
        self.searchBarTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchBarTextField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    else
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    
    self.myOrderManager = [OrderManager sharedInstance];
    self.myPrintManager = [PrintManager sharedPrintManager];
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
        [self.printerButton setTitle:self.myPrintManager.myPrinterPicker.selectedPrinter.displayName forState:UIControlStateNormal];
    else
        [self.printerButton setTitle:@"No Printer Selected" forState:UIControlStateNormal];
    
    if ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] == NSOrderedAscending )
        self.printerButton.hidden = YES;
}

- (void)textFieldDidChange :(NSNotification *)notif
{
    if ( [self.delegate respondsToSelector:@selector(searchBarTextDidChange:)] )
        [self.delegate searchBarTextDidChange:[(UITextField *)notif.object text]];
}

- (IBAction)logoutAction:(id)sender
{
    if ( [self.delegate respondsToSelector:@selector(didPressLogout)] )
        [self.delegate didPressLogout];
}

//this method is required for the logout button - since it is outside the view bounds
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView* view in self.subviews)
    {
        if (view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }
    return NO;
}

- (IBAction)mallNameAction:(id)sender
{
    if ( self.logoutView.hidden )
        self.logoutView.hidden = NO;
    else
        self.logoutView.hidden = YES;
}

- (IBAction)backButtonAction:(id)sender
{
    if ( [self.delegate respondsToSelector:@selector(didPressBackButton)] )
        [self.delegate didPressBackButton];
}

- (IBAction)searchButtonAction:(id)sender
{
    [self.searchBarTextField becomeFirstResponder];
}

- (IBAction)alertButtonAction:(id)sender
{
    [self.delegate didPressAlertButton];
}

#pragma mark - printing
- (IBAction)printerAction:(id)sender
{
    [self.myPrintManager presentFromRect:[(UIButton *)sender frame] inView:self animated:YES completionHandler:^(UIPrinterPickerController *printerPickerController, BOOL userDidSelect, NSError *error)
    {
        if ( userDidSelect )
            [self.printerButton setTitle:self.myPrintManager.myPrinterPicker.selectedPrinter.displayName forState:UIControlStateNormal];
    }];
}
@end
