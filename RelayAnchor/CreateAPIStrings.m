//
//  CreateAPIStrings.m
//  RelayAnchor
//
//  Created by chuck on 8/14/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "CreateAPIStrings.h"

@implementation CreateAPIStrings

//NSString * const baseUrl = @"http://shopyourwaylocal.com/SYWRelayServices";
//NSString * const baseUrl = @"http://sywlapp404p.prod.ch4.s.com:8180/SYWRelayServices";
//NSString * const baseUrl = @"http://sywl-pilotvip.prod.ch4.s.com/SYWRelayServices";
NSString * const baseUrl = @"http://sywlapp301p.qa.ch3.s.com:8680/SYWRelayServices";
//NSString * const baseUrl = @"http://sywlapp302p.qa.ch3.s.com:8680/SYWRelayServices";

+ (NSString *)baseUrl
{
    return baseUrl;
}

+ (NSString *)sessionKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"sessionKey"];
}

+ (NSString *)sellerId
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"sellerId"];
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

#pragma mark - account manager
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
    return [NSString stringWithFormat:@"%@/relay/push/addPushToken/%@?pushToken=%@&localSessionKey=%@&appType=ANC_ENT&clientVersion=%@&sourceDevice=iOS", baseUrl, [self sellerId], pushTokenString, [self sessionKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}

+ (NSString *)updatePushToken:(NSString *)newPushTokenString forOldPushToken:(NSString *)oldPushTokenString
{
    return [NSString stringWithFormat:@"%@/relay/push/updatePushToken/%@?oldPushToken=%@&newPushToken=%@&localSessionKey=%@&appType=ANCHOR&clientVersion=%@&sourceDevice=iOS", baseUrl, [self sellerId], oldPushTokenString, newPushTokenString, [self sessionKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}

#pragma mark - order manager
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
    
    return [NSString stringWithFormat:@"%@/relay/orders/viewSellerOrders/%@?ordersForAnchorFilterBy=%@&start=%i&count=%i&orderPlaceTimeSort=ASC&runnerId=%@&sessionKey=%@", baseUrl, [self sellerId], statuses, startIndex, count, [self sellerId], [self sessionKey]];
}

+ (NSString *)viewOrderDetailsForOrder:(Order *)order
{
    return [NSString stringWithFormat:@"%@/relay/orders/viewSellerOrderDetails/%@/%@?sessionKey=%@", baseUrl, [self sellerId], order.mysqlOrderId, [self sessionKey]];
}

+ (NSString *)confirmProductAtAnchor:(Product *)product
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/confirmOrderItemAtAnchor/%@/%@/%@?purchaseReceiptImg=%@&anchorSessionKey=%@&appType=%@", baseUrl, [self sellerId], product.myOrder.mysqlOrderId, product.productId, [[product.purchaseReceiptUrl absoluteString] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [self sessionKey], [self appType]];
}

+ (NSString *)confirmOrderDelivery:(Order *)order
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/confirmDelivery/%@/%@?anchorSessionKey=%@", baseUrl, [self sellerId], order.mysqlOrderId, [self sessionKey]];
}

+ (NSString *) overrideConfirmOrderAtStation:(Order *)order
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/overrideOrderToReady/%@/%@?purchaseReceiptImg=%@&anchorSessionKey=%@", baseUrl, [self sellerId], order.mysqlOrderId, order.purchaseReceiptUrl, [self sessionKey]];
}

+ (NSString *) confirmProductReturnByCustomer:(Product *)product
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/confirmOrderItemReturnByCustomer/%@/%@/%@?anchorSessionKey=%@", baseUrl, [self sellerId], product.myOrder.mysqlOrderId, product.productId, [self sessionKey]];
}

+(NSString *)confirmProductReturnToStore:(Product *)product
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/confirmOrderItemReturnToStore/%@/%@/%@?cancelReceiptImg=%@&anchorSessionKey=%@", baseUrl, [self sellerId], product.myOrder.mysqlOrderId, product.productId, product.returnReceiptUrl, [self sessionKey]];
}

+(NSString *)confirmProductReturnRejected:(Product *)product
{
    return [NSString stringWithFormat:@"%@/relay/anchor/orders/confirmOrderItemReturnRejected/%@/%@/%@?cancelReceiptImg=%@&anchorSessionKey=%@", baseUrl, [self sellerId], product.myOrder.mysqlOrderId, product.productId, product.returnReceiptUrl, [self sessionKey]];
}

#pragma mark - contact manager
+ (NSString *) sendEmailTo:(NSString *)emailAddress withSubject:(NSString *)subject andBody:(NSString *)body
{
    return [NSString stringWithFormat:@"%@/sendEmail?emailaddress=%@&subject=%@&message=%@", baseUrl, emailAddress, subject, body];
}

@end
