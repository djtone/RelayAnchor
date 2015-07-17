//
//  ReceiptPopup.h
//  RelayAnchor
//
//  Created by chuck johnston on 7/12/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ReceiptPopupDelegate <NSObject>
- (void) didPressCancel;
- (void) didPressUpload;
@end

@interface ReceiptPopup : UIView

@property id <ReceiptPopupDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIImageView *receiptImageView;
- (IBAction)cancelAction:(id)sender;
- (IBAction)uploadAction:(id)sender;

@end
