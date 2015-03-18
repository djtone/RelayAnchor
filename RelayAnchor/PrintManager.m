//
//  PrintManager.m
//  RelayAnchor
//
//  Created by chuck johnston on 2/27/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "PrintManager.h"
#import "OrderManager.h"
#import "UIPrintPageRenderer+PDFdata.h"

#define kPaperSizeA4 CGSizeMake(595.2,841.8)

@implementation PrintManager

static PrintManager * sharedPrintManager = nil;

+ (PrintManager *)sharedPrintManager
{
    if ( sharedPrintManager == nil )
    {
        sharedPrintManager = [[PrintManager alloc] init];
        sharedPrintManager.myPrinterPicker = [UIPrinterPickerController printerPickerControllerWithInitiallySelectedPrinter:nil];
        sharedPrintManager.myPrinterPicker.delegate = (id<UIPrinterPickerControllerDelegate>)self;
        sharedPrintManager.myPrintInteractionController = [UIPrintInteractionController sharedPrintController];
        sharedPrintManager.myDateFormatter = [[NSDateFormatter alloc] init];
        [sharedPrintManager.myDateFormatter setDateStyle:NSDateFormatterShortStyle];
        sharedPrintManager.myWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 900, 700)]; //i dont think this size makes a difference
        
        [sharedPrintManager.myWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Packslip-wideroption" ofType:@"html"]]]];
    }
    return sharedPrintManager;
}

- (void) presentFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated completionHandler:(UIPrinterPickerCompletionHandler)callBack
{
    [self.myPrinterPicker presentFromRect:rect inView:view animated:animated completionHandler:callBack];
}

- (void) printReceiptForOrder:(Order *)order fromView:(UIView *)view completion:(void (^)(BOOL))callBack
{
    if ( ( [[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] == NSOrderedAscending ) )
    {
        if ( ! view )
        {
            NSLog(@"must provide view if iOS is not 8.0 or later" );
            if ( callBack )
                callBack(NO);
            return;
        }
        
        //self.myPrintInteractionController.printInfo.printerID = self.defaultPrinterId;
    }
    else if ( ! self.myPrinterPicker.selectedPrinter )
    {
        NSLog(@"no printer selected - printer must be selected in iOS 8 and later");
        if ( callBack )
            callBack(NO);
        return;
    }
    
    //if the details are not loaded. load them. then call this print method again
    if ( ! order.hasLoadedDetails )
    {
        [[OrderManager sharedInstance] loadOrderDetailsForOrder:order completion:^(Order *loadedOrder)
        {
            [self printReceiptForOrder:order fromView:view completion:callBack];
        }];
        return;
    }
    else
        [self configureWebViewForOrder:order];
    
    /*
    UIPrintPageRenderer * renderer = [[UIPrintPageRenderer alloc] init];
    [renderer addPrintFormatter:[self.myWebView viewPrintFormatter] startingAtPageAtIndex:0];
    float topPadding = 10.0f;
    float bottomPadding = 10.0f;
    float leftPadding = 15.0f;
    float rightPadding = 15.0f;
    CGRect printableRect = CGRectMake(leftPadding,
                                      topPadding,
                                      kPaperSizeA4.width-leftPadding-rightPadding,
                                      kPaperSizeA4.height-topPadding-bottomPadding);
    CGRect paperRect = CGRectMake(0, 37, kPaperSizeA4.width, kPaperSizeA4.height);
    [renderer setValue:[NSValue valueWithCGRect:paperRect] forKey:@"paperRect"];
    [renderer setValue:[NSValue valueWithCGRect:printableRect] forKey:@"printableRect"];
    NSData *pdfData = [renderer printToPDF];
    */

    //self.myPrintInteractionController.printingItem = pdfData;
    self.myPrintInteractionController.printFormatter = [self.myWebView viewPrintFormatter];
    self.myPrintInteractionController.showsNumberOfCopies = NO;
    self.myPrintInteractionController.showsPageRange = NO;
     
    
    NSString *html = [self.myWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
    NSLog(@"html code: \n%@", html);
    
    if ( view )
    {
        [self.myPrintInteractionController presentFromRect:CGRectMake(view.frame.size.width/2, view.frame.size.height/2, 0, 0) inView:view animated:YES completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error)
        {
            if ( callBack )
            {
                if ( completed )
                    callBack(YES);
                else
                    callBack(NO);
            }
        }];
    }
    else
    {
        [self.myPrintInteractionController printToPrinter:self.myPrinterPicker.selectedPrinter completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error)
        {
            //do i need to get the main thread?
            if ( callBack )
            {
                if ( completed )
                    callBack(YES);
                else
                    callBack(NO);
            }
        }];
    }
}


