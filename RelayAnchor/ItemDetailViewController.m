//
//  ItemDetailViewController.m
//  RelayAnchor
//
//  Created by chuck on 8/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "ItemDetailViewController.h"
#import "OrdersViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "SVProgressHUD.h"
#import "UIAlertView+Blocks.h"
#import "OrderDetailViewController.h"
#import "MyCameraViewController.h"
#import "AccountManager.h"

@implementation ItemDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.myOrderManager = [OrderManager sharedInstanceWithDelegate:self];
    self.shouldSetStatusToAtStation = NO;
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(getOrderDetails) userInfo:nil repeats:YES];
    
    //ui stuff
    [self setNeedsStatusBarAppearanceUpdate];
    
    //receipt views
    self.purchaseReceiptView = [[[NSBundle mainBundle] loadNibNamed:@"ReceiptView" owner:self options:nil] firstObject];
    self.purchaseReceiptView.delegate = self;
    UITapGestureRecognizer * purchaseReceiptTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(presentPurchaseReceiptView)];
    [self.purchaseReceiptImageView addGestureRecognizer:purchaseReceiptTapGesture];
    self.purchaseReceiptAlphaOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 70, 1024, 618)];
    [self.purchaseReceiptAlphaOverlay setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:.5]];
    
    self.returnReceiptView = [[[NSBundle mainBundle] loadNibNamed:@"ReceiptView" owner:self options:nil] firstObject];
    self.returnReceiptView.delegate = self;
    UITapGestureRecognizer * returnReceiptTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(presentReturnReceiptView)];
    [self.returnReceiptImageView addGestureRecognizer:returnReceiptTapGesture];
    self.returnReceiptAlphaOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 70, 1024, 618)];
    [self.returnReceiptAlphaOverlay setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:.5]];
    
    //email
    self.myEmailView = [[[NSBundle mainBundle] loadNibNamed:@"EmailView" owner:self options:nil] firstObject];
    self.myEmailView.delegate = self;
    self.emailViewAlphaOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 70, 1024, 618)];
    [self.emailViewAlphaOverlay setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:.5]];
    
    //top view
    self.myTopView = [[[NSBundle mainBundle] loadNibNamed:@"TopView" owner:self options:nil] firstObject];
    self.myTopView.delegate = self;
    self.myTopView.searchView.hidden = YES;
    self.myTopView.searchSeparator.hidden = YES;
    self.myTopView.printerButton.hidden = YES;
    self.myTopView.keynoteOrdersButton.hidden = YES;
    self.myTopView.keynoteOrdersSwitch.hidden = YES;
    if ( self.tmpOrderNumber != -1 )
    {
        self.myTopView.orderNumberLabel.text = [NSString stringWithFormat:@"%i", self.tmpOrderNumber];
        self.tmpOrderNumber = -1;
    }
    [self.view addSubview:self.myTopView];
    
    //bottom view
    self.myBottomView = [[[NSBundle mainBundle] loadNibNamed:@"BottomView" owner:self options:nil] firstObject];
    self.myBottomView.delegate = self;
    [self.view addSubview:self.myBottomView];
    
    if ( ! [self.myProduct.productDescription isEqualToString:@""] )
        self.descriptionTextView.text = self.myProduct.productDescription;
    self.priceLabel.text = [NSString stringWithFormat:@"%.2f", [self.myProduct.price floatValue]];
    self.storeNameLabel.text = self.myProduct.store;
    if ( self.myProduct.isDeliveryItem )
        self.deliveryItemLabel.hidden = NO;
    if ( [self.myProduct.buyerComments isEqualToString:@""] )
    {
        self.commentsTitleLabel.hidden = YES;
        self.commentsTextView.hidden = YES;
    }
    else
        self.commentsTextView.text = self.myProduct.buyerComments;
    
    //contact views
    //this [runnerAddressLabel setText] should change. the login response should return the mall address. and the mall object should add an address property
    if ( [[[[AccountManager sharedInstance] selectedMall] name] isEqualToString:@"Oakbrook Mall"] )
        self.runnerAddressLabel.text = @"100 Oakbrook Center\nOak Brook, IL";
    else if ( [[[[AccountManager sharedInstance] selectedMall] name] isEqualToString:@"Water Tower Mall"] )
        self.runnerAddressLabel.text = @"835 N Michigan Ave\nChicago, IL";
        
    
    self.myContactView = [[[NSBundle mainBundle] loadNibNamed:@"ContactView" owner:self options:nil] firstObject];
    self.myContactView.delegate = self;
    self.contactViewAlphaOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 70, 1024, 618)];
    [self.contactViewAlphaOverlay setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:.5]];
    UITapGestureRecognizer * contactMemberTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(presentContactMember)];
    [self.contactMemberTapView addGestureRecognizer:contactMemberTap];
    UITapGestureRecognizer * contactRunnerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(presentContactRunner)];
    [self.contactRunnerTapView addGestureRecognizer:contactRunnerTap];
    
    //product details
    [self updateDetails];
}

