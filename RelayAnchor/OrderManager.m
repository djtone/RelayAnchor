//
//  OrderManager.m
//  RelayAnchor
//
//  Created by chuck on 8/15/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "OrderManager.h"
#import "CreateAPIStrings.h"
#import "Order.h"
#import "DataMethods.h"
#import "AccountManager.h"

@implementation OrderManager

static OrderManager * sharedOrderManager = nil;

+ (OrderManager *) sharedInstanceWithDelegate:(id)delegate
{
    if ( sharedOrderManager == nil )
    {
        sharedOrderManager = [[OrderManager alloc] init];
        sharedOrderManager.cachedOrders = [@{[EnumTypes stringFromLoadOrderStatus:kLoadOrderStatusOpen]: [@[] mutableCopy],
                                             [EnumTypes stringFromLoadOrderStatus:kLoadOrderStatusReady]: [@[] mutableCopy],
                                             [EnumTypes stringFromLoadOrderStatus:kLoadOrderStatusDelivered]: [@[] mutableCopy],
                                             [EnumTypes stringFromLoadOrderStatus:kLoadOrderStatusCancelledReturned]: [@[] mutableCopy]} mutableCopy];
        NSURLSessionConfiguration * tmpSessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        [tmpSessionConfig setTimeoutIntervalForRequest:300];
        sharedOrderManager.myNSURLSession = [NSURLSession sessionWithConfiguration:tmpSessionConfig delegate:sharedOrderManager delegateQueue:nil];
        sharedOrderManager.responsesData = [[NSMutableDictionary alloc] init];
        sharedOrderManager.isUpdatingOrder = NO;
        sharedOrderManager.isLoadingOrders = NO;
        sharedOrderManager.isLoadingOrderDetails = NO;
        sharedOrderManager.isUploadingReceipt = NO;
        if ( [[CreateAPIStrings baseUrl] isEqualToString:@"http://sywlapp301p.qa.ch3.s.com:8680/SYWRelayServices"] )
            sharedOrderManager.showKeynoteOrders = YES;
        else
            sharedOrderManager.showKeynoteOrders = NO;
        sharedOrderManager.myDateFormatter = [[NSDateFormatter alloc] init];
        [sharedOrderManager.myDateFormatter setDateFormat:@"M/d/yy"];
    }
    sharedOrderManager.delegate = delegate;
    return sharedOrderManager;
}

+ (OrderManager *) sharedInstance
{
    if ( sharedOrderManager == nil )
    {
        sharedOrderManager = [[OrderManager alloc] init];
        sharedOrderManager.isUpdatingOrder = NO;
        sharedOrderManager.isLoadingOrders = NO;
        sharedOrderManager.isLoadingOrderDetails = NO;
        sharedOrderManager.isUploadingReceipt = NO;
        sharedOrderManager.myDateFormatter = [[NSDateFormatter alloc] init];
        [sharedOrderManager.myDateFormatter setDateFormat:@"M/d/yy"];
    }
    return sharedOrderManager;
}

#pragma mark - viewing orders
- (void) loadOrdersWithStatus:(LoadOrderStatus)loadOrderStatus completion:(void (^)(NSArray *))callBack
{
    self.isLoadingOrders = YES;
    NSString * urlString = [CreateAPIStrings viewOrdersWithStatus:loadOrderStatus];
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:NO];
        NSURLSessionDataTask * loadOrdersDataTask = [self.myNSURLSession dataTaskWithRequest:request];
        
        loadOrdersDataTask.taskDescription = [EnumTypes stringFromLoadOrderStatus:loadOrderStatus];
        
        if ( callBack )
            self.completionBlocks[@(loadOrdersDataTask.taskIdentifier)] = callBack;
        else if ( [self.delegate respondsToSelector:@selector(didStartLoadingOrdersWithStatus:)] )
            [self.delegate didStartLoadingOrdersWithStatus:loadOrderStatus];
        
        [loadOrdersDataTask resume];
    }];
}

- (void) startAutoRefreshOrdersWithStatus:(LoadOrderStatus)loadOrderStatus timeInterval:(float)timeInterval
{
    NSDictionary * userInfo = @{@"loadOrderStatus": @(loadOrderStatus)};
    [self loadOrdersWithStatus:loadOrderStatus completion:nil];
    self.autoRefreshOrdersTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(loadOrdersFromTimer:) userInfo:userInfo repeats:YES];
}

