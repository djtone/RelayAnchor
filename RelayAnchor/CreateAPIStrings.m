//
//  CreateAPIStrings.m
//  RelayAnchor
//
//  Created by chuck on 8/14/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "CreateAPIStrings.h"
#import "AccountManager.h"

@implementation CreateAPIStrings

NSString * const baseUrl = @"http://shopyourwaylocal.com/SYWRelayServices";
//NSString * const baseUrl = @"http://sywlapp404p.prod.ch4.s.com:8180/SYWRelayServices";
//NSString * const baseUrl = @"http://sywl-pilotvip.prod.ch4.s.com/SYWRelayServices";
//NSString * const baseUrl = @"http://sywlapp301p.qa.ch3.s.com:8680/SYWRelayServices";
//NSString * const baseUrl = @"http://sywlapp302p.qa.ch3.s.com:8680/SYWRelayServices";

+ (NSString *)baseUrl
{
    return baseUrl;
}

+ (NSString *)appType
{
    if ( [baseUrl isEqualToString:@"http://shopyourwaylocal.com/SYWRelayServices"] )
        return @"ANC_ENT";
    else
        return @"ANC_DEV";
}

+ (void)splitUrl:(NSString *)urlToSplit ForApis:(void (^)(NSString *, NSString *))giveBaseAndParams
{
    NSLog(@"urlString : %@", urlToSplit/*, @"&sourceApp=Anchor"*/);
    
    NSArray *components = [urlToSplit componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?"]];
    giveBaseAndParams(components[0],components[1]/* stringByAppendingString:@"&sourceApp=Anchor"]*/);
}

+ (NSURLRequest *)createRequestWithBaseUrl:(NSString *)baseUrl paramString:(NSString *)paramString isPostRequest:(BOOL)isPostRequest
{
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseUrl]];
    if ( isPostRequest )
    {
        [request setHTTPMethod:@"POST"];
        NSMutableData *body = [NSMutableData data];
        [body appendData:[paramString dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:body];
        
        return request;
    }
    
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", baseUrl, paramString]];
    return request;
}

#pragma mark - AccountManager
+ (NSString *)loginWithUser:(NSString *)user password:(NSString *)password andPushToken:(NSString *)pushToken
{
    return [NSString stringWithFormat:@"%@/login?username=%@&passWord=%@&pushToken=%@", baseUrl, user, password, pushToken];
}

+ (NSString *)forgotPasswordForUser:(NSString *)user
{
    return [NSString stringWithFormat:@"%@/sellerForgotPassword?sellerEmail=%@", baseUrl, user];
}

