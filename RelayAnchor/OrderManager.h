//
//  OrderManager.h
//  RelayAnchor
//
//  Created by chuck on 8/15/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Product.h"
#import "Order.h"
//#import "PrintManager.h"

@protocol OrderManagerDelegate <NSObject>

@optional

//order
- (void) didFinishLoadingOrders:(NSArray *)orders withStatusOpen:(BOOL)open ready:(BOOL)ready delivered:(BOOL)delivered cancelledReturned:(BOOL)cancelledReturned;
- (void) didFinishLoadingOrderDetails:(Order *)order;

//product
- (void) didFinishLoadingImageType:(NSString *)type forProduct:(Product *)product;

//receipt
- (void) didFinishUploadingReceipt:(NSURL *)receiptUrl;
- (void) didFailUploadingReceipt:(NSString *)errorMessage;

//printing
- (void) didFinishPrintingReceiptForOrder:(Order *)order;
- (void) didFailPrintingReceiptForOrder:(Order *)order;

@end


@interface OrderManager : NSObject <NSURLConnectionDataDelegate>

+ (OrderManager *) sharedInstanceWithDelegate:(id)delegate;
+ (OrderManager *) sharedInstance;

@property id <OrderManagerDelegate> delegate;

- (void) loadAllOrders;
- (void) loadAllOrdersWithCompletion:(void(^)(NSArray * orders))callBack;
- (void) loadOpenOrders;
- (void) loadOpenOrdersWithCompletion:(void(^)(NSArray * orders))callBack;
- (void) loadReadyOrders;
- (void) loadReadyOrdersWithCompletion:(void(^)(NSArray * orders))callBack;
- (void) loadDeliveredOrders;
- (void) loadDeliveredOrdersWithCompletion:(void(^)(NSArray * orders))callBack;
- (void) loadCancelledReturnedOrders;
- (void) loadCancelledReturnedOrdersWithCompletion:(void(^)(NSArray * orders))callBack;

- (void) loadOrderDetailsForOrder:(Order *)order;
- (void) loadOrderDetailsForOrder:(Order *)order completion:(void(^)(Order * order))callBack;

- (NSArray *) searchOrders:(NSArray *)orders withString:(NSString *)searchString;
- (NSArray *) searchProducts:(NSArray *)products withString:(NSString *)searchString;

- (BOOL) isLastProductToApprove:(Product *)product;
- (BOOL) allItemsAreAtStationForOrder:(Order *)order;
- (UIImage *) mergeReceiptImagesWithType:(NSString *)type forOrder:(Order *)order;
- (void) uploadReceiptImage:(UIImage *)receiptImage withType:(NSString *)type forOrder:(Order *)order;

- (void) confirmDeliveryForOrder:(Order *)order completion:(void (^)(BOOL success))callBack;
- (void) confirmProductAtStation:(Product *)product completion:(void (^)(BOOL success))callBack;
- (void) overrideConfirmOrderAtStation:(Order *)order completion:(void (^)(NSString * errorMessage))callBack;
- (void) confirmProductReturnByCustomer:(Product *)product completion:(void (^)(BOOL success))callBack;
- (void) confirmProductReturnToStore:(Product *)product completion:(void (^)(BOOL success))callBack;
- (void) confirmProductReturnRejected:(Product *)product completion:(void (^)(BOOL success))callBack;

@property NSString * sellerId;
@property BOOL isUpdatingOrder;
@property BOOL isLoadingOrders;
@property BOOL isLoadingOrderDetails;
@property BOOL isUploadingReceipt;
@property NSURLConnection * receiptConnection;
@property NSDateFormatter * myDateFormatter;

@property int numberOfOrdersReturned;

+ (NSMutableArray *) sortOrders:(NSMutableArray *)tmpOrders;

@end
