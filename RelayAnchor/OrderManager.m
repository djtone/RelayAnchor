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
        sharedOrderManager.isUpdatingOrder = NO;
        sharedOrderManager.isLoadingOrders = NO;
        sharedOrderManager.isLoadingOrderDetails = NO;
        sharedOrderManager.isUploadingReceipt = NO;
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
- (void) loadOrdersForOpen:(BOOL)open ready:(BOOL)ready delivered:(BOOL)delivered cancelledReturned:(BOOL)cancelledReturned startIndex:(int)startIndex count:(int)count completion:(void (^)(NSArray * newOrders))callBack
{
    NSString * urlString = [CreateAPIStrings viewOrdersForOpen:open ready:ready closed:delivered cancelledReturned:cancelledReturned startIndex:startIndex count:count];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:NO];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            if ( error )
            {
                NSLog(@"error : %@", error);
                callBack(nil);
            }
            else
            {
                NSDictionary * dictionaryResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                NSMutableArray * tmpOrders = [[NSMutableArray alloc] init];
                NSArray * ordersArray = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"orderBeanList"] withAlternative:@[]];
                for ( int i = 0; i < [ordersArray count]; i++ )
                {
                    Order * tmpOrder = [[Order alloc] initWithDictionary:[ordersArray objectAtIndex:i]];
                    [tmpOrders addObject:tmpOrder];
                }
                
                tmpOrders = [OrderManager sortOrders:tmpOrders];
                
                callBack(tmpOrders);
            }
        }] resume];
    }];
}

