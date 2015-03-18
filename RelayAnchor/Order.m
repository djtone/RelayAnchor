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

@implementation Order

- (id) initWithDictionary:(NSDictionary *)dictionaryResponse
{
    if ( self = [super init] )
    {
        self.hasLoadedDetails = NO;
        
        self.orderId = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"wcsOrderId"] withAlternative:[NSNumber numberWithInt:0]];
        self.mysqlOrderId = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"mysqlOrderId"] withAlternative:[NSNumber numberWithInt:0]];
        self.totalPrice = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"totalOrderPrice"] withAlternative:[NSNumber numberWithInt:0]];
        self.tax = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"tax"] withAlternative:[NSNumber numberWithInt:0]];
        self.shippingCharges = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"shippingCharges"] withAlternative:[NSNumber numberWithInt:0]];
        self.itemQuantity = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"noOfOrderItems"] withAlternative:[NSNumber numberWithInt:0]];
        self.buyerFirstName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"firstName"] withAlternative:@""];
        self.buyerLastName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"lastName"] withAlternative:@""];
        self.runnerId = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerId"] withAlternative:[NSNumber numberWithInt:0]];
        self.anchorId = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"anchorId"] withAlternative:[NSNumber numberWithInt:0]];
        self.buyerEmail = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"buyerEmail"] withAlternative:@""];
        self.buyerPhoneNumber = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"buyerPhoneNumber"] withAlternative:[NSNumber numberWithDouble:0]];
        
        self.isKeynoteOrder = NO;
        if ( [[DataMethods checkForNull:[dictionaryResponse valueForKey:@"isKeynoteOrder"] withAlternative:nil] intValue] != 0 )
            self.isKeynoteOrder = YES;
        
        //NSLog(@"hasDelivItems : %hhd", self.hasDeliveryItems);
        
        self.runnerStatus = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerStatus"] withAlternative:@"Open"];
        if ( [self.runnerStatus isEqualToString:@"RUNNING"] )
            self.runnerStatus = @"Running";
        else if ( [self.runnerStatus isEqualToString:@"PICKEDUPBYRUNNER"] )
            self.runnerStatus = @"Picked Up";
        else if ( [self.runnerStatus isEqualToString:@"DROPPEDATANCHOR"] || [self.runnerStatus isEqualToString:@"READY"] ) //READY means it was overridden
            self.runnerStatus = @"At Station";
        else if ( [self.runnerStatus isEqualToString:@"DELIVERED"] )
            self.runnerStatus = @"Delivered";
        
        self.anchorStatus = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"anchorStatus"] withAlternative:@"Open"];
        if ( [self.anchorStatus isEqualToString:@"RUNNING"] )
            self.anchorStatus = @"Running";
        else if ( [self.anchorStatus isEqualToString:@"PICKEDUPBYRUNNER"] )
            self.anchorStatus = @"Picked Up";
        else if ( [self.anchorStatus isEqualToString:@"DROPPEDATANCHOR"] || [self.anchorStatus isEqualToString:@"READY"] ) //READY means it was overridden
            self.anchorStatus = @"At Station";
        else if ( [self.anchorStatus isEqualToString:@"DELIVERED"] )
            self.anchorStatus = @"Delivered";
        else if ( [self.anchorStatus isEqualToString:@"WAITITEMRETURNCUST"] )
            self.anchorStatus = @"Return Initiated";
        
        self.placeTime = [NSDate dateWithTimeIntervalSince1970:[[NSNumber numberWithInt:[[DataMethods checkForNull:[dictionaryResponse valueForKey:@"orderPlaceTime"] withAlternative:[NSNumber numberWithInt:0]] floatValue] /1000] doubleValue]];
        
        self.status = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"orderStatus"] withAlternative:@""];
        if ( [self.status isEqualToString:@"SUBMITTED"] )
            self.status = @"Open";
        else if ( [self.status isEqualToString:@"READY"] )
            self.status = @"At Station";
        else if ( [self.status isEqualToString:@"DELIVERED"] )
            self.status = @"Delivered";
        else if ( [self.status isEqualToString:@"FULLORDERREFINIT"] )
            self.status = @"Cancelled";
        else if ( [self.status isEqualToString:@"REFUNDED"] )
            self.status = @"Returned";
        else if ( [self.status isEqualToString:@"REFREJECTED"] )
            self.status = @"Rejected";
        
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
        
        self.isChangingStatus = NO;
    }
    return self;
}

- (void) fillOrderDetails:(NSDictionary *)dictionaryResponse
{
    self.products = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"anchorStatus"] withAlternative:@""];
    self.tax = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"tax"] withAlternative:0];
    
    NSArray * productDictionaries = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"orderItems"] withAlternative:[[NSArray alloc] init]];
    if ( [productDictionaries class] == [NSNull class] )
        productDictionaries = @[];
    NSMutableArray * tmpProducts = [[NSMutableArray alloc] init];
    for ( int i = 0; i < [productDictionaries count]; i++ )
    {
        Product * tmpProduct = [[Product alloc] initWithOrder:self andDictionary:[productDictionaries objectAtIndex:i]];
        [tmpProducts addObject:tmpProduct];
    }
    self.products = [tmpProducts copy];
}


@end