#pragma mark - top view delegate
- (void) didPressLogout
{
    //[self] specific stuff
    //nothing to do here
    
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

- (void) didPressAlertButton
{
    [self.myBottomView openButtonAction:nil];
}

- (void) didPressBackButton
{
    [self.refreshTimer invalidate];
    OrderDetailViewController * orderDetailViewController = (OrderDetailViewController *)self.presentingViewController;
    [orderDetailViewController setRefreshTimer:[NSTimer scheduledTimerWithTimeInterval:10 target:orderDetailViewController selector:@selector(refreshDetails) userInfo:nil repeats:YES]];
    [orderDetailViewController myTopView].orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
    self.myOrderManager.delegate = orderDetailViewController;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) didChangeMall
{
    //go back to order page
    
    [self.refreshTimer invalidate];
    OrderDetailViewController * orderDetailViewController = (OrderDetailViewController *)self.presentingViewController;
    [orderDetailViewController.refreshTimer invalidate];
    OrdersViewController * ordersViewController = (OrdersViewController *)orderDetailViewController.presentingViewController;
    
    self.myOrderManager.delegate = ordersViewController;
    [ordersViewController myTopView].orderNumberLabel.text = self.myTopView.orderNumberLabel.text;
    [ordersViewController.myOrderManager startAutoRefreshOrdersWithStatus:[EnumTypes LoadOrderStatusFromBottomViewStatus:ordersViewController.myBottomView.selectedStatus] timeInterval:10];
    
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
    [orderDetailViewController.view addSubview:imageOverlay];
    [self dismissViewControllerAnimated:NO completion:nil];
    ordersViewController.ordersForTableView = @[];
    [ordersViewController refreshOrders];
    [ordersViewController dismissViewControllerAnimated:YES completion:^
    {
        [imageOverlay removeFromSuperview];
    }];
}

#pragma mark - bottom view delegate
- (void) didChangeStatus:(enum BottomViewStatus)selectedStatus
{
    [self.refreshTimer invalidate];
    UIViewController * modalToDismissFrom = self;
    while ( ! [[[modalToDismissFrom presentingViewController] restorationIdentifier] isEqualToString:@"homePage"] )
        modalToDismissFrom = [modalToDismissFrom presentingViewController];
    self.myOrderManager.delegate = (id<OrderManagerDelegate>)modalToDismissFrom;
    
    if ( selectedStatus == kBottomViewStatusOpen )
        [[(OrdersViewController *)modalToDismissFrom myBottomView] performSelector:@selector(openButtonAction:) withObject:self afterDelay:0];
    else if ( selectedStatus == kBottomViewStatusReady )
        [[(OrdersViewController *)modalToDismissFrom myBottomView] performSelector:@selector(readyButtonAction:) withObject:self afterDelay:0];
    else if ( selectedStatus == kBottomViewStatusDelivered )
        [[(OrdersViewController *)modalToDismissFrom myBottomView] performSelector:@selector(deliveredButtonAction:) withObject:self afterDelay:0];
    else if ( selectedStatus == kBottomViewStatusCancelledReturned )
        [[(OrdersViewController *)modalToDismissFrom myBottomView] performSelector:@selector(cancelledReturnedButtonAction:) withObject:self afterDelay:0];
    
    [modalToDismissFrom dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - contact view delegate
- (void) didPressText
{
    if ( [self.myContactView.phoneLabel.text isEqualToString:@"No Phone Provided"] )
        [SVProgressHUD showImage:nil status:@"No Number Provided"];
    else
    {
        [self dismissContactView];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"sms:%@",
            [[[[self.myContactView.phoneLabel.text stringByReplacingOccurrencesOfString:@" " withString:@""]
                                                   stringByReplacingOccurrencesOfString:@"-" withString:@""]
                                                   stringByReplacingOccurrencesOfString:@"(" withString:@""]
                                                   stringByReplacingOccurrencesOfString:@")" withString:@""]]]];
    }
}

- (void) didPressMail
{
    if ( [self.myContactView.emailAddress isEqualToString:@""] || [self.myContactView.emailAddress isEqualToString:@"0"] )
        [SVProgressHUD showImage:nil status:@"No Address Provided"];
    else
    {
        [self dismissContactView];
        
        self.myEmailView.emailLabel.text = self.myContactView.emailAddress;
        self.myEmailView.subjectTextField.text = [NSString stringWithFormat:@"Order Ready: #%@", self.myProduct.myOrder.wcsOrderId];
        self.myEmailView.bodyTextView.text = [NSString stringWithFormat:@"Dear %@ %@,\n\nYour item is now ready for pickup.\n\nRegards,\nSYW Relay Team\n------------------------------------\nOrder ID: %@\nItem ID: %@\nDescription: %@\nSize: %@\nColor: %@\nPrice: $%.2f\n\nRunner: %@ %@", self.myProduct.myOrder.buyerFirstName, self.myProduct.myOrder.buyerLastName, self.myProduct.myOrder.wcsOrderId, self.myProduct.productId, self.myProduct.productDescription, self.myProduct.size, self.myProduct.color, [self.myProduct.salePrice floatValue], self.myProduct.runnerFirstName, self.myProduct.runnerLastName];
        
        [self.view addSubview:self.emailViewAlphaOverlay];
        [self.view addSubview:self.myEmailView];
        
        [UIView animateWithDuration:.3 animations:^
        {
            [self.myEmailView.bodyTextView becomeFirstResponder];
            self.myEmailView.bodyTextView.selectedRange = NSMakeRange(0, 0);
        } completion:^(BOOL finished)
        {
            [self.myEmailView.bodyTextView flashScrollIndicators];
        }];
    }
}