- (void) loadEveryOrderWithStatusOpen:(BOOL)open ready:(BOOL)ready delivered:(BOOL)delivered cancelledReturned:(BOOL)cancelledReturned startIndex:(int)startIndex orders:(NSMutableArray *)orders completion:(void(^)(NSArray * orders))callBack;
{
    [self loadOrdersForOpen:open ready:ready delivered:delivered cancelledReturned:cancelledReturned startIndex:startIndex count:5000 completion:^(NSArray *newOrders)
    {
        [orders addObjectsFromArray:newOrders];
         
        if ( [newOrders count] == 5000 )
            [self loadEveryOrderWithStatusOpen:open ready:ready delivered:delivered cancelledReturned:cancelledReturned startIndex:startIndex+5000 orders:orders completion:callBack];
        else
        {
            self.isLoadingOrders = NO;
            
            if ( callBack != nil )
                dispatch_sync(dispatch_get_main_queue(), ^
            {
                callBack(orders);
            });
            else if ([self.delegate respondsToSelector:@selector(didFinishLoadingOrders:withStatusOpen:ready:delivered:cancelledReturned:)])
                 dispatch_sync(dispatch_get_main_queue(), ^
            {
                [self.delegate didFinishLoadingOrders:orders withStatusOpen:open ready:ready delivered:delivered cancelledReturned:cancelledReturned];
            });
        }
    }];
}

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
            sortKey = @"orderId";
        else if ( [sortPreferenceString isEqualToString:@"Buyer Name"] )
            sortKey = @"buyerLastName";
        else if ( [sortPreferenceString isEqualToString:@"Buyer Email"] )
            sortKey = @"buyerEmail";
        else if ( [sortPreferenceString isEqualToString:@"Buyer Phone"] )
            sortKey = @"buyerPhoneNumber";
        else if ( [sortPreferenceString isEqualToString:@"Runner"] )
            sortKey = @"runnerId";
        else if ( [sortPreferenceString isEqualToString:@"Status"] )
            sortKey = @"status";
        
        if ( [sortKey length] > 0 )
            [sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:sortKey ascending:[[[sortPreferences objectAtIndex:i] lastObject] boolValue]]];
    }
    
    return [[tmpOrders sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
}

- (void) loadAllOrders
{
    if ( ! self.isLoadingOrders )
    {
        self.isLoadingOrders = YES;
        NSMutableArray * orders = [[NSMutableArray alloc] init];
        [self loadEveryOrderWithStatusOpen:YES ready:YES delivered:YES cancelledReturned:YES startIndex:0 orders:orders completion:nil];
    }
}

- (void) loadAllOrdersWithCompletion:(void (^)(NSArray *))callBack
{
    if ( ! self.isLoadingOrders )
    {
        self.isLoadingOrders = YES;
        NSMutableArray * orders = [[NSMutableArray alloc] init];
        [self loadEveryOrderWithStatusOpen:YES ready:YES delivered:YES cancelledReturned:YES startIndex:0 orders:orders completion:callBack];
    }
}

- (void) loadOpenOrders
{
    if ( ! self.isLoadingOrders )
    {
        self.isLoadingOrders = YES;
        NSMutableArray * orders = [[NSMutableArray alloc] init];
        [self loadEveryOrderWithStatusOpen:YES ready:NO delivered:NO cancelledReturned:NO startIndex:0 orders:orders completion:nil];
    }
}

- (void) loadOpenOrdersWithCompletion:(void (^)(NSArray *))callBack
{
    if ( ! self.isLoadingOrders )
    {
        self.isLoadingOrders = YES;
        NSMutableArray * orders = [[NSMutableArray alloc] init];
        [self loadEveryOrderWithStatusOpen:YES ready:NO delivered:NO cancelledReturned:NO startIndex:0 orders:orders completion:callBack];
    }
}

- (void) loadReadyOrders
{
    if ( ! self.isLoadingOrders )
    {
        self.isLoadingOrders = YES;
        NSMutableArray * orders = [[NSMutableArray alloc] init];
        [self loadEveryOrderWithStatusOpen:NO ready:YES delivered:NO cancelledReturned:NO startIndex:0 orders:orders completion:nil];
    }
}

- (void) loadReadyOrdersWithCompletion:(void (^)(NSArray *))callBack
{
    if ( ! self.isLoadingOrders )
    {
        self.isLoadingOrders = YES;
        NSMutableArray * orders = [[NSMutableArray alloc] init];
        [self loadEveryOrderWithStatusOpen:NO ready:YES delivered:NO cancelledReturned:NO startIndex:0 orders:orders completion:callBack];
    }
}

- (void) loadDeliveredOrders
{
    if ( ! self.isLoadingOrders )
    {
        self.isLoadingOrders = YES;
        NSMutableArray * orders = [[NSMutableArray alloc] init];
        [self loadEveryOrderWithStatusOpen:NO ready:NO delivered:YES cancelledReturned:NO startIndex:0 orders:orders completion:nil];
    }
}

- (void) loadDeliveredOrdersWithCompletion:(void (^)(NSArray *))callBack
{
    if ( ! self.isLoadingOrders )
    {
        self.isLoadingOrders = YES;
        NSMutableArray * orders = [[NSMutableArray alloc] init];
        [self loadEveryOrderWithStatusOpen:NO ready:NO delivered:YES cancelledReturned:NO startIndex:0 orders:orders completion:callBack];
    }
}

- (void) loadCancelledReturnedOrders
{
    if ( ! self.isLoadingOrders )
    {
        self.isLoadingOrders = YES;
        NSMutableArray * orders = [[NSMutableArray alloc] init];
        [self loadEveryOrderWithStatusOpen:NO ready:NO delivered:NO cancelledReturned:YES startIndex:0 orders:orders completion:nil];
    }
}

- (void) loadCancelledReturnedOrdersWithCompletion:(void (^)(NSArray *))callBack
{
    if ( ! self.isLoadingOrders )
    {
        self.isLoadingOrders = YES;
        NSMutableArray * orders = [[NSMutableArray alloc] init];
        [self loadEveryOrderWithStatusOpen:NO ready:NO delivered:NO cancelledReturned:YES startIndex:0 orders:orders completion:callBack];
    }
}


- (void) loadOrderDetailsForOrder:(Order *)order
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
                order.buyerPhoneNumber = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"memberPhone"] withAlternative:0];
                order.totalPrice = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"totalOrderPrice"] withAlternative:[NSNumber numberWithInt:0]];
                NSMutableArray * tmpProducts = [[NSMutableArray alloc] init];
                NSArray * productsArray = [dictionaryResponse valueForKey:@"orderItems"];
                if ( [productsArray class] == [NSNull class] )
                    productsArray = @[]; //prevents exception "no known selector [NSNull Count]"
                                         //i have only seen this error in QA orders that are messed up (all the entries are null)
                for ( int i = 0; i < [productsArray count]; i++ )
                {
                    Product * tmpProduct = [[Product alloc] initWithOrder:order andDictionary:[productsArray objectAtIndex:i]];
                    //the following 3 fields will be moved into the product details dictionary eventually
                    //because the runner assignments will be moved to item level instead of order level
                    tmpProduct.runnerFirstName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerFirstName"] withAlternative:@""];
                    tmpProduct.runnerLastName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerLastName"] withAlternative:@""];
                    tmpProduct.runnerPhoneNumber = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerPhoneNumber"] withAlternative:0];
                    [tmpProducts addObject:tmpProduct];
                    
                    [self loadImageType:@"product" forProduct:tmpProduct];
                    [self loadImageType:@"purchaseReceipt" forProduct:tmpProduct];
                    [self loadImageType:@"returnReceipt" forProduct:tmpProduct];
                }
                order.products = tmpProducts;
                order.hasLoadedDetails = YES;
                
                if ([self.delegate respondsToSelector:@selector(didFinishLoadingOrderDetails:)])
                {
                    dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        self.isLoadingOrderDetails = NO;
                        [self.delegate didFinishLoadingOrderDetails:order];
                    });
                }
            }
        }] resume];
    }];
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
                order.buyerPhoneNumber = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"memberPhone"] withAlternative:0];
                order.totalPrice = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"totalOrderPrice"] withAlternative:[NSNumber numberWithInt:0]];
                NSMutableArray * tmpProducts = [[NSMutableArray alloc] init];
                NSArray * productsArray = [dictionaryResponse valueForKey:@"orderItems"];
                if ( [productsArray class] == [NSNull class] )
                    productsArray = @[];
                for ( int i = 0; i < [productsArray count]; i++ )
                {
                    Product * tmpProduct = [[Product alloc] initWithOrder:order andDictionary:[productsArray objectAtIndex:i]];
                    //the following 3 fields will be moved into the product details dictionary eventually
                    //because the runner assignments will be moved to item level instead of order level
                    tmpProduct.runnerFirstName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerFirstName"] withAlternative:@""];
                    tmpProduct.runnerLastName = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerLastName"] withAlternative:@""];
                    tmpProduct.runnerPhoneNumber = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"runnerPhoneNumber"] withAlternative:0];
                    [tmpProducts addObject:tmpProduct];
                       
                    [self loadImageType:@"product" forProduct:tmpProduct];
                    [self loadImageType:@"purchaseReceipt" forProduct:tmpProduct];
                    [self loadImageType:@"returnReceipt" forProduct:tmpProduct];
                }
                order.products = tmpProducts;
                order.hasLoadedDetails = YES;
                   
                dispatch_sync(dispatch_get_main_queue(), ^
                {
                    self.isLoadingOrderDetails = NO;
                    callBack(order);
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
                        dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        [self.delegate didFinishLoadingImageType:type forProduct:product];
                    });
                }
                else if ( [type isEqualToString:@"purchaseReceipt"] )
                {
                    product.purchaseReceiptImage = tmpImage;
                    if ([self.delegate respondsToSelector:@selector(didFinishLoadingImageType:forProduct:)])
                        dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        [self.delegate didFinishLoadingImageType:type forProduct:product];
                    });
                }
                else
                {
                    product.returnReceiptImage = tmpImage;
                    if ([self.delegate respondsToSelector:@selector(didFinishLoadingImageType:forProduct:)])
                        dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        [self.delegate didFinishLoadingImageType:type forProduct:product];
                    });
                }
            }
        }] resume];
    }
}

