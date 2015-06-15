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
#import "EnumTypes.h"


@protocol OrderManagerDelegate <NSObject>

@optional

//order
- (void) didStartLoadingOrdersWithStatus:(LoadOrderStatus)loadOrderStatus;
- (void) didFinishLoadingOrders:(NSArray *)orders status:(LoadOrderStatus)loadOrderStatus error:(NSString *)error;
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




@interface OrderManager : NSObject <NSURLConnectionDataDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

+ (OrderManager *) sharedInstanceWithDelegate:(id)delegate;
+ (OrderManager *) sharedInstance;

@property id <OrderManagerDelegate> delegate;

@property NSMutableDictionary * cachedOrders;

- (void) loadOrdersWithStatus:(LoadOrderStatus)loadOrderStatus completion:(void (^)(NSArray * orders))callBack;
- (void) startAutoRefreshOrdersWithStatus:(LoadOrderStatus)loadOrderStatus timeInterval:(float)timeInterval;
- (void) stopAutoRefreshOrders:(void(^)())completion;

- (void) cancelLoadOrders:(void(^)())callBack;

- (void) loadOrderDetailsForOrder:(Order *)order completion:(void(^)(Order * order))callBack;
- (void) loadImageType:(NSString*)type forProduct:(Product *)product;

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
- (void) cancelProduct:(Product *)product completion:(void (^)(BOOL success, NSString * errorMessage))callBack;

@property NSTimer * autoRefreshOrdersTimer;
@property NSTimer * autoRefreshOrderDetailsTimer;
@property NSURLSession * myNSURLSession;
@property NSMutableDictionary * responsesData;
@property NSMutableDictionary * completionBlocks;
//@property (copy) void (^loadOrdersCompletionBlock)(NSArray * orders);
@property NSString * sellerId;
@property NSURLConnection * receiptConnection;
@property NSDateFormatter * myDateFormatter;
@property BOOL showKeynoteOrders;

@property BOOL isUpdatingOrder;
@property BOOL isLoadingOrders;
@property BOOL isLoadingOrderDetails;
@property BOOL isUploadingReceipt;

+ (void) currentTasks:(void(^)(BOOL isLoadingOrders, BOOL isLoadingOrderDetails, BOOL isUpdatingOrder, BOOL isUploadingReceipt))completion;
//@property int numberOfOrdersReturned;

+ (NSMutableArray *) sortOrders:(NSMutableArray *)tmpOrders;

@end