- (void) didPressCloseWindow
{
    [self dismissContactView];
}

#pragma mark - contact member/runner
- (void) presentContactMember
{
    self.myContactView.titleLabel.text = @"Contact the Member";
    self.myContactView.nameLabel.text = [NSString stringWithFormat:@"%@ %@", self.myProduct.myOrder.buyerFirstName, self.myProduct.myOrder.buyerLastName];
    self.myContactView.emailAddress = self.myProduct.myOrder.buyerEmail;
    self.myContactView.addressLabel.text = [self.buyerAddressLabel.text stringByReplacingOccurrencesOfString:@"\n" withString:@", "];
    
    if ( [self.myProduct.myOrder.buyerPhoneNumber intValue] == 0 )
    {
        self.myContactView.phoneLabel.text = @"No Phone Provided";
        self.myContactView.phoneIcon.frame = CGRectMake(153, self.myContactView.phoneIcon.frame.origin.y, self.myContactView.phoneIcon.frame.size.width, self.myContactView.phoneIcon.frame.size.height);
    }
    else
    {
        NSString * phoneString = [NSString stringWithFormat:@"%@", self.myProduct.myOrder.buyerPhoneNumber];
        if ( [phoneString length] == 11 )
            self.myContactView.phoneLabel.text = [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringWithRange:NSMakeRange(1, 3)], [phoneString substringWithRange:NSMakeRange(4, 3)], [phoneString substringWithRange:NSMakeRange(7, 4)]];
        else if ( [phoneString length] == 10 )
            self.myContactView.phoneLabel.text = [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringWithRange:NSMakeRange(0, 3)], [phoneString substringWithRange:NSMakeRange(3, 3)], [phoneString substringWithRange:NSMakeRange(6, 4)]];
        else
            self.myContactView.phoneLabel.text = phoneString;
        
        self.myContactView.phoneIcon.frame = CGRectMake(170, self.myContactView.phoneIcon.frame.origin.y, self.myContactView.phoneIcon.frame.size.width, self.myContactView.phoneIcon.frame.size.height);
    }
    
    [self.view addSubview:self.contactViewAlphaOverlay];
    [self.view addSubview:self.myContactView];
}

- (void) presentContactRunner
{
    self.myContactView.titleLabel.text = @"Contact the Runner";
    
    NSString * runnerName = [NSString stringWithFormat:@"%@ %@", self.myProduct.runnerFirstName, self.myProduct.runnerLastName];
    if ( [[runnerName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0 )
        self.myContactView.nameLabel.text = @"No Name Provided";
    else
        self.myContactView.nameLabel.text = runnerName;
    
    self.myContactView.emailAddress = [NSString stringWithFormat:@"%@", self.myProduct.runnerId];
    self.myContactView.addressLabel.text = [self.runnerAddressLabel.text stringByReplacingOccurrencesOfString:@"\n" withString:@", "];
    
    if ( [self.myProduct.runnerPhoneNumber intValue] == 0 )
    {
        self.myContactView.phoneLabel.text = @"No Phone Provided";
        self.myContactView.phoneIcon.frame = CGRectMake(153, self.myContactView.phoneIcon.frame.origin.y, self.myContactView.phoneIcon.frame.size.width, self.myContactView.phoneIcon.frame.size.height);
    }
    else
    {
        NSString * phoneString = [NSString stringWithFormat:@"%@", self.myProduct.runnerPhoneNumber];
        if ( [phoneString length] == 11 )
            self.myContactView.phoneLabel.text = [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringWithRange:NSMakeRange(1, 3)], [phoneString substringWithRange:NSMakeRange(4, 3)], [phoneString substringWithRange:NSMakeRange(7, 4)]];
        else if ( [phoneString length] == 10 )
            self.myContactView.phoneLabel.text = [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringWithRange:NSMakeRange(0, 3)], [phoneString substringWithRange:NSMakeRange(3, 3)], [phoneString substringWithRange:NSMakeRange(6, 4)]];
        else
            self.myContactView.phoneLabel.text = phoneString;
        
        self.myContactView.phoneIcon.frame = CGRectMake(170, self.myContactView.phoneIcon.frame.origin.y, self.myContactView.phoneIcon.frame.size.width, self.myContactView.phoneIcon.frame.size.height);
    }
    
    [self.view addSubview:self.contactViewAlphaOverlay];
    [self.view addSubview:self.myContactView];
}

- (void) dismissContactView
{
    [self.contactViewAlphaOverlay removeFromSuperview];
    [self.myContactView removeFromSuperview];
}

#pragma mark - email delegate
- (void) didStartSendingEmail
{
    [SVProgressHUD show];
    //[self performSelector:@selector(showLoading) withObject:nil afterDelay:1];
}

- (void) showLoading
{
    [SVProgressHUD show];
}

- (void) didSendEmail
{
    [SVProgressHUD showSuccessWithStatus:@"Email Sent"];
    [self dismissEmailView];
}