#pragma mark - misc
- (void) confirmProductAtStation:(Product *)product completion:(void (^)(BOOL success))callBack
{
    NSString * urlString = [CreateAPIStrings confirmProductAtAnchor:product];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
        
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
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
                dispatch_sync(dispatch_get_main_queue(), ^
                {
                    callBack(NO);
                });
            }
            else
            {
                if ( [[dictionaryResponse valueForKey:@"responseCode"] intValue] != 0 )
                {
                    dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        callBack(NO);
                    });
                }
                else
                {
                    product.anchorStatus = @"At Station";
                    product.myOrder.anchorStatus = @"At Station";
                    dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        callBack(YES);
                    });
                }
            }
        }] resume];
    }];
}


- (NSArray *) searchOrders:(NSArray *)orders withString:(NSString *)searchString
{
    searchString = [searchString lowercaseString];
    NSMutableArray * filteredOrders = [[NSMutableArray alloc] init];
    
    for ( int i = 0; i < [orders count]; i++ )
    {
        Order * tmpOrder = [orders objectAtIndex:i];
        
        if ( [[[self.myDateFormatter stringFromDate:tmpOrder.placeTime] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpOrder.orderId] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@ %@", tmpOrder.buyerFirstName, tmpOrder.buyerLastName] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpOrder.buyerEmail] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpOrder.buyerPhoneNumber] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpOrder.runnerId] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[[NSString stringWithFormat:@"%@", tmpOrder.runnerStatus] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
            [[tmpOrder.status lowercaseString] rangeOfString:searchString].location != NSNotFound )
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
            [[tmpProduct.status lowercaseString] rangeOfString:searchString].location != NSNotFound )
        {
            [filteredProducts addObject:tmpProduct];
        }
    }
    
    return filteredProducts;
}