- (void) webViewForReceiptOrder:(Order *)order completion:(void (^)(UIWebView *))callBack
{
    //if the details are not loaded. load them. then call this method again
    if ( ! order.hasLoadedDetails )
    {
        [[OrderManager sharedInstance] loadOrderDetailsForOrder:order completion:^(Order *loadedOrder)
        {
            [self webViewForReceiptOrder:order completion:callBack];
        }];
        return;
    }
    else
        [self configureWebViewForOrder:order];
        
    if ( callBack )
    {
        NSString *html = [self.myWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
        NSLog(@"html code: \n%@", html);
        callBack(self.myWebView);
    }
    else
        callBack(nil);
}


- (UIWebView *) configureWebViewForOrder:(Order *)order
{
    NSDateFormatter * tmpDateFormatter = [[NSDateFormatter alloc] init];
    [tmpDateFormatter setDateStyle:NSDateFormatterLongStyle];
    __block NSString * javaScriptString = @"document.getElementById('orderId').innerHTML = \"Order #%i\";\
    document.getElementById('name').innerHTML = \"%@ %@\";\
    document.getElementById('address').innerHTML = \"%@\";\
    document.getElementById('phone').innerHTML = \"%@\";\
    document.getElementById('purchaseDate').innerHTML = \"%@\";\
    document.getElementById('mallName').innerHTML = \"%@\";\
    document.getElementById('itemList').innerHTML = \"\";";
    
    NSString * phoneString;
    if ( [order.buyerPhoneNumber intValue] == 0 )
        phoneString = @"N/A";
    
    javaScriptString = [NSString stringWithFormat:javaScriptString,
                        [order.orderId intValue],
                        order.buyerFirstName, order.buyerLastName,
                        @"N/A",
                        phoneString,
                        [tmpDateFormatter stringFromDate:order.placeTime],
                        @"Oakbrook Mall"];
    
    //the fulfillment and thank you message are product-specific, therefore must be set after the order details have been loaded
    //the 'fulfillment' option is actually an item-specific attribute. i am just setting it to whatever the first item is
    NSString * fulfillment;
    if ( [[order.products firstObject] isDeliveryItem] )
        fulfillment = @"document.getElementById('fulfillment').innerHTML = 'delivery';\
        document.getElementById('fulfillmentImage').src = 'fulfillmentDelivery.png';";
    else
        fulfillment = @"document.getElementById('fulfillment').innerHTML = 'pick-up';\
        document.getElementById('fulfillmentImage').src = 'fulfillmentPickUp.png';";
    
    //the runner is actually an item-specific attribute. i am just setting the runner name to the whatever the first item is
    NSString * thankYouMessage = [NSString stringWithFormat:@"document.getElementById('thankYouMessage').innerHTML = \"Hi %@, <br /><br />Thank you for your business.  It is a pleasure to serve you!<br /><br />Thanks,<br />%@ %@<br />SYW Relay Runner<br />\";", order.buyerFirstName, [[order.products firstObject] runnerFirstName], [[order.products firstObject] runnerLastName]];
    
    javaScriptString = [NSString stringWithFormat:@"%@%@%@", javaScriptString, fulfillment, thankYouMessage];
    
    
    //product list
    for ( int i = 0; i < order.products.count; i++ )
    {
        Product * tmpProduct = [order.products objectAtIndex:i];
        NSString * tmpProductCell = [NSString stringWithFormat:@"var iDiv = document.createElement('div');\
                                     iDiv.className = \"row mb20\";\
                                     \
                                     var iDivSubA = document.createElement('div');\
                                     iDivSubA.className = \"col-md-6 col-xs-6 fs14 lightGray-2 textIndent-15\";\
                                     iDivSubA.innerHTML = \"%@\";\
                                     \
                                     var iDivSubA_1 = document.createElement('div');\
                                     iDivSubA_1.className = \"lightGray fs14 textIndent-0\";\
                                     iDivSubA_1.innerHTML = \"%@\";\
                                     \
                                     iDivSubA.appendChild(iDivSubA_1);\
                                     \
                                     var iDivSubB = document.createElement('div');\
                                     iDivSubB.className =\"col-md-3 col-xs-3 fs14 lightGray-2 text-right\";\
                                     iDivSubB.innerHTML = \"%@\";\
                                     \
                                     var iDivSubC = document.createElement('div');\
                                     iDivSubC.className = \"col-md-3 col-xs-3 fs14 fwb blackColors p0 text-right\";\
                                     iDivSubC.innerHTML = \"%@\";\
                                     \
                                     iDiv.appendChild(iDivSubA);\
                                     iDiv.appendChild(iDivSubB);\
                                     iDiv.appendChild(iDivSubC);\
                                     \
                                     var itemList = document.getElementById('itemList');\
                                     itemList.insertBefore(iDiv, document.getElementById('totals'));",
                                     
                                     [NSString stringWithFormat:@"%i. %@, Size: %@, Color: %@", i+1, [tmpProduct.name stringByReplacingOccurrencesOfString:@"\"" withString:@"\\""\""], tmpProduct.size, tmpProduct.color],
                                     tmpProduct.store,
                                     [NSString stringWithFormat:@"Qty: %@", tmpProduct.quantity],
                                     [NSString stringWithFormat:@"$%.2f", [tmpProduct.price floatValue]]];
        
        javaScriptString = [NSString stringWithFormat:@"%@%@", javaScriptString, tmpProductCell];
    }
    
    
    NSString * totals = [NSString stringWithFormat:@"var taxRow = document.createElement('div');\
                                                    taxRow.className = \"row\";\
                                                    \
                                                    var emptyTaxRow = document.createElement('div');\
                                                    emptyTaxRow.className = \"col-md-6 col-xs-6\";\
                                                    \
                                                    var taxRow1 = document.createElement('div');\
                                                    taxRow1.className = \"col-md-3 col-xs-3 fs14 lightGray-3 text-right\";\
                                                    taxRow1.innerHTML = \"Tax\";\
                                                    \
                                                    var taxRow2 = document.createElement('div');\
                                                    taxRow2.className = \"col-md-3 col-xs-3 fs14 lightGray-3 p0 text-right\";\
                                                    taxRow2.innerHTML = \"%@\";\
                                                    \
                                                    taxRow.appendChild(emptyTaxRow);\
                                                    taxRow.appendChild(taxRow1);\
                                                    taxRow.appendChild(taxRow2);\
                                                    \
                                                    \
                                                    var shippingRow = document.createElement('div');\
                                                    shippingRow.className = \"row\";\
                                                    \
                                                    var emptyShippingRow = document.createElement('div');\
                                                    emptyShippingRow.className = \"col-md-6 col-xs-6\";\
                                                    \
                                                    var shippingRow1 = document.createElement('div');\
                                                    shippingRow1.className = \"col-md-3 col-xs-3 fs14 lightGray-3 text-right\";\
                                                    shippingRow1.innerHTML = \"Shipping\";\
                                                    \
                                                    var shippingRow2 = document.createElement('div');\
                                                    shippingRow2.className = \"col-md-3 col-xs-3 fs14 lightGray-3 p0 text-right\";\
                                                    shippingRow2.innerHTML = \"%@\";\
                                                    \
                                                    shippingRow.appendChild(emptyShippingRow);\
                                                    shippingRow.appendChild(shippingRow1);\
                                                    shippingRow.appendChild(shippingRow2);\
                                                    \
                                                    \
                                                    var totalRow = document.createElement('div');\
                                                    totalRow.className = \"row\";\
                                                    \
                                                    var emptyTotalRow = document.createElement('div');\
                                                    emptyTotalRow.className = \"col-md-6 col-xs-6\";\
                                                    \
                                                    var totalRow1 = document.createElement('div');\
                                                    totalRow1.className = \"col-md-3 col-xs-3 fs14 lightGray-3 text-right\";\
                                                    totalRow1.innerHTML = \"Total\";\
                                                    \
                                                    var totalRow2 = document.createElement('div');\
                                                    totalRow2.className = \"col-md-3 col-xs-3 fs14 fwb blackColors p0 text-right\";\
                                                    totalRow2.innerHTML = \"%@\";\
                                                    \
                                                    totalRow.appendChild(emptyTotalRow);\
                                                    totalRow.appendChild(totalRow1);\
                                                    totalRow.appendChild(totalRow2);\
                                                    \
                                                    \
                                                    itemList.appendChild(taxRow);\
                                                    itemList.appendChild(shippingRow);\
                                                    itemList.appendChild(totalRow);",
                                                    [NSString stringWithFormat:@"$%.2f", [order.tax floatValue]],
                                                    [NSString stringWithFormat:@"$%.2f", [order.shippingCharges floatValue]],
                                                    [NSString stringWithFormat:@"$%.2f", [order.totalPrice floatValue]]];
    
    javaScriptString = [NSString stringWithFormat:@"%@%@", javaScriptString, totals];
    
    [self.myWebView stringByEvaluatingJavaScriptFromString:javaScriptString];
    return self.myWebView;
}

- (void) printerPickerControllerDidSelectPrinter:(UIPrinterPickerController *)printerPickerController
{
    self.defaultPrinterId = self.myPrintInteractionController.printInfo.printerID;
}

@end