- (void) didReceiveError
{
    [[[UIAlertView alloc] initWithTitle:@"Issue Sending Email"
                                message:@"There was an issue sending your email."
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:^
                                        {
                                            [self didCancelEmail];
                                        }]
                       otherButtonItems:[RIButtonItem itemWithLabel:@"Retry" action:^
                                        {
                                            [self.myEmailView sendAction:nil];
                                        }],nil] show];
}

- (void) didCancelEmail
{
    [self dismissEmailView];
}

- (void) dismissEmailView
{
    [self.emailViewAlphaOverlay removeFromSuperview];
    [self.myEmailView removeFromSuperview];
}

#pragma mark - receipt view delegate
- (void) didPressImage:(ReceiptView *)receiptView
{
    [self useCustomCamera];
}

- (void) didPressUpload:(ReceiptView *)receiptView
{
    NSString * receiptType = @"";
    if ( receiptView == self.purchaseReceiptView )
        receiptType = @"purchaseReceipt";
    else if ( receiptView == self.returnReceiptView )
        receiptType = @"returnReceipt";
    
    if ( self.myProduct.purchaseReceiptImage != nil )
    {
        [SVProgressHUD showWithStatus:@"Uploading Receipt"];
        UIImage * purchaseReceiptImage = [self.myOrderManager mergeReceiptImagesWithType:receiptType forOrder:self.myProduct.myOrder];
        self.myProduct.myOrder.purchaseReceiptImage = purchaseReceiptImage;
        
        [self.myOrderManager uploadReceiptImage:purchaseReceiptImage withType:receiptType forOrder:self.myProduct.myOrder];
    }
    else
        [SVProgressHUD showErrorWithStatus:@"No Receipt Image"];
}

- (void) didPressCancel:(ReceiptView *)receiptView
{
    if ( [self.myOrderManager isUploadingReceipt] )
    {
        [self.myOrderManager.receiptConnection cancel];
        [SVProgressHUD showErrorWithStatus:@"Upload Cancelled"];
    }
    
    [self dismissReceiptView:receiptView];
}

- (void) dismissReceiptView:(ReceiptView *)receiptView
{
    [receiptView removeFromSuperview];
    [self.purchaseReceiptAlphaOverlay removeFromSuperview];
    [self.returnReceiptAlphaOverlay removeFromSuperview];
}

- (void) presentPurchaseReceiptView
{
    self.isPurchaseReceipt = YES;
    [self.view addSubview:self.purchaseReceiptAlphaOverlay];
    [self.view addSubview:self.purchaseReceiptView];
}

- (void) presentReturnReceiptView
{
    self.isPurchaseReceipt = NO;
    [self.view addSubview:self.returnReceiptAlphaOverlay];
    [self.view addSubview:self.returnReceiptView];
}

#pragma mark - misc.
- (void) getOrderDetails
{
    if ( self.myOrderManager.isUpdatingOrder )
        return;
    
    [self.myOrderManager loadOrderDetailsForOrder:self.myProduct.myOrder completion:nil];
}

