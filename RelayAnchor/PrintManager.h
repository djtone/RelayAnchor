//
//  PrintManager.h
//  RelayAnchor
//
//  Created by chuck johnston on 2/27/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Order.h"

@interface PrintManager : NSObject <UIWebViewDelegate>

+ (PrintManager *)sharedPrintManager;

@property NSString * defaultPrinterId;
@property UIPrinterPickerController * myPrinterPicker;
@property UIPrintInteractionController * myPrintInteractionController;
@property NSDateFormatter * myDateFormatter;
@property UIWebView * myWebView;

- (void) presentFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated completionHandler:(UIPrinterPickerCompletionHandler)callBack;
- (void) printReceiptForOrder:(Order *)order fromView:(UIView *)view completion:(void(^)(BOOL success, NSString * error))callBack;
- (void) webViewForReceiptOrder:(Order *)order completion:(void(^)(UIWebView * webView))callBack;

@end
