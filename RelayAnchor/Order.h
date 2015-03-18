//
//  Order.h
//  RelayAnchor
//
//  Created by chuck on 8/13/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Order : NSObject

- (id) initWithDictionary:(NSDictionary *)dictionaryResponse;
- (void) fillOrderDetails:(NSDictionary *)dictionaryResponse;
@property BOOL hasLoadedDetails;

//view order
@property NSNumber * orderId;
@property NSNumber * mysqlOrderId;
@property NSNumber * shippingCharges;
@property NSNumber * totalPrice;
@property NSNumber * itemQuantity;
@property NSDate * placeTime;
@property NSString * buyerFirstName;
@property NSString * buyerLastName;
@property NSNumber * buyerPhoneNumber;
@property NSString * status;
@property NSNumber * runnerId;
@property NSNumber * anchorId;
@property NSString * runnerStatus;
@property NSString * anchorStatus;
@property NSString * buyerEmail;
@property BOOL isKeynoteOrder;

//view order details
@property NSNumber * tax;
@property NSArray * products;

@property NSURL * purchaseReceiptUrl;
@property UIImage * purchaseReceiptImage;
@property NSURL * returnReceiptUrl;
@property UIImage * returnReceiptImage;

//for displaying on tableviews
@property BOOL isChangingStatus;

@end