- (void)updateDetails
{
    //images
    if ( self.myProduct.productImage != nil )
        self.imagePlaceholder.image = self.myProduct.productImage;
    
    if ( self.myProduct.purchaseReceiptImage != nil )
    {
        self.purchaseReceiptImageView.image = self.myProduct.purchaseReceiptImage;
        self.purchaseReceiptView.receiptImageView.image = self.myProduct.purchaseReceiptImage;
    }
    
    if ( self.myProduct.returnReceiptImage != nil )
    {
        self.returnReceiptImageView.image = self.myProduct.returnReceiptImage;
        self.returnReceiptView.receiptImageView.image = self.myProduct.returnReceiptImage;
    }
    
    //title
    if ( ! [self.itemNameLabel.text isEqualToString:self.myProduct.name] )
        self.itemNameLabel.text = [NSString stringWithFormat:@"%@", self.myProduct.name];
    
    if ( ! [self.orderIdLabel.text isEqualToString:[NSString stringWithFormat:@"Order %@", self.myProduct.myOrder.wcsOrderId]] )
        self.orderIdLabel.text = [NSString stringWithFormat:@"Order %@", self.myProduct.myOrder.wcsOrderId];
    
    //product details
    if ( ! [self.colorLabel.text isEqualToString:self.myProduct.color] )
    {
        self.colorLabel.text = self.myProduct.color;
        if ( [self.myProduct.color length] == 0 )
            self.colorLabel.text = @"One Color";
    }
    
    if ( ! [self.sizeLabel.text isEqualToString:self.myProduct.size] )
    {
        self.sizeLabel.text = self.myProduct.size;
        if ( [self.myProduct.size length] == 0 )
            self.sizeLabel.text = @"One Size";
    }
    
    if ( ! [self.priceLabel.text isEqualToString:[NSString stringWithFormat:@"%.2f", [self.myProduct.price floatValue]]] )
        self.priceLabel.text = [NSString stringWithFormat:@"%.2f", [self.myProduct.price floatValue]];
    
    if ( ! [self.storeNameLabel.text isEqualToString:self.myProduct.store] )
        self.storeNameLabel.text = self.myProduct.store;
    
    //status bar
    //-check marks
    if ( [self.myProduct.runnerStatus isEqualToString:@"Picked Up"] || [self.myProduct.runnerStatus isEqualToString:@"At Station"] || [self.myProduct.anchorStatus isEqualToString:@"Delivered"] )
        self.statusPickUpCheckMark.hidden = NO;
    if ( [self.myProduct.anchorStatus isEqualToString:@"At Station"] || [self.myProduct.anchorStatus isEqualToString:@"Delivered"] || [self.myProduct.anchorStatus isEqualToString:@"Return Initiated"] )
        self.statusAtStationCheckMark.hidden = NO;
    if ( [self.myProduct.anchorStatus isEqualToString:@"Delivered"] || [self.myProduct.anchorStatus isEqualToString:@"Return Initiated"] )
        self.statusDeliveredCheckMark.hidden = NO;
    //-buttons
    self.atStationButton.hidden = YES;
    self.deliveredButton.hidden = YES;
    if ( [self.myProduct.runnerStatus isEqualToString:@"At Station"] && ! [self.myProduct.anchorStatus isEqualToString:@"At Station"] && ! [self.myProduct.anchorStatus isEqualToString:@"Delivered"] && ! [self.myProduct.anchorStatus isEqualToString:@"Return Initiated"] )
        self.atStationButton.hidden = NO;
    else if ( [self.myProduct.anchorStatus isEqualToString:@"At Station"] )
        self.deliveredButton.hidden = NO;
    //-issue icons
    if ( [self.myProduct.status isEqualToString:@"Cancelled"] )
    {
        self.statusIssueCancelButton.hidden = NO;
        if ( [self.myProduct.anchorStatus isEqualToString:@"Return Initiated"]  )
            self.statusIssueReturnTextView.text = @"Customer is returning item.";
    }
    else if ( self.myProduct.isSubstitute )
        self.statusIssueSubstituteButton.hidden = NO;
    
    if ( self.myProduct.isReturn )
    {
        self.returnReceiptStuff.hidden = NO;
        
        if ( [self.myProduct.anchorStatus isEqualToString:@"Return Initiated"]  )
            self.returnedByCustomerButton.hidden = NO;
    }
    
    //contact member/runner
    NSString * buyerAddressString = [NSString stringWithFormat:@"%@\n%@, %@", self.myProduct.buyerAddress, self.myProduct.buyerCity, self.myProduct.buyerState];
    if ( ! [self.buyerAddressLabel.text isEqualToString:buyerAddressString] )
        self.buyerAddressLabel.text = buyerAddressString;
    
    NSString * runnerNameString;
    if ( [self.myProduct.runnerFirstName length] + [self.myProduct.runnerLastName length] == 0 )
        runnerNameString = @"No Name Provided";
    else
        runnerNameString = [NSString stringWithFormat:@"%@ %@", self.myProduct.runnerFirstName, self.myProduct.runnerLastName];
    if ( ! [self.runnerNameLabel.text isEqualToString:runnerNameString] )
        self.runnerNameLabel.text = runnerNameString;
    
    NSString * runnerPhoneString;
    if ( [self.myProduct.runnerPhoneNumber intValue] == 0 )
        runnerPhoneString = @"No Phone Provided";
    else
    {
        runnerPhoneString = [NSString stringWithFormat:@"%@", self.myProduct.runnerPhoneNumber];
        if ( [runnerPhoneString length] == 11 )
            runnerPhoneString = [NSString stringWithFormat:@"(%@) %@-%@", [runnerPhoneString substringWithRange:NSMakeRange(1, 3)], [runnerPhoneString substringWithRange:NSMakeRange(4, 3)], [runnerPhoneString substringWithRange:NSMakeRange(7, 4)]];
        else if ( [runnerPhoneString length] == 10 )
            runnerPhoneString = [NSString stringWithFormat:@"(%@) %@-%@", [runnerPhoneString substringWithRange:NSMakeRange(0, 3)], [runnerPhoneString substringWithRange:NSMakeRange(3, 3)], [runnerPhoneString substringWithRange:NSMakeRange(6, 4)]];
    }
    if ( ! [self.runnerPhoneLabel.text isEqualToString:runnerPhoneString] )
        self.runnerPhoneLabel.text = runnerPhoneString;
    
    NSString * buyerNameString;
    if ( [self.myProduct.myOrder.buyerFirstName length] + [self.myProduct.myOrder.buyerLastName length] == 0 )
        buyerNameString = @"No Name Provided";
    else
        buyerNameString = [NSString stringWithFormat:@"%@ %@", self.myProduct.myOrder.buyerFirstName, self.myProduct.myOrder.buyerLastName];
    if ( ! [self.buyerNameLabel.text isEqualToString:buyerNameString] )
        self.buyerNameLabel.text = buyerNameString;
    
    //self.buyerFulfillmentLabel.text = //this should change based on delivery or pickup
    
    NSString * phoneString; //should use [DataMethods FormattedPhoneNumber] instead
    if ( [self.myProduct.myOrder.buyerPhoneNumber intValue] == 0 && [self.myProduct.myOrder.deliveryPhoneNumber intValue] == 0 )
        phoneString = @"No Phone Provided";
    else
    {
        if ( [self.myProduct.myOrder.deliveryPhoneNumber intValue] != 0 && self.myProduct.isDeliveryItem )
            phoneString = [NSString stringWithFormat:@"%@", self.myProduct.myOrder.deliveryPhoneNumber];
        else
            phoneString = [NSString stringWithFormat:@"%@", self.myProduct.myOrder.buyerPhoneNumber];
            
        if ( [phoneString length] == 11 )
            phoneString = [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringWithRange:NSMakeRange(1, 3)], [phoneString substringWithRange:NSMakeRange(4, 3)], [phoneString substringWithRange:NSMakeRange(7, 4)]];
        else if ( [phoneString length] == 10 )
            phoneString = [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringWithRange:NSMakeRange(0, 3)], [phoneString substringWithRange:NSMakeRange(3, 3)], [phoneString substringWithRange:NSMakeRange(6, 4)]];
    }
    if ( ! [self.buyerPhoneLabel.text isEqualToString:phoneString] )
        self.buyerPhoneLabel.text = phoneString;
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

