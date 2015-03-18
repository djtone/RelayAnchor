//
//  ReceiptView.h
//  RelayAnchor
//
//  Created by chuck on 9/12/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ReceiptViewDelegate;


@interface ReceiptView : UIView

@property id <ReceiptViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *receiptImageView;

- (IBAction)cancelAction:(id)sender;
- (IBAction)uploadAction:(id)sender;

@end


@protocol ReceiptViewDelegate <NSObject>

- (void) didPressUpload:(ReceiptView *)receiptView;
- (void) didPressCancel:(ReceiptView *)receiptView;
- (void) didPressImage:(ReceiptView *)receiptView;

@end