//
//  BottomView.h
//  RelayAnchor
//
//  Created by chuck on 8/11/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EnumTypes.h"

@protocol BottomViewDelegate <NSObject>
- (void) didChangeStatus:(BottomViewStatus)selectedStatus;
@end

@interface BottomView : UIView

@property (nonatomic, assign) id <BottomViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIImageView *triangleSelectionIcon;
@property (weak, nonatomic) IBOutlet UIButton *openButton;
@property (weak, nonatomic) IBOutlet UIButton *readyButton;
@property (weak, nonatomic) IBOutlet UIButton *deliveredButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelledReturnedButton;
@property BottomViewStatus selectedStatus;

- (void) resetButtons;

- (IBAction)openButtonAction:(id)sender;
- (IBAction)readyButtonAction:(id)sender;
- (IBAction)deliveredButtonAction:(id)sender;
- (IBAction)cancelledReturnedButtonAction:(id)sender;

@end
