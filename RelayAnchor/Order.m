//
//  Order.m
//  RelayAnchor
//
//  Created by chuck on 8/13/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "Order.h"
#import "Product.h"
#import "DataMethods.h"
#import "OrderManager.h"

@implementation Order

- (id) initWithDictionary:(NSDictionary *)dictionaryResponse
{
    if ( self = [super init] )
    {
        self.hasLoadedDetails = NO;
        
        self.wcsOrderId = [NSNumber numberWithInt:[[DataMethods checkForNull:[dictionaryResponse valueForKey:@"wcsOrderId"] withAlternative:@"0"] intValue]];
        self.mysqlOrderId = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"mysqlOrderId"] withAlternative:[NSNumber numberWithInt:0]];
        self.totalPrice = [NSNumber numberWithFloat:[[DataMethods checkForNull:[dictionaryResponse valueForKey:@"totalOrderPrice"] withAlternative:@"0"] floatValue]];
        self.tax = [NSNumber numberWithFloat:[[DataMethods checkForNull:[dictionaryResponse valueForKey:@"tax"] withAlternative:@"0"] floatValue]];
        self.shippingCharges = [NSNumber numberWithFloat:[[DataMethods checkForNull:[dictionaryResponse valueForKey:@"shippingCharges"] withAlternative:@"0"] floatValue]];
        self.itemQuantity = [NSNumber numberWithInt:[[DataMethods checkForNull:[dictionaryResponse valueForKey:@"noOfOrderItems"] withAlternative:@"0"] intValue]];
        self.buyerFirstName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"firstName"] withAlternative:@""];
        self.buyerLastName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"lastName"] withAlternative:@""];
        self.runnerId = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerId"] withAlternative:[NSNumber numberWithInt:0]];
        self.runnerName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerName"] withAlternative:@""];
        self.anchorId = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"anchorId"] withAlternative:[NSNumber numberWithInt:0]];
        self.buyerEmail = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"buyerEmail"] withAlternative:@""];
        
        self.buyerPhoneNumber = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"buyerPhoneNumber"] withAlternative:[NSNumber numberWithDouble:0]];
        
        self.isKeynoteOrder = NO;
        if ( [[DataMethods checkForNull:[dictionaryResponse valueForKey:@"isKeynoteOrder"] withAlternative:nil] intValue] != 0 )
            self.isKeynoteOrder = YES;
        
        self.hasDeliveryItems = NO;
        if ( [[DataMethods checkForNull:[dictionaryResponse valueForKey:@"hasDelivItems"] withAlternative:nil] intValue] != 0 )
            self.hasDeliveryItems = YES;
        self.deliverySlot = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"deliverySlotText"] withAlternative:@""];
        self.pickupLocation = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"fulfillmentLabel"] withAlternative:@""];
        
        NSString * apiRunnerStatus = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerStatus"] withAlternative:@"Open"];
        if ( [apiRunnerStatus isEqualToString:@"RUNNING"] )
            self.runnerStatus = kRunnerStatusRunning;
        else if ( [apiRunnerStatus isEqualToString:@"PICKEDUPBYRUNNER"] )
            self.runnerStatus = kRunnerStatusPickedUp;
        else if ( [apiRunnerStatus isEqualToString:@"DROPPEDATANCHOR"] || [apiRunnerStatus isEqualToString:@"READY"] ) //READY means it was overridden
            self.runnerStatus = kRunnerStatusAtStation;
        else if ( [apiRunnerStatus isEqualToString:@"DELIVERED"] )
            self.runnerStatus = kRunnerStatusDelivered;
        
        NSString * apiAnchorStatus = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"anchorStatus"] withAlternative:@"Open"];
        if ( [apiAnchorStatus isEqualToString:@"RUNNING"] )
            self.anchorStatus = kAnchorStatusRunning;
        else if ( [apiAnchorStatus isEqualToString:@"PICKEDUPBYRUNNER"] )
            self.anchorStatus = kAnchorStatusPickedUp;
        else if ( [apiAnchorStatus isEqualToString:@"DROPPEDATANCHOR"] || [apiAnchorStatus isEqualToString:@"READY"] ) //READY means it was overridden
            self.anchorStatus = kAnchorStatusAtStation;
        else if ( [apiAnchorStatus isEqualToString:@"DELIVERED"] )
            self.anchorStatus = kAnchorStatusDelivered;
        else if ( [apiAnchorStatus isEqualToString:@"WAITITEMRETURNCUST"] )
            self.anchorStatus = kAnchorStatusReturnInitiated;
        
        self.placeTime = [NSDate dateWithTimeIntervalSince1970:[[NSNumber numberWithInt:[[DataMethods checkForNull:[dictionaryResponse valueForKey:@"orderPlaceTime"] withAlternative:[NSNumber numberWithInt:0]] floatValue] /1000] doubleValue]];
        
        NSString * apiStatus = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"orderStatus"] withAlternative:@""];
        if ( [apiStatus isEqualToString:@"SUBMITTED"] )
            self.status = kStatusOpen;
        else if ( [apiStatus isEqualToString:@"READY"] )
            self.status = kStatusAtStation;
        else if ( [apiStatus isEqualToString:@"DELIVERED"] )
            self.status = kStatusDelivered;
        else if ( [apiStatus isEqualToString:@"FULLORDERREFINIT"] )
            self.status = kStatusCancelled;
        else if ( [apiStatus isEqualToString:@"REFUNDED"] )
            self.status = kStatusReturned;
        else if ( [apiStatus isEqualToString:@"REFREJECTED"] )
            self.status = kStatusReturnRejected;
        
        /*
        if ( [DataMethods checkForNull:[dictionaryResponse valueForKey:@"orderItemReturnsBean"] withAlternative:nil] )
        {
         
        }
         */
        
        NSString * urlString = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"purchasedReceiptImg"] withAlternative:@""];
        self.purchaseReceiptUrl = [NSURL URLWithString:urlString];
        self.purchaseReceiptImage = nil;
        
        urlString = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"cancelledReceiptImg"] withAlternative:@""];
        self.returnReceiptUrl = [NSURL URLWithString:urlString];
        self.returnReceiptImage = nil;
        
        [self displayStatus]; //sets display color - ill change it eventually.. maybe

        self.isChangingStatus = NO;
    }
    return self;
}

