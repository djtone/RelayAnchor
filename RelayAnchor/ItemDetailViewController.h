//
//  ItemDetailViewController.h
//  RelayAnchor
//
//  Created by chuck on 8/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TopView.h"
#import "BottomView.h"
#import "Product.h"
#import "OrderManager.h"
#import "ContactView.h"
#import "ReceiptView.h"
#import "EmailView.h"

@interface ItemDetailViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, TopViewDelegate, BottomViewDelegate, OrderManagerDelegate, ContactViewDelegate, ReceiptViewDelegate, EmailViewDelegate>

@property OrderManager * myOrderManager;
@property Product * myProduct;
@property NSTimer * refreshTimer;

@property TopView * myTopView;
@property BottomView * myBottomView;
@property ContactView * myContactView;
@property UIView * contactViewAlphaOverlay;
@property ReceiptView * purchaseReceiptView;
@property UIView * purchaseReceiptAlphaOverlay;
@property ReceiptView * returnReceiptView;
@property UIView * returnReceiptAlphaOverlay;
@property EmailView * myEmailView;
@property UIView * emailViewAlphaOverlay;

@property (weak, nonatomic) IBOutlet UILabel *orderIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imagePlaceholder;
@property (weak, nonatomic) IBOutlet UILabel *colorLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *storeNameLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *commentsTitleLabel;
@property (weak, nonatomic) IBOutlet UITextView *commentsTextView;

@property (weak, nonatomic) IBOutlet UIImageView *purchaseReceiptImageView;
@property (weak, nonatomic) IBOutlet UIView *returnReceiptStuff;
@property (weak, nonatomic) IBOutlet UIImageView *returnReceiptImageView;
@property BOOL isPurchaseReceipt; //used for the camera delegate function

@property (weak, nonatomic) IBOutlet UILabel *runnerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *runnerPhoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *runnerAddressLabel;

@property (weak, nonatomic) IBOutlet UILabel *buyerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyerPhoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyerAddressLabel;

@property (weak, nonatomic) IBOutlet UIView *contactRunnerTapView;
@property (weak, nonatomic) IBOutlet UIView *contactMemberTapView;

@property (weak, nonatomic) IBOutlet UIImageView *statusOrderedCheckMark;
@property (weak, nonatomic) IBOutlet UIImageView *statusPickUpCheckMark;
@property (weak, nonatomic) IBOutlet UIImageView *statusAtStationCheckMark;
@property (weak, nonatomic) IBOutlet UIImageView *statusDeliveredCheckMark;

//@property (weak, nonatomic) IBOutlet UIButton *statusIssueButton;
@property (weak, nonatomic) IBOutlet UIButton *statusIssueCancelButton;
- (IBAction)statusIssueCancelButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *statusIssueCancelView;
@property (weak, nonatomic) IBOutlet UITextView *statusIssueCancelTextView;

@property (weak, nonatomic) IBOutlet UIButton *statusIssueSubstituteButton;
- (IBAction)statusIssueSubstituteButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *statusIssueSubstituteView;
@property (weak, nonatomic) IBOutlet UITextView *statusIssueSubstituteTextView;

@property (weak, nonatomic) IBOutlet UIButton *statusIssueReturnButton;
- (IBAction)statusIssueReturnButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *statusIssueReturnView;
@property (weak, nonatomic) IBOutlet UITextView *statusIssueReturnTextView;

@property (weak, nonatomic) IBOutlet UIButton *atStationButton;
- (IBAction)atStationAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *deliveredButton;
@property (weak, nonatomic) IBOutlet UIButton *returnedByCustomerButton;
@property (weak, nonatomic) IBOutlet UIButton *returnApprovedButton;
@property (weak, nonatomic) IBOutlet UIButton *returnRejectedButton;
- (IBAction)deliveredAction:(id)sender;
- (IBAction)returnedByCustomerAction:(id)sender;
- (IBAction)returnApprovedAction:(id)sender;
- (IBAction)returnRejectedAction:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *deliveryItemLabel;

@property int tmpOrderNumber;

@property BOOL shouldSetStatusToAtStation;

//camera
- (void) didFinishTakingPicture:(UIImage *)tmpImage;

@end
