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
        NSString * buyerPhoneString = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"fullfillmentPhoneNumber"] withAlternative:@"0"];
        buyerPhoneString = [[buyerPhoneString componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
        self.myOrder.buyerPhoneNumber = [NSNumber numberWithInt:[buyerPhoneString intValue]];
        
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
        self.productDescription = [[DataMethods checkForNull:[dictionaryResponse valueForKey:@"descriptionShort"] withAlternative:@""] stringByReplacingOccurrencesOfString:@"\n    *" withString:@"\n*"]; //i think they might have removed this newline stuff
        self.fulfillment = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"itemFulfillment"] withAlternative:@""];
        self.buyerComments = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"instructions"] withAlternative:@""];
        NSString * fulfillment = [dictionaryResponse valueForKey:@"fulfillmentAddress"];
        //fulfillmentAddress = "835 N Michigan Ave, , Chicago, IL 60611";
        //parse the string (in a safe way)
        if ( [fulfillment class] != [NSNull class] )
        {
            if ( [fulfillment length] > 0 )
            {
                NSArray * fulfillmentComponents = [fulfillment componentsSeparatedByString:@","];
                
                if ( [fulfillmentComponents count] > 0 )
                {
                    NSString * tmpAddress = [[fulfillmentComponents objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if ( [tmpAddress length] > 0 )
                        self.buyerAddress = [[fulfillmentComponents objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    else
                        self.buyerAddress = @"No Address Provided";
                }
                else
                    self.buyerAddress = @"No Address Provided";
                
                //index 1 would be address line 2. skipping
                
                if ( [fulfillmentComponents count] > 2 )
                {
                    NSString * tmpCity = [[fulfillmentComponents objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if ( [tmpCity length] > 0 )
                        self.buyerCity = [[fulfillmentComponents objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    else
                        self.buyerCity = @"No City Provided";
                }
                else
                    self.buyerCity = @"No City Provided";
                
                if ( [fulfillmentComponents count] > 3 )
                {
                    NSString * stateAndZip = [[fulfillmentComponents objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    NSArray * stateAndZipComponents = [stateAndZip componentsSeparatedByString:@" "];
                    
                    if ( [stateAndZipComponents count] > 0 )
                    {
                        NSString * tmpBuyerState = [stateAndZipComponents objectAtIndex:0];
                        if ( [tmpBuyerState length] > 0 )
                            self.buyerState = [stateAndZipComponents objectAtIndex:0];
                        else
                            self.buyerState = @"No State Provided";
                    }
                    else
                        self.buyerState = @"No State Provided";
                    
                    if ( [stateAndZipComponents count] > 1 )
                    {
                        NSString * tmpBuyerZip = [stateAndZipComponents objectAtIndex:1];
                        if ( [tmpBuyerZip length] > 0 )
                            self.buyerZip = [stateAndZipComponents objectAtIndex:1];
                        else
                            self.buyerZip = @"No Zip Provided";
                    }
                    else
                        self.buyerZip = @"No Zip Provided";
                }
                else
                {
                    self.buyerState = @"No State Provided";
                    self.buyerZip = @"No Zip Provided";
                }
            }
            else
            {
                self.buyerAddress = @"No Address Provided";
                self.buyerCity = @"No City Provided";
                self.buyerState = @"No State Provided";
                self.buyerZip = @"No Zip Provided";
            }
        }
        else
        {
            self.buyerAddress = @"No Address Provided";
            self.buyerCity = @"No City Provided";
            self.buyerState = @"No State Provided";
            self.buyerZip = @"No Zip Provided";
        }
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
        else if ( [self.status isEqualToString:@"REFINIT"] || [self.runnerStatus isEqualToString:@"CANCELLED"] ) // || ORDERRETPROCESSING?
            self.status = @"Cancelled";
        else if ( [self.status isEqualToString:@"REFREJECTED"] )
            self.status = @"Refund Rejected";
        
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