- (void) fillOrderDetails:(NSDictionary *)dictionaryResponse
{
    self.totalPrice = [NSNumber numberWithFloat:[[DataMethods checkForNull:[dictionaryResponse valueForKey:@"totalOrderPrice"] withAlternative:@"0"] floatValue]];
    self.deliveryPhoneNumber = [NSNumber numberWithInt:[[DataMethods checkForNull:[dictionaryResponse valueForKey:@"fullfillmentPhoneNumber"] withAlternative:@"0"] intValue]];
//    NSDateFormatter * tmpDateFormatter = [[OrderManager sharedInstance] myDateFormatter];
//    [tmpDateFormatter setDateFormat:@""];
//    NSString * tmpDateString = [dictionaryResponse valueForKey:@"deliverySlot"];
//    if ( [tmpDateString class] != [NSNull class] )
//        self.deliveryDate = [tmpDateFormatter dateFromString:tmpDateString];
    
    NSMutableArray * tmpProducts = [[NSMutableArray alloc] init];
    NSArray * productsArray = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"orderItems"] withAlternative:@[]];
    
    for ( int i = 0; i < [productsArray count]; i++ )
    {
        Product * tmpProduct = [[Product alloc] initWithOrder:self andDictionary:[productsArray objectAtIndex:i]];
        tmpProduct.runnerFirstName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerFirstName"] withAlternative:@""];
        tmpProduct.runnerLastName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerLastName"] withAlternative:@""];
        tmpProduct.runnerPhoneNumber = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerPhoneNumber"] withAlternative:0];
        [tmpProducts addObject:tmpProduct];
        
        [[OrderManager sharedInstance] loadImageType:@"product" forProduct:tmpProduct];
        [[OrderManager sharedInstance] loadImageType:@"purchaseReceipt" forProduct:tmpProduct];
        [[OrderManager sharedInstance] loadImageType:@"returnReceipt" forProduct:tmpProduct];
    }
    self.products = tmpProducts;
    self.hasLoadedDetails = YES;
}