- (void) loadOrdersFromTimer:(NSTimer *)timer
{
    if ( ! self.isLoadingOrders && ! self.isUpdatingOrder )
    {
        LoadOrderStatus loadOrderStatus = [[[timer userInfo] valueForKey:@"loadOrderStatus"] intValue];
        [self loadOrdersWithStatus:loadOrderStatus completion:nil];
    }
}

- (void) stopAutoRefreshOrders:(void(^)())completion
{
    [self.autoRefreshOrdersTimer invalidate];
    [self cancelLoadOrders:^
    {
        if ( completion )
            completion();
    }];
}

#pragma mark - misc
+ (NSMutableArray *) sortOrders:(NSMutableArray *)tmpOrders
{
    NSMutableArray * sortDescriptors = [[NSMutableArray alloc] init];
    NSArray * sortPreferences = [[AccountManager sharedInstance] orderSortPreferences];
    
    for ( int i = 0; i < [sortPreferences count]; i++ )
    {
        NSString * sortPreferenceString = [[sortPreferences objectAtIndex:i] firstObject];
        NSString * sortKey;
        
        if ( [sortPreferenceString isEqualToString:@"Order Date"] )
            sortKey = @"placeTime";
        else if ( [sortPreferenceString isEqualToString:@"Order ID"] )
            sortKey = @"wcsOrderId";
        else if ( [sortPreferenceString isEqualToString:@"Buyer Name"] )
            sortKey = @"buyerLastName";
        else if ( [sortPreferenceString isEqualToString:@"Buyer Email"] )
            sortKey = @"buyerEmail";
        else if ( [sortPreferenceString isEqualToString:@"Buyer Phone"] )
            sortKey = @"buyerPhoneNumber";
        else if ( [sortPreferenceString isEqualToString:@"Runner"] )
            sortKey = @"runnerId";
        else if ( [sortPreferenceString isEqualToString:@"Status"] )
            sortKey = @"displayStatus";
        
        if ( [sortKey length] > 0 )
            [sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:sortKey ascending:[[[sortPreferences objectAtIndex:i] lastObject] boolValue]]];
    }
    
    return [[tmpOrders sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];    
}


- (void) cancelLoadOrders:(void (^)())callBack
{
    [self.myNSURLSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            for ( NSURLSessionDataTask * tmpDataTask in dataTasks )
            {
                if ( [tmpDataTask.taskDescription containsString:@"LoadOrderStatus"] )
                {
                    NSLog(@"cancelling request : %@", tmpDataTask.currentRequest);
                    [tmpDataTask cancel];
                }
            }
            self.isLoadingOrders = NO;
            if ( callBack )
                callBack();
        });
    }];
}

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error)
    {
        NSLog(@"%@ failed: %@", task.originalRequest.URL, error);
        return;
    }
    
    NSMutableData * responseData = self.responsesData[@(task.taskIdentifier)];
    NSDictionary * dictionaryResponse = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
    
    if ( dictionaryResponse )
    {
        //NSLog(@"dictionaryResponse = %@", dictionaryResponse);

        if ( [task.taskDescription containsString:@"LoadOrderStatus"] ) //find a better way of checking this
        {
            self.isLoadingOrders = NO;
            NSMutableArray * tmpOrders = [[NSMutableArray alloc] init];
            NSArray * ordersArray = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"orderBeanList"] withAlternative:@[]];
            for ( int i = 0; i < [ordersArray count]; i++ )
            {
                Order * tmpOrder = [[Order alloc] initWithDictionary:[ordersArray objectAtIndex:i]];
                
                if ( self.showKeynoteOrders )
                {
                    if ( tmpOrder.isKeynoteOrder )
                        [tmpOrders addObject:tmpOrder];
                }
                else if ( ! tmpOrder.isKeynoteOrder )
                    [tmpOrders addObject:tmpOrder];
            }
            
            tmpOrders = [OrderManager sortOrders:tmpOrders];
            
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [self.cachedOrders setValue:tmpOrders forKey:task.taskDescription]; //not sure if this is correct
                
                void(^completionBlock)(NSArray *) = self.completionBlocks[@(task.taskIdentifier)];
                if ( completionBlock )
                    completionBlock(tmpOrders);
                else if ( [self.delegate respondsToSelector:@selector(didFinishLoadingOrders:status:error:)] )
                    [self.delegate didFinishLoadingOrders:tmpOrders status:[EnumTypes enumFromString:task.taskDescription] error:[error localizedDescription]];
                
                [self.completionBlocks removeObjectForKey:@(task.taskIdentifier)];
            });
        }
    }
    
    [self.responsesData removeObjectForKey:@(task.taskIdentifier)];
}

- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSMutableData * responseData = self.responsesData[@(dataTask.taskIdentifier)];
    if ( ! responseData )
    {
        responseData = [NSMutableData dataWithData:data];
        self.responsesData[@(dataTask.taskIdentifier)] = responseData;
    }
    else
        [responseData appendData:data];
}

- (void) loadOrderDetailsForOrder:(Order *)order completion:(void (^)(Order *))callBack
{
    self.isLoadingOrderDetails = YES;
    NSString * urlString = [CreateAPIStrings viewOrderDetailsForOrder:order];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:NO];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            if ( error )
                NSLog(@"error : %@", error);
            else
            {
                NSDictionary * dictionaryResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                [order fillOrderDetails:dictionaryResponse];
                self.isLoadingOrderDetails = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    if ( callBack )
                        callBack(order);
                    else if ( [self.delegate respondsToSelector:@selector(didFinishLoadingOrderDetails:)] )
                        [self.delegate didFinishLoadingOrderDetails:order];
                });
            }
        }] resume];
    }];
}

- (void) loadImageType:(NSString*)type forProduct:(Product *)product
{
    NSURLSession * session = [NSURLSession sharedSession];
    NSURLRequest * request;
    if ( [type isEqualToString:@"product"] )
        request = [[NSURLRequest alloc] initWithURL:product.imageUrl];
    else if ( [type isEqualToString:@"purchaseReceipt"] )
        request = [[NSURLRequest alloc] initWithURL:product.purchaseReceiptUrl];
    else
        request = [[NSURLRequest alloc] initWithURL:product.returnReceiptUrl];
    
    if ( [request.URL.absoluteString length] == 0 )
        return;
    else
    {
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                NSLog(@"loadImageType url : %@", request.URL.absoluteString);
                
                if ( error )
                    NSLog(@"error : %@", error);
                else
                {
                    UIImage * tmpImage = [UIImage imageWithData:data];
                    
                    if ( [type isEqualToString:@"product"] )
                    {
                        product.productImage = tmpImage;
                        if ([self.delegate respondsToSelector:@selector(didFinishLoadingImageType:forProduct:)])
                                            [self.delegate didFinishLoadingImageType:type forProduct:product];
                    }
                    else if ( [type isEqualToString:@"purchaseReceipt"] )
                    {
                        product.purchaseReceiptImage = tmpImage;
                        if ([self.delegate respondsToSelector:@selector(didFinishLoadingImageType:forProduct:)])                                               [self.delegate didFinishLoadingImageType:type forProduct:product];
                    }
                    else
                    {
                        product.returnReceiptImage = tmpImage;
                        if ([self.delegate respondsToSelector:@selector(didFinishLoadingImageType:forProduct:)])                                               [self.delegate didFinishLoadingImageType:type forProduct:product];
                    }
                }
            });
        }] resume];
    }
}

- (void) confirmProductAtStation:(Product *)product completion:(void (^)(BOOL success))callBack
{
    NSString * urlString = [CreateAPIStrings confirmProductAtAnchor:product];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
        
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                NSDictionary * dictionaryResponse;
                if ( data )
                {
                    dictionaryResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    NSLog(@"%@", dictionaryResponse);
                }
                
                if ( error )
                {
                    NSLog(@"error : %@", error);
                    callBack(NO);
                }
                else
                {
                    if ( [[dictionaryResponse valueForKey:@"responseCode"] intValue] != 0 )
                        callBack(NO);
                    else
                    {
                        product.anchorStatus = @"At Station";
                        product.myOrder.anchorStatus = kAnchorStatusAtStation;
                        callBack(YES);
                    }
                }
            });
        }] resume];
    }];
}


