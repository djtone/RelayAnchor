//
//  Product.h
//  RelayAnchor
//
//  Created by chuck on 8/15/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Order.h"

@interface Product : NSObject

- (id) initWithOrder:(Order *)order andDictionary:(NSDictionary *)dictionaryResponse;

@property Order * myOrder;

@property NSString * name;
@property NSNumber * productId;
@property NSString * quantity;
@property NSString * store;
@property NSNumber * itemPrice;
@property NSNumber * price;
@property NSNumber * salePrice;
@property NSNumber * amountSaved;
@property NSNumber * tax;
@property NSURL * imageUrl;
@property UIImage * productImage;
@property NSString * productDescription; //'description' is a key word
@property NSString * fulfillment;
@property NSString * size;
@property NSString * color;
@property NSString * status;
@property NSString * runnerFirstName;
@property NSString * runnerLastName;
@property NSNumber * runnerId;
@property NSNumber * runnerPhoneNumber;
@property NSNumber * anchorId;
@property NSString * runnerStatus;
@property NSString * anchorStatus;

@property NSURL * purchaseReceiptUrl;
@property UIImage * purchaseReceiptImage;
@property NSURL * returnReceiptUrl;
@property UIImage * returnReceiptImage;

@property BOOL isDeliveryItem;
@property BOOL isSubstitute;
@property BOOL isReturn;

@property BOOL isSwipedOpen;

@end