- (NSString *)displayStatus
{
    NSString * displayStatus = @"";
    displayStatus = [self stringFromRunnerStatus]; // switch this to the [EnumTypes string] call
    
    if ( self.anchorStatus == kAnchorStatusReturnInitiated )
    {
        displayStatus = @"Return\nInitiated";
        self.displayColor = [UIColor colorWithRed:(float)82/255 green:(float)210/255 blue:(float)128/255 alpha:1];
    }
    else if ( self.status == kStatusCancelled || self.status == kStatusReturned || self.status == kStatusReturnRejected )
    {
        displayStatus = [self stringFromStatus];
        self.displayColor = [UIColor lightGrayColor];
    }
    else if ( self.runnerStatus == kRunnerStatusRunning )
        self.displayColor = [UIColor colorWithRed:(float)254/255 green:(float)174/255 blue:(float)17/255 alpha:1];
    else if ( self.runnerStatus == kRunnerStatusPickedUp )
        self.displayColor = [UIColor colorWithRed:(float)254/255 green:(float)174/255 blue:(float)17/255 alpha:1];
    else if ( self.runnerStatus == kRunnerStatusAtStation || self.runnerStatus == kRunnerStatusDelivered )
    {
        displayStatus = @"Pending\nAt Station";
        self.displayColor = [UIColor colorWithRed:(float)82/255 green:(float)210/255 blue:(float)128/255 alpha:1];
        
        if ( self.anchorStatus == kAnchorStatusAtStation )
        {
            displayStatus = @"At Station";
            self.displayColor = [UIColor colorWithRed:(float)239/255 green:(float)118/255 blue:(float)37/255 alpha:1];
        }
        else if ( self.anchorStatus == kAnchorStatusDelivered )
        {
            displayStatus = @"Delivered";
            self.displayColor = [UIColor colorWithRed:(float)109/255 green:(float)202/255 blue:(float)72/255 alpha:1];
        }
    }
    else
    {
        displayStatus = @"Open";
        self.displayColor = [UIColor colorWithRed:(float)241/255 green:(float)68/255 blue:(float)51/255 alpha:1];
    }

    NSString *deviceType = [UIDevice currentDevice].model;
    
    if ( [deviceType containsString:@"iPhone"] )
        displayStatus = [displayStatus stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    
    return displayStatus;
}

- (NSString *) stringFromStatus
{
    switch (self.status)
    {
        case kStatusOpen:
            return @"Open";
            
        case kStatusAtStation:
            return @"At Station";
            
        case kStatusDelivered:
            return @"Delivered";
            
        case kStatusCancelled:
            return @"Cancelled";
            
        case kStatusReturned:
            return @"Returned";
            
        case kStatusReturnRejected:
            return @"Return Rejected";
            
        default:
            return @"";
    }
}

- (NSString *) stringFromRunnerStatus
{
    switch (self.runnerStatus)
    {
        case kRunnerStatusRunning:
            return @"Running";
            
        case kRunnerStatusPickedUp:
            return @"Picked Up";
            
        case kRunnerStatusAtStation:
            return @"At Station";
            
        case kRunnerStatusDelivered:
            return @"Delivered";
            
        default:
            return @"";
    }
}

- (NSString *) stringFromAnchorStatus
{
    switch (self.anchorStatus)
    {
        case kAnchorStatusRunning:
            return @"Running";
            
        case kAnchorStatusPickedUp:
            return @"Picked Up";
            
        case kAnchorStatusAtStation:
            return @"At Station";
            
        case kAnchorStatusDelivered:
            return @"Delivered";
            
        case kAnchorStatusReturnInitiated:
            return @"Return Initiated";
            
        default:
            return @"";
    }
}

@end