- (NSArray *) searchOrders:(NSArray *)orders withString:(NSString *)searchString
{
    if ( ! searchString.length )
        return orders;
    
    searchString = [searchString lowercaseString];
    NSMutableArray * filteredOrders = [[NSMutableArray alloc] init];
    
    for ( int i = 0; i < [orders count]; i++ )
    {
        Order * tmpOrder = [orders objectAtIndex:i];
        
        if ( [[[self.myDateFormatter stringFromDate:tmpOrder.placeTime] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpOrder.wcsOrderId] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@ %@", tmpOrder.buyerFirstName, tmpOrder.buyerLastName] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpOrder.buyerEmail] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpOrder.buyerPhoneNumber] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpOrder.runnerName] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpOrder.pickupLocation] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", [tmpOrder stringFromRunnerStatus]] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpOrder.displayStatus] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[tmpOrder stringFromStatus] lowercaseString] rangeOfString:searchString].location != NSNotFound )
        {
            [filteredOrders addObject:tmpOrder];
        }
    }
    
    return filteredOrders;
}

- (NSArray *) searchProducts:(NSArray *)products withString:(NSString *)searchString
{
    searchString = [searchString lowercaseString];
    NSMutableArray * filteredProducts = [[NSMutableArray alloc] init];
    
    for ( int i = 0; i < [products count]; i++ )
    {
        Product * tmpProduct = [products objectAtIndex:i];
        
        if ( [[[NSString stringWithFormat:@"%@", tmpProduct.productId] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[tmpProduct.store lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[tmpProduct.color lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[tmpProduct.size lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpProduct.price] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[tmpProduct.status lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[tmpProduct.name lowercaseString] rangeOfString:searchString].location != NSNotFound )
        {
            [filteredProducts addObject:tmpProduct];
        }
    }
    
    return filteredProducts;
}

- (void) confirmDeliveryForOrder:(Order *)order completion:(void (^)(BOOL success))callBack
{
    self.isUpdatingOrder = YES;
    NSString * urlString = [CreateAPIStrings confirmOrderDelivery:order];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                NSDictionary * dictionaryResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                NSString * responseStatus = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"status"] withAlternative:@""];
                self.isUpdatingOrder = NO;
                
                if ( error || ! [responseStatus isEqualToString:@"SUCCESS"] )
                {
                    if ( error )
                        NSLog(@"error : %@", error);
                    else
                        NSLog(@"response : %@", responseStatus);
                    
                    callBack(NO);
                }
                else
                {
                   order.status = kStatusDelivered;
                   order.anchorStatus = kAnchorStatusDelivered;
                   for ( int i = 0; i < [order.products count]; i++ )
                   {
                       Product * tmpProduct = (Product *)[order.products objectAtIndex:i];
                       tmpProduct.anchorStatus = @"Delivered";
                   }
                   callBack(YES);
                }
            });
        }] resume];
    }];
}

- (void) overrideConfirmOrderAtStation:(Order *)order completion:(void (^)(NSString *))callBack
{
    self.isUpdatingOrder = YES;
    NSString * urlString = [CreateAPIStrings overrideConfirmOrderAtStation:order];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                self.isUpdatingOrder = NO;
                if ( error )
                {
                    NSLog(@"error : %@", error);
                    if ( callBack )
                        callBack([NSString stringWithFormat:@"%@", error]);
                }
                else
                {
                    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    
                    NSLog(@"%@", responseDictionary);
                    
                    if ( callBack )
                    {
                        if ( [[responseDictionary valueForKey:@"status"] class] == [NSString class] &&
                           ( [[responseDictionary valueForKey:@"status"] isEqualToString:@"Delivery successfully called"] ||
                             [[responseDictionary valueForKey:@"status"] isEqualToString:@"SUCCESS"] ) )
                        {
                                 callBack(nil);
                        }
                        else
                        {
                            if ( [responseDictionary valueForKey:@"status"] )
                                callBack([responseDictionary valueForKey:@"status"]);
                            else
                                callBack(@"No Reponse From Server");
                        }
                    }
                }
            });
        }] resume];
    }];
}