+ (NSString *)addPushToken:(NSString *)pushTokenString
{
    return [NSString stringWithFormat:@"%@/relay/push/addPushToken/%@?pushToken=%@&localSessionKey=%@&appType=ANC_ENT&clientVersion=%@&sourceDevice=iOS", baseUrl, [[[AccountManager sharedInstance] selectedMall] mallId], pushTokenString, [[[AccountManager sharedInstance] selectedMall] sessionKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}

+ (NSString *)updatePushToken:(NSString *)newPushTokenString forOldPushToken:(NSString *)oldPushTokenString
{
    return [NSString stringWithFormat:@"%@/relay/push/updatePushToken/%@?oldPushToken=%@&newPushToken=%@&localSessionKey=%@&appType=ANCHOR&clientVersion=%@&sourceDevice=iOS", baseUrl, [[[AccountManager sharedInstance] selectedMall] mallId], oldPushTokenString, newPushTokenString, [[[AccountManager sharedInstance] selectedMall] sessionKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}

#pragma mark - order manager
+ (NSString *)viewOrdersWithStatus:(LoadOrderStatus)loadOrderStatus
{
    NSString * ordersForAnchorFilterBy = @"";
    switch (loadOrderStatus)
    {
        case kLoadOrderStatusAll:
            ordersForAnchorFilterBy = @"ALL";
            break;
            
        case kLoadOrderStatusOpen:
            ordersForAnchorFilterBy = @"OPEN";
            break;
            
        case kLoadOrderStatusReady:
            ordersForAnchorFilterBy = @"READY";
            break;
            
        case kLoadOrderStatusDelivered:
            ordersForAnchorFilterBy = @"DELIVERED";
            break;
        
        case kLoadOrderStatusCancelledReturned:
            ordersForAnchorFilterBy = @"CANCELLED";
            break;
            
        default:
            ordersForAnchorFilterBy = @"ALL";
    }
    
    return [NSString stringWithFormat:@"%@/relay/orders/viewSellerOrders/%@?ordersForAnchorFilterBy=%@&start=0&count=5000&orderPlaceTimeSort=ASC&runnerId=%@&sessionKey=%@", baseUrl, [[[AccountManager sharedInstance] selectedMall] mallId], ordersForAnchorFilterBy, [[[AccountManager sharedInstance] selectedMall] mallId], [[[AccountManager sharedInstance] selectedMall] sessionKey]];
    
    return ordersForAnchorFilterBy;
}

+ (NSString *)viewOrdersForOpen:(BOOL)open ready:(BOOL)ready closed:(BOOL)closed cancelledReturned:(BOOL)cancelledReturned startIndex:(int)startIndex count:(int)count
{
    NSString * statuses = @"";
    if ( open && ready && closed && cancelledReturned )
        statuses = @"ALL";
    else if ( open )
        statuses = @"OPEN";
    else if ( ready )
        statuses = @"READY";
    else if ( closed )
        statuses = @"DELIVERED";
    else if ( cancelledReturned )
        statuses = @"CANCELLED";
    
    return [NSString stringWithFormat:@"%@/relay/orders/viewSellerOrders/%@?ordersForAnchorFilterBy=%@&start=%i&count=%i&orderPlaceTimeSort=ASC&runnerId=%@&sessionKey=%@", baseUrl, [[[AccountManager sharedInstance] selectedMall] mallId], statuses, startIndex, count, [[[AccountManager sharedInstance] selectedMall] mallId], [[[AccountManager sharedInstance] selectedMall] sessionKey]];
}

+ (NSString *)viewOrderDetailsForOrder:(Order *)order
{
    return [NSString stringWithFormat:@"%@/relay/orders/viewSellerOrderDetails/%@/%@?sessionKey=%@", baseUrl, [[[AccountManager sharedInstance] selectedMall] mallId], order.mysqlOrderId, [[[AccountManager sharedInstance] selectedMall] sessionKey]];
}

+ (NSString *)confirmProductAtAnchor:(Product *)product
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/confirmOrderItemAtAnchor/%@/%@/%@?purchaseReceiptImg=%@&anchorSessionKey=%@&appType=%@", baseUrl, [[[AccountManager sharedInstance] selectedMall] mallId], product.myOrder.mysqlOrderId, product.productId, [[product.purchaseReceiptUrl absoluteString] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [[[AccountManager sharedInstance] selectedMall] sessionKey], [self appType]];
}

+ (NSString *)confirmOrderDelivery:(Order *)order
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/confirmDelivery/%@/%@?anchorSessionKey=%@", baseUrl, [[[AccountManager sharedInstance] selectedMall] mallId], order.mysqlOrderId, [[[AccountManager sharedInstance] selectedMall] sessionKey]];
}

+ (NSString *) overrideConfirmOrderAtStation:(Order *)order
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/overrideOrderToReady/%@/%@?purchaseReceiptImg=%@&anchorSessionKey=%@", baseUrl, [[[AccountManager sharedInstance] selectedMall] mallId], order.mysqlOrderId, order.purchaseReceiptUrl, [[[AccountManager sharedInstance] selectedMall] sessionKey]];
}

+ (NSString *) confirmProductReturnByCustomer:(Product *)product
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/confirmOrderItemReturnByCustomer/%@/%@/%@?anchorSessionKey=%@", baseUrl, [[[AccountManager sharedInstance] selectedMall] mallId], product.myOrder.mysqlOrderId, product.productId, [[[AccountManager sharedInstance] selectedMall] sessionKey]];
}

+(NSString *)confirmProductReturnToStore:(Product *)product
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/confirmOrderItemReturnToStore/%@/%@/%@?cancelReceiptImg=%@&anchorSessionKey=%@", baseUrl, [[[AccountManager sharedInstance] selectedMall] mallId], product.myOrder.mysqlOrderId, product.productId, product.returnReceiptUrl, [[[AccountManager sharedInstance] selectedMall] sessionKey]];
}

+(NSString *)confirmProductReturnRejected:(Product *)product
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/confirmOrderItemReturnRejected/%@/%@/%@?cancelReceiptImg=%@&anchorSessionKey=%@", baseUrl, [[[AccountManager sharedInstance] selectedMall] mallId], product.myOrder.mysqlOrderId, product.productId, product.returnReceiptUrl, [[[AccountManager sharedInstance] selectedMall] sessionKey]];
}

+(NSString *)cancelProduct:(Product *)product
{
    return [NSString stringWithFormat:@"%@/relay/buyer/orders/cancelOrderItem?buyerEmail=%@&orderItemId=%@&localSessionKey=%@", baseUrl, product.myOrder.buyerEmail, product.productId, [[[AccountManager sharedInstance] selectedMall] sessionKey]];
}

#pragma mark - contact manager
+ (NSString *) sendEmailTo:(NSString *)emailAddress withSubject:(NSString *)subject andBody:(NSString *)body
{
    return [NSString stringWithFormat:@"%@/sendEmail?emailaddress=%@&subject=%@&message=%@", baseUrl, emailAddress, subject, body];
}

@end