#pragma mark - status bar
- (IBAction)statusIssueCancelButtonAction:(id)sender
{
    if ( self.statusIssueCancelView.hidden )
    {
        self.statusIssueCancelView.alpha = 0;
        self.statusIssueCancelView.hidden = NO;
        [UIView animateWithDuration:.2 animations:^
        {
            self.statusIssueCancelView.alpha = 1;
        }];
    }
    else
    {
        [UIView animateWithDuration:.2 animations:^
        {
            self.statusIssueCancelView.alpha = 0;
        }
        completion:^(BOOL finished)
        {
            self.statusIssueCancelView.hidden = YES;
            self.statusIssueCancelView.alpha = 1;
        }];
    }
}

- (IBAction)statusIssueSubstituteButtonAction:(id)sender
{
    if ( self.statusIssueSubstituteView.hidden )
    {
        self.statusIssueSubstituteView.alpha = 0;
        self.statusIssueSubstituteView.hidden = NO;
        [UIView animateWithDuration:.2 animations:^
        {
            self.statusIssueSubstituteView.alpha = 1;
        }];
    }
    else
    {
        [UIView animateWithDuration:.2 animations:^
        {
            self.statusIssueSubstituteView.alpha = 0;
        }
        completion:^(BOOL finished)
        {
            self.statusIssueSubstituteView.hidden = YES;
            self.statusIssueSubstituteView.alpha = 1;
        }];
    }
}

- (IBAction)statusIssueReturnButtonAction:(id)sender
{
    if ( self.statusIssueReturnView.hidden )
    {
        self.statusIssueReturnView.alpha = 0;
        self.statusIssueReturnView.hidden = NO;
        [UIView animateWithDuration:.2 animations:^
        {
            self.statusIssueReturnView.alpha = 1;
        }];
    }
    else
    {
        [UIView animateWithDuration:.2 animations:^
        {
            self.statusIssueReturnView.alpha = 0;
        }
        completion:^(BOOL finished)
        {
            self.statusIssueReturnView.hidden = YES;
            self.statusIssueReturnView.alpha = 1;
        }];
    }
}

- (IBAction)atStationAction:(id)sender
{
    self.isPurchaseReceipt = YES;
    //self.isPurchaseReceipt = NO;
    
    if ( self.myProduct.purchaseReceiptImage == nil )
        [self useCustomCamera];
    else
    {
        if ( [self.myOrderManager isLastProductToApprove:self.myProduct] )
        {
            self.shouldSetStatusToAtStation = YES;
            [SVProgressHUD showWithStatus:@"Uploading Receipt"];
            UIImage * purchaseReceiptImage = [self.myOrderManager mergeReceiptImagesWithType:@"purchase" forOrder:self.myProduct.myOrder];
            [self.myOrderManager uploadReceiptImage:purchaseReceiptImage withType:@"purchase" forOrder:self.myProduct.myOrder];
        }
        else
            [self setProductStatus:@"At Station"];
    }
}

- (IBAction)deliveredAction:(id)sender
{
    [self setProductStatus:@"Delivered"];
}

- (IBAction)returnedByCustomerAction:(id)sender
{
    [SVProgressHUD show];
    [self.myOrderManager confirmProductReturnByCustomer:self.myProduct completion:^(BOOL success)
    {
        if ( success )
        {
            [SVProgressHUD showSuccessWithStatus:@"Status Saved"];
            self.returnedByCustomerButton.hidden = YES;
            self.returnApprovedButton.hidden = NO;
            self.returnRejectedButton.hidden = NO;
        }
        else
            [SVProgressHUD showErrorWithStatus:@"Issue Saving Status"];
    }];
}

- (IBAction)returnApprovedAction:(id)sender
{
    if ( self.myProduct.returnReceiptImage == nil )
    {
        self.isPurchaseReceipt = NO;
        [self useCustomCamera];
    }
    else
    {
        [SVProgressHUD showWithStatus:@"Uploading Receipt"];
        self.isPurchaseReceipt = NO;
        UIImage * returnReceiptImage = [self.myOrderManager mergeReceiptImagesWithType:@"return" forOrder:self.myProduct.myOrder];
        [self.myOrderManager uploadReceiptImage:returnReceiptImage withType:@"return" forOrder:self.myProduct.myOrder];
    }
}