- (void) confirmProductReturnByCustomer:(Product *)product completion:(void (^)(BOOL success))callBack
{
    NSString * urlString = [CreateAPIStrings confirmProductReturnByCustomer:product];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
        
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                if ( error )
                {
                    NSLog(@"error : %@", error);
                    callBack(NO);
                }
                else
                {
                    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    NSLog(@"%@", responseDictionary);
                    if ( [[responseDictionary valueForKey:@"status"] isEqualToString:@"SUCCESS"] )
                        callBack(YES);
                    else
                        callBack(NO);
                }
            });
        }] resume];
    }];
}

- (void) confirmProductReturnToStore:(Product *)product completion:(void (^)(BOOL success))callBack
{
    NSString * urlString = [CreateAPIStrings confirmProductReturnToStore:product];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                if ( error )
                {
                    NSLog(@"error : %@", error);
                    callBack(NO);
                }
                else
                {
                    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    NSLog(@"%@", responseDictionary);
                    if ( [[responseDictionary valueForKey:@"status"] isEqualToString:@"SUCCESS"] )
                        callBack(YES);
                    else
                        callBack(NO);
                }
            });
        }] resume];
    }];
}

- (void) confirmProductReturnRejected:(Product *)product completion:(void (^)(BOOL success))callBack
{
    NSString * urlString = [CreateAPIStrings confirmProductReturnRejected:product];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                if ( error )
                {
                    NSLog(@"error : %@", error);
                    callBack(NO);
                }
                else
                {
                    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    NSLog(@"%@", responseDictionary);
                    
                    if ( [[responseDictionary valueForKey:@"status"] isEqualToString:@"SUCCESS"] )
                        callBack(YES);
                    else
                        callBack(NO);
                }
            });
        }] resume];
    }];
}

- (void) cancelProduct:(Product *)product completion:(void (^)(BOOL, NSString *))callBack
{
    NSString * urlString = [CreateAPIStrings cancelProduct:product];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                if ( error )
                {
                    NSLog(@"error : %@", error);
                    callBack(NO, [error localizedDescription]);
                }
                else
                {
                    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    NSLog(@"%@", responseDictionary);
                    
                    if ( [[responseDictionary valueForKey:@"message"] isEqualToString:@"SUCCESS"] )
                    {
                        product.status = @"Cancelled";
                        callBack(YES, nil);
                    }
                    else
                        callBack(NO, [DataMethods checkForNull:[responseDictionary valueForKey:@"message"] withAlternative:@"No Error Message"]);
                }
            });
        }] resume];
    }];
}

- (BOOL) allItemsAreAtStationForOrder:(Order *)order
{
    for ( int i = 0; i < [order.products count]; i++ )
    {
        if ( ! [[(Product *)[order.products objectAtIndex:i] anchorStatus] isEqualToString:@"At Station"] &&
             ! [[(Product *)[order.products objectAtIndex:i] status] isEqualToString:@"Cancelled"] )
            return NO;
    }
    return YES;
}

#pragma mark - receipt stuff
- (BOOL) isLastProductToApprove:(Product *)product
{
    BOOL isLastProductToApprove = YES;
    for ( int i = 0; i < product.myOrder.products.count; i++ )
    {
        Product * tmpProduct = [product.myOrder.products objectAtIndex:i];
        if ( ! [tmpProduct.anchorStatus isEqualToString:@"At Station"] && ! [tmpProduct.status isEqualToString:@"Cancelled"] && tmpProduct != product )
        {
            isLastProductToApprove = NO;
            break;
        }
    }
    return isLastProductToApprove;
}