- (void) confirmDeliveryForOrder:(Order *)order completion:(void (^)(BOOL success))callBack
{
    NSString * urlString = [CreateAPIStrings confirmOrderDelivery:order];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            NSDictionary * dictionaryResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSString * responseStatus = [DataMethods checkForNull:[dictionaryResponse valueForKey:@"status"] withAlternative:@""];
               
            if ( error || ! [responseStatus isEqualToString:@"SUCCESS"] )
            {
                if ( error )
                    NSLog(@"error : %@", error);
                else
                    NSLog(@"response : %@", responseStatus);
                
                dispatch_sync(dispatch_get_main_queue(), ^
                {
                    callBack(NO);
                });
            }
            else
            {
                dispatch_sync(dispatch_get_main_queue(), ^
                {
                    order.status = @"Delivered";
                    order.anchorStatus = @"Delivered";
                    for ( int i = 0; i < [order.products count]; i++ )
                    {
                        Product * tmpProduct = (Product *)[order.products objectAtIndex:i];
                        tmpProduct.anchorStatus = @"Delivered";
                    }
                    callBack(YES);
                    
                    //the below /*code*/ could be used for automatic printing
                    //remember to comment out the above callBack(YES) if you are going to use automatic printing
                    /*
                    [self.myPrintManager printReceiptForOrder:order completion:^(BOOL success)
                    {
                        if ( success )
                        {
                            if ( [self.delegate respondsToSelector:@selector(didFinishPrintingReceiptForOrder:)] )
                                [self.delegate didFinishPrintingReceiptForOrder:order];
                        }
                        else
                        {
                            if ( [self.delegate respondsToSelector:@selector(didFailPrintingReceiptForOrder:)] )
                                [self.delegate didFailPrintingReceiptForOrder:order];
                        }
                        
                        callBack(YES);
                    }];
                     */
                });
            }
        }] resume];
    }];
}

- (void) overrideConfirmOrderAtStation:(Order *)order completion:(void (^)(NSString *))callBack
{
    NSString * urlString = [CreateAPIStrings overrideConfirmOrderAtStation:order];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            if ( error )
            {
                NSLog(@"error : %@", error);
                dispatch_sync(dispatch_get_main_queue(), ^
                {
                    callBack([NSString stringWithFormat:@"%@", error]);
                });
            }
            else
            {
                NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                
                NSLog(@"%@", responseDictionary);
                
                if ( [[responseDictionary valueForKey:@"status"] isEqualToString:@"SUCCESS"] )
                {
                    dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        callBack(nil);
                    });
                }
                else
                {
                    dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        callBack([responseDictionary valueForKey:@"status"]);
                        //callBack([[responseDictionary valueForKey:@"messageBean"] valueForKey:@"message"]);
                    });
                }
            }
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
            if ( error )
            {
                NSLog(@"error : %@", error);
                dispatch_sync(dispatch_get_main_queue(), ^
                {
                    callBack(NO);
                });
            }
            else
            {
                NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                NSLog(@"%@", responseDictionary);
                if ( [[responseDictionary valueForKey:@"status"] isEqualToString:@"SUCCESS"] )
                {
                    dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        callBack(YES);
                    });
                }
                else
                {
                    dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        callBack(NO);
                    });
                }
            }
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
            if ( error )
            {
                NSLog(@"error : %@", error);
                dispatch_sync(dispatch_get_main_queue(), ^
                {
                    callBack(NO);
                });
            }
            else
            {
                NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                NSLog(@"%@", responseDictionary);
                if ( [[responseDictionary valueForKey:@"status"] isEqualToString:@"SUCCESS"] )
                {
                    dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        callBack(YES);
                    });
                }
                else
                {
                    dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        callBack(NO);
                    });
                }
            }
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
            if ( error )
            {
                NSLog(@"error : %@", error);
                dispatch_sync(dispatch_get_main_queue(), ^
                {
                    callBack(NO);
                });
            }
            else
            {
                NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                NSLog(@"%@", responseDictionary);
                if ( [[responseDictionary valueForKey:@"status"] isEqualToString:@"SUCCESS"] )
                {
                    dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        callBack(YES);
                    });
                }
                else
                {
                    dispatch_sync(dispatch_get_main_queue(), ^
                    {
                        callBack(NO);
                    });
                }
            }
        }] resume];
    }];
}

- (BOOL) allItemsAreAtStationForOrder:(Order *)order
{
    for ( int i = 0; i < [order.products count]; i++ )
    {
        if ( ! [[(Product *)[order.products objectAtIndex:i] anchorStatus] isEqualToString:@"At Station"] && ! [[(Product *)[order.products objectAtIndex:i] status] isEqualToString:@"Cancelled"])
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
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"PurchaseReceipt_%@.jpg\"\r\n", FileParamConstant, order.orderId] dataUsingEncoding:NSUTF8StringEncoding]];
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

@end