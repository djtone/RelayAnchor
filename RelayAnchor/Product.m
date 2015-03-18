//
//  Product.m
//  RelayAnchor
//
//  Created by chuck on 8/15/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "Product.h"
#import "DataMethods.h"

@implementation Product

- (id) initWithOrder:(Order *)order andDictionary:(NSDictionary *)dictionaryResponse
{
    if ( self = [super init] )
    {
        self.myOrder = order;
        
        self.name = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"partName"] withAlternative:@""];
        self.productId = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"id"] withAlternative:[NSNumber numberWithInt:0]];
        self.quantity = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"quantity"] withAlternative:[NSNumber numberWithInt:0]];
        self.store = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"retSellerName"] withAlternative:@""];
        if ( [self.store isEqualToString:@"(null)"] )
            self.store = @"";
        self.price = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"totalItemPrice"] withAlternative:[NSNumber numberWithInt:0]];
        self.itemPrice = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"regularPrice"] withAlternative:[NSNumber numberWithInt:0]];
        self.salePrice = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"salePrice"] withAlternative:[NSNumber numberWithInt:0]];
        self.amountSaved = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"savingAmount"] withAlternative:[NSNumber numberWithInt:0]];
        self.tax = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"tax"] withAlternative:[NSNumber numberWithInt:0]];
        self.productDescription = [[DataMethods checkForNull:[dictionaryResponse valueForKey:@"descriptionShort"] withAlternative:@""] stringByReplacingOccurrencesOfString:@"\n    *" withString:@"\n*"];
        self.fulfillment = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"itemFulfillment"] withAlternative:@""];
        self.size = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"variationSize"] withAlternative:@"One Size"];
        if ( [self.size isEqualToString:@""] )
            self.size = @"One Size";
        self.color = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"variationColor"] withAlternative:@"One Color"];
        if ( [self.color isEqualToString:@""] )
            self.color = @"One Color";
        self.status = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"orderItemStatus"] withAlternative:@""];
        self.runnerFirstName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerFirstName"] withAlternative:@""];
        self.runnerLastName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerLastName"] withAlternative:@""];
        self.runnerId = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerId"] withAlternative:[NSNumber numberWithInt:0]];
        self.runnerPhoneNumber = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerPhoneNumber"] withAlternative:[NSNumber numberWithDouble:0]];
        self.anchorId = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"anchorId"] withAlternative:[NSNumber numberWithInt:0]];
        
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
        
        if ( [self.status isEqualToString:@"SUBMITTED"] )
            self.status = @"Open";
        else if ( [self.status isEqualToString:@"READY"] )
            self.status = @"At Station";
        else if ( [self.status isEqualToString:@"DELIVERED"] )
            self.status = @"Delivered";
        else if ( [self.status isEqualToString:@"REFINIT"] )
            self.status = @"Cancelled";
        
        NSString * urlString = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"imgUrl"] withAlternative:@""];
        self.imageUrl = [NSURL URLWithString:urlString];
        self.productImage = nil;
        
        self.purchaseReceiptUrl = order.purchaseReceiptUrl;
        self.purchaseReceiptImage = order.purchaseReceiptImage;
        //self.purchaseReceiptImage = [UIImage imageNamed:@"AppIcon.png"];
        
        self.returnReceiptUrl = order.returnReceiptUrl;
        self.returnReceiptImage = order.returnReceiptImage;
        //self.returnReceiptImage = [UIImage imageNamed:@"AppIcon.png"];
        
        self.isDeliveryItem = NO;
        if ( [[dictionaryResponse valueForKey:@"delivItem"] intValue] != 0 )
            self.isDeliveryItem = YES;
        
        self.isSubstitute = NO;
        if ( [[dictionaryResponse valueForKey:@"orderItemSubstitutionsBean"] class] != [NSNull class] )
        {
            self.isSubstitute = YES;
            
            NSDictionary * substituteItem = [dictionaryResponse valueForKey:@"orderItemSubstitutionsBean"];
            self.price = [DataMethods checkForNull:[substituteItem valueForKey:@"price"] withAlternative:[NSNumber numberWithInt:0]];
            self.quantity = [DataMethods checkForNull:[substituteItem valueForKey:@"quantity"] withAlternative:[NSNumber numberWithInt:0]];
            self.itemPrice = [DataMethods checkForNull:[substituteItem valueForKey:@"price"] withAlternative:[NSNumber numberWithInt:0]];
        }
        
        self.isReturn = NO;
        if ( [DataMethods checkForNull:[dictionaryResponse valueForKey:@"orderItemReturnsBean"] withAlternative:nil] )
            self.isReturn = YES;
        
        self.isSwipedOpen = NO;
    }
    return self;
}

@end