- (IBAction)returnRejectedAction:(id)sender
{
    [SVProgressHUD showWithStatus:@"Saving Status"];
    [self.myOrderManager confirmProductReturnRejected:self.myProduct completion:^(BOOL success)
    {
        if ( success )
        {
            [SVProgressHUD showSuccessWithStatus:@"Status Saved"];
        }
        else
            [SVProgressHUD showErrorWithStatus:@"Issue Saving Status"];
    }];
}

- (void) setProductStatus:(NSString *)status
{
    if ( [status isEqualToString:@"At Station"] )
    {
        [SVProgressHUD showWithStatus:@"Setting Status"];
        [self.myOrderManager confirmProductAtStation:self.myProduct completion:^(BOOL success)
        {
            if ( success )
            {
                [SVProgressHUD showSuccessWithStatus:@"Status Saved"];
                
                self.deliveredButton.alpha = 0;
                self.deliveredButton.hidden = NO;
                self.statusAtStationCheckMark.alpha = 0;
                self.statusAtStationCheckMark.hidden = NO;
                [UIView animateWithDuration:.3 animations:^
                {
                    self.atStationButton.alpha = 0;
                    self.deliveredButton.alpha = 1;
                    self.statusAtStationCheckMark.alpha = 1;
                }
                completion:^(BOOL finished)
                {
                    self.atStationButton.hidden = YES;
                    self.atStationButton.alpha = 1;
                }];
                
                //[[(OrderDetailViewController *)[self presentingViewController] OrderDetailTableView] reloadData];
                //im just calling this on the viewWillAppear method instead
            }
            else
                [SVProgressHUD showErrorWithStatus:@"Error Setting Status"];
        }];
        self.shouldSetStatusToAtStation = NO;
    }
    else if ( [status isEqualToString:@"Delivered"] )
    {
        if ( [self.myOrderManager allItemsAreAtStationForOrder:self.myProduct.myOrder] )
        {
            [SVProgressHUD showWithStatus:@"Setting Status"];
            [self.myOrderManager confirmDeliveryForOrder:self.myProduct.myOrder completion:^(BOOL success)
            {
                if ( success )
                {
                    [SVProgressHUD showSuccessWithStatus:@"Status Saved"];
                    
                    self.statusDeliveredCheckMark.alpha = 0;
                    self.statusDeliveredCheckMark.hidden = NO;
                    [UIView animateWithDuration:.3 animations:^
                    {
                        self.statusDeliveredCheckMark.alpha = 1;
                        self.deliveredButton.alpha = 0;
                    }
                    completion:^(BOOL finished)
                    {
                        self.deliveredButton.hidden = YES;
                        self.deliveredButton.alpha = 1;
                    }];
                    
                    [[(OrderDetailViewController *)[self presentingViewController] OrderDetailTableView] reloadData];
                }
                else
                    [SVProgressHUD showErrorWithStatus:@"Error Changing Status"];
            }];
        }
        else
            [SVProgressHUD showErrorWithStatus:@"All Items Must Be\nAtStation"];
    }
}

#pragma mark - receipt / camera
- (void) useCustomCamera
{
    UIStoryboard * myStoryboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    UIViewController * myCameraVC = [myStoryboard instantiateViewControllerWithIdentifier:@"myCameraViewController"];
    myCameraVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:myCameraVC animated:YES completion:nil];
}

- (void) useCamera:(id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.mediaTypes = @[(NSString *) kUTTypeImage];
        imagePicker.allowsEditing = NO;
        imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Camera failed to open"
                              message: @"Camera is not available"
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
}

//this is the old way. (not using the custom camera vew controller)
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:^
    {
        if ( self.isPurchaseReceipt )
        {
            self.myProduct.purchaseReceiptImage = [info objectForKey:UIImagePickerControllerOriginalImage];
            self.purchaseReceiptImageView.image = self.myProduct.purchaseReceiptImage;
            self.purchaseReceiptView.receiptImageView.image = self.myProduct.purchaseReceiptImage;
        }
        else
        {
            self.myProduct.returnReceiptImage = [info objectForKey:UIImagePickerControllerOriginalImage];
            self.returnReceiptImageView.image = self.myProduct.returnReceiptImage;
            self.returnReceiptView.receiptImageView.image = self.myProduct.returnReceiptImage;
        }
    }];
}

- (void) didFinishTakingPicture:(UIImage *)tmpImage
{
    if ( self.isPurchaseReceipt )
    {
        [UIView animateWithDuration:.2 animations:^
        {
            self.purchaseReceiptImageView.alpha = 0;
            self.purchaseReceiptView.receiptImageView.alpha = 0;
        }
        completion:^(BOOL finished)
        {
            self.myProduct.purchaseReceiptImage = tmpImage;
            self.purchaseReceiptImageView.image = self.myProduct.purchaseReceiptImage;
            self.purchaseReceiptView.receiptImageView.image = self.myProduct.purchaseReceiptImage;
            
            [UIView animateWithDuration:.2 animations:^
            {
                self.purchaseReceiptImageView.alpha = 1;
                self.purchaseReceiptView.receiptImageView.alpha = 1;
            }];
        }];
    }
    else
    {
        [UIView animateWithDuration:.2 animations:^
        {
            self.returnReceiptImageView.alpha = 0;
            self.returnReceiptView.receiptImageView.alpha = 0;
        }
        completion:^(BOOL finished)
        {
            self.myProduct.returnReceiptImage = tmpImage;
            self.returnReceiptImageView.image = self.myProduct.returnReceiptImage;
            self.returnReceiptView.receiptImageView.image = self.myProduct.returnReceiptImage;
             
            [UIView animateWithDuration:.2 animations:^
            {
                self.returnReceiptImageView.alpha = 1;
                self.returnReceiptView.receiptImageView.alpha = 1;
            }];
        }];
    }
}

