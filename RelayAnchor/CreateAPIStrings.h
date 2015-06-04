//
//  CreateAPIStrings.h
//  RelayAnchor
//
//  Created by chuck on 8/14/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Order.h"
#import "Product.h"
#import "EnumTypes.h"

@interface CreateAPIStrings : NSObject

+(NSString *)baseUrl;
+(NSString *)appType;

+(void)splitUrl:(NSString*)urlToSplit ForApis:(void(^)(NSString * baseUrl, NSString *paramString))giveBaseAndParams;
+(NSURLRequest *)createRequestWithBaseUrl:(NSString *)baseUrl paramString:(NSString *)paramString isPostRequest:(BOOL)isPostRequest;

#pragma mark - account manager
+(NSString *)loginWithUser:(NSString *)user password:(NSString *)password andPushToken:(NSString *)pushToken;
+(NSString *)forgotPasswordForUser:(NSString *)user;
+(NSString *)addPushToken:(NSString *)pushTokenString;
+(NSString *)updatePushToken:(NSString *)newPushTokenString forOldPushToken:(NSString *)oldPushTokenString;

#pragma mark - order manager
+(NSString *)viewOrdersWithStatus:(LoadOrderStatus)loadOrderStatus;
+(NSString *)viewOrdersForOpen:(BOOL)open ready:(BOOL)ready closed:(BOOL)closed cancelledReturned:(BOOL)cancelledReturned startIndex:(int)startIndex count:(int)count;
+(NSString *)viewOrderDetailsForOrder:(Order *)order;
+(NSString *)confirmProductAtAnchor:(Product *)product;
+(NSString *)confirmOrderDelivery:(Order *)order;
+(NSString *)overrideConfirmOrderAtStation:(Order *)order;

+(NSString *)confirmProductReturnByCustomer:(Product *)product;
+(NSString *)confirmProductReturnToStore:(Product *)product;
+(NSString *)confirmProductReturnRejected:(Product *)product;
+(NSString *)cancelProduct:(Product *)product;

#pragma mark - contact manager
+(NSString *)sendEmailTo:(NSString *)emailAddress withSubject:(NSString *)subject andBody:(NSString *)body;

@end