- (UIImage *) mergeReceiptImagesWithType:(NSString *)type forOrder:(Order *)order
{
    NSMutableArray * receiptImages = [[NSMutableArray alloc] init];
    
    if ( [type isEqualToString:@"purchase"] )
    {
        for ( int i = 0; i < order.products.count; i++ )
        {
            if ( [[order.products objectAtIndex:i] purchaseReceiptImage] )
                [receiptImages addObject:[[order.products objectAtIndex:i] purchaseReceiptImage]];
        }
    }
    else
    {
        for ( int i = 0; i < order.products.count; i++ )
        {
            if ( [[order.products objectAtIndex:i] returnReceiptImage] != nil )
                [receiptImages addObject:[[order.products objectAtIndex:i] returnReceiptImage]];
        }
    }
    
    int imageWidth = 0;
    int imageHeight = 0;
    for ( int i = 0; i < receiptImages.count; i++ )
    {
        UIImage * tmpImage = [receiptImages objectAtIndex:i];
        
        if ( tmpImage.size.width > imageWidth )
            imageWidth = tmpImage.size.width;
        
        imageHeight += tmpImage.size.height;
    }
    CGSize size = CGSizeMake(imageWidth, imageHeight);
    
    UIGraphicsBeginImageContext(size);
    for ( int i = 0; i < receiptImages.count; i++ )
    {
        UIImage * tmpImage = [receiptImages objectAtIndex:i];
        
        if ( i == 0 )
            [tmpImage drawInRect:CGRectMake(0, 0, tmpImage.size.width, tmpImage.size.height)];
        else
        {
            UIImage * previousImage = [receiptImages objectAtIndex:i-1];
            [tmpImage drawInRect:CGRectMake(0, previousImage.size.height, tmpImage.size.width, tmpImage.size.height)];
        }
    }
    
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return finalImage;
}

- (void) uploadReceiptImage:(UIImage *)purchaseReceiptImage withType:(NSString *)type forOrder:(Order *)order
{
    self.isUploadingReceipt = YES;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"------VohpleBoundary4QuqLuM1cE5lMwCy";
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    if ( [type isEqualToString:@"purcahse"] )
        [parameters setValue:@"ORDERRECEIPT" forKey:@"imageType"];
    else
        [parameters setValue:@"ORDERRECEIPT" forKey:@"imageType"]; //this needs to be changed. do not have paramter value yet
    
    for (NSString *param in parameters)
    {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", [parameters objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSString *FileParamConstant = @"file";
    
    NSData *imageData = UIImageJPEGRepresentation(purchaseReceiptImage, .25);
    //NSLog(@"image size in mb : %.2f",(float)imageData.length/1024.0f/1024.0f); // i want to log this on a device to find the size of the receipt images
    
    if (imageData)
    {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"PurchaseReceipt_%@.jpg\"\r\n", FileParamConstant, order.wcsOrderId] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type:image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imageData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:body];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/dude/uploadGeneralImage/", [CreateAPIStrings baseUrl]]]];
    
    self.receiptConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ( [self.delegate respondsToSelector:@selector(didFailUploadingReceipt:)] )
        [self.delegate didFailUploadingReceipt:@"Error Uploading Receipt"];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ( connection == self.receiptConnection )
    {
        NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        if ( [[responseDictionary valueForKey:@"responseCode"] intValue] == 0 )
        {
            if ( [self.delegate respondsToSelector:@selector(didFinishUploadingReceipt:)] )
                [self.delegate didFinishUploadingReceipt:[NSURL URLWithString:[responseDictionary valueForKey:@"message"]]];
        }
        else if ( [self.delegate respondsToSelector:@selector(didFailUploadingReceipt:)] )
            [self.delegate didFailUploadingReceipt:@"Error Uploading Receipt"];
    }
}

+ (void) currentTasks:(void (^)(BOOL isLoadingOrders, BOOL isLoadingOrderDetails, BOOL isUpdatingOrder, BOOL isUploadingReceipt))completion
{
    [[NSURLSession sharedSession] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks)
    {
        BOOL isUpdatingOrder = NO;
        BOOL isLoadingOrders = NO;
        BOOL isLoadingOrderDetails = NO;
        BOOL isUploadingReceipt = NO;
        
        for ( NSURLSessionDataTask * dataTask in dataTasks )
        {
            if ( [dataTask.taskDescription isEqualToString:@"load orders"] )
                isLoadingOrders = YES;
            else if ( [dataTask.taskDescription isEqualToString:@"load order details"] )
                isLoadingOrderDetails = YES;
            else if ( [dataTask.taskDescription isEqualToString:@"updating order"] )
                isUpdatingOrder = YES;
            else if ( [dataTask.taskDescription isEqualToString:@"uploading receipt"] )
                isUploadingReceipt = YES;
        }
        
        completion(isLoadingOrders, isLoadingOrderDetails, isUpdatingOrder, isUploadingReceipt);
    }];
}

@end