#pragma mark - order manager delegate
- (void) didFinishLoadingOrderDetails:(Order *)order
{
    if ( [self.myOrderManager isUpdatingOrder] )
        return;
    
    for ( int i = 0; i < [order.products count]; i++ )
    {
        if ( [[(Product *)[order.products objectAtIndex:i] productId] isEqual:self.myProduct.productId] )
        {
            //retain receipts
            UIImage * purchaseReceiptImage = self.myProduct.purchaseReceiptImage;
            UIImage * returnReceiptImage = self.myProduct.returnReceiptImage;
            
            self.myProduct = (Product *)[order.products objectAtIndex:i];
            
            self.myProduct.purchaseReceiptImage = purchaseReceiptImage;
            self.myProduct.returnReceiptImage = returnReceiptImage;
            
            [self updateDetails];
            break;
        }
    }
}

- (void) didFinishLoadingImageType:(NSString *)type forProduct:(Product *)product
{
    if ( [product.productId isEqual:self.myProduct.productId] )
    {
        if ( [type isEqualToString:@"product"] )
        {
            self.myProduct.productImage = product.productImage;
            self.imagePlaceholder.image = self.myProduct.productImage;
        }
        else if ( [type isEqualToString:@"purchaseReceipt"] && product.purchaseReceiptImage )
        {
            self.myProduct.purchaseReceiptImage = product.purchaseReceiptImage;
            self.purchaseReceiptImageView.image = self.myProduct.purchaseReceiptImage;
            self.purchaseReceiptView.receiptImageView.image = self.myProduct.purchaseReceiptImage;
        }
        else if ( [type isEqualToString:@"returnReceipt"] && product.returnReceiptImage )
        {
            self.myProduct.returnReceiptImage = product.returnReceiptImage;
            self.returnReceiptImageView.image = self.myProduct.returnReceiptImage;
            self.returnReceiptView.receiptImageView.image = self.myProduct.returnReceiptImage;
        }
    }
}

- (void) didFinishLoadingOrders:(NSArray *)orders withStatusOpen:(BOOL)open ready:(BOOL)ready delivered:(BOOL)delivered cancelledReturned:(BOOL)cancelledReturned success:(BOOL)success
{
    // setting the top view bell thing number
    if ( open )
    {
        int numberOfOpenOrders = 0;
        for ( int i = 0; i < [orders count]; i++ )
        {
            if ( [(Order *)[orders objectAtIndex:i] status] == kStatusOpen )
                numberOfOpenOrders++;
        }
        self.myTopView.orderNumberLabel.text = [NSString stringWithFormat:@"%i", numberOfOpenOrders];
    }
}

- (void) didFinishUploadingReceipt:(NSURL *)receiptUrl
{
    if ( self.isPurchaseReceipt )
    {
        self.myProduct.myOrder.purchaseReceiptUrl = receiptUrl;
        self.myProduct.myOrder.purchaseReceiptImage = self.purchaseReceiptView.receiptImageView.image;
        for ( int i = 0; i < [self.myProduct.myOrder.products count]; i++ )
        {
            [(Product *)[self.myProduct.myOrder.products objectAtIndex:i] setPurchaseReceiptImage:self.purchaseReceiptView.receiptImageView.image];
            [(Product *)[self.myProduct.myOrder.products objectAtIndex:i] setPurchaseReceiptUrl:receiptUrl];
        }
        [SVProgressHUD showSuccessWithStatus:@"Receipt Saved"];
        [self dismissReceiptView:self.purchaseReceiptView];
        
        if ( self.shouldSetStatusToAtStation )
            [self setProductStatus:@"At Station"];
    }
    else
    {
        self.myProduct.myOrder.returnReceiptUrl = receiptUrl;
        self.myProduct.myOrder.returnReceiptImage = self.returnReceiptView.receiptImageView.image;
        for ( int i = 0; i < [self.myProduct.myOrder.products count]; i++ )
        {
            [(Product *)[self.myProduct.myOrder.products objectAtIndex:i] setReturnReceiptImage:self.returnReceiptView.receiptImageView.image];
            [(Product *)[self.myProduct.myOrder.products objectAtIndex:i] setReturnReceiptUrl:receiptUrl];
        }
        [SVProgressHUD showSuccessWithStatus:@"Receipt Saved"];
        [self dismissReceiptView:self.returnReceiptView];
    }
}

- (void) didFailUploadingReceipt:(NSString *)errorMessage
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: @"Receipt Upload Failed"
                          message: @"Receipt Upload Failed"
                          delegate: nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
}

- (void) didFinishPrintingReceiptForOrder:(Order *)order
{
    NSLog(@"receipt printed for order id : %@", order.wcsOrderId);
}

- (void) didFailPrintingReceiptForOrder:(Order *)order
{
    NSLog(@"failed printing receipt for order id : %@", order.wcsOrderId);
}

@end
