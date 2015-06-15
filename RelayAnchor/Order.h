//
//  Order.h
//  RelayAnchor
//
//  Created by chuck on 8/13/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnumTypes.h"

@interface Order : NSObject

- (id) initWithDictionary:(NSDictionary *)dictionaryResponse;
- (void) fillOrderDetails:(NSDictionary *)dictionaryResponse;
@property BOOL hasLoadedDetails;

//view order
@property NSNumber * wcsOrderId;
@property NSNumber * mysqlOrderId;
@property NSNumber * shippingCharges;
@property NSNumber * tax;
@property NSNumber * itemQuantity;
@property NSDate * placeTime;
@property NSString * buyerFirstName;
@property NSString * buyerLastName;
@property Status status;
@property RunnerStatus runnerStatus;
@property AnchorStatus anchorStatus;
@property NSNumber * runnerId;
@property NSString * runnerName;
@property NSNumber * anchorId;
@property NSString * buyerEmail;
@property BOOL isKeynoteOrder;
@property BOOL hasDeliveryItems;
@property NSString * deliverySlot;
@property NSString * pickupLocation;

- (NSString *)stringFromStatus; // switch this to the [EnumTypes string] method //;/
- (NSString *)stringFromRunnerStatus; // switch this to the [EnumTypes string] method //;/
- (NSString *)stringFromAnchorStatus; // switch this to the [EnumTypes string] method //;/

//i need to check if receipts are in viewSellerOrders or viewSellerOrderDetails
@property NSURL * purchaseReceiptUrl;
@property UIImage * purchaseReceiptImage;
@property NSURL * returnReceiptUrl;
@property UIImage * returnReceiptImage;

//view order details
@property NSNumber * totalPrice;
@property NSNumber * buyerPhoneNumber;
@property NSNumber * deliveryPhoneNumber;
@property NSDate * deliveryDate;
@property NSArray * products;

//for displaying on tableviews
- (NSString *) displayStatus;
@property UIColor * displayColor;
@property BOOL isChangingStatus;

@end
