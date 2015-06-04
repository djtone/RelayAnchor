//
//  AccountManager.m
//  RelayAnchor
//
//  Created by chuck on 8/16/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "AccountManager.h"
#import "CreateAPIStrings.h"
#import "DataMethods.h"
#import "UIAlertView+Blocks.h"
#import "SVProgressHUD.h"

@implementation AccountManager

static AccountManager * sharedAccountManager = nil;

+ (AccountManager *) sharedInstance
{
    if ( sharedAccountManager == nil )
    {
        sharedAccountManager = [[AccountManager alloc] init];
        sharedAccountManager.shouldAddPushToken = NO;
        sharedAccountManager.shouldUpdatePushToken = NO;
        sharedAccountManager.authenticatedMalls = [[NSMutableArray alloc] init];
        sharedAccountManager.rememberedEmail = [[NSUserDefaults standardUserDefaults] valueForKey:@"sellerEmail"];
        
        //needed cause some devices saved old preferences which had different structure. too lazy to check for correct format
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"orderSortPreferences"];
        
        //if no sort preferences are found, create default sort preferences
        if ( ! [[NSUserDefaults standardUserDefaults] valueForKey:@"orderSortPreferences"] )
        {
            sharedAccountManager.orderSortPreferences = [@[@[@"Order Date", @YES],
                                                           @[@"Order ID", @YES],
                                                           @[@"Buyer Name", @YES],
                                                           @[@"Buyer Email", @YES],
                                                           @[@"Buyer Phone", @YES],
                                                           @[@"Runner", @YES],
                                                           @[@"Status", @YES]] mutableCopy];
            
            [[NSUserDefaults standardUserDefaults] setValue:sharedAccountManager.orderSortPreferences forKey:@"orderSortPreferences"];
        }
        else
            sharedAccountManager.orderSortPreferences = [[NSUserDefaults standardUserDefaults] valueForKey:@"orderSortPreferences"];
    }
    return sharedAccountManager;
}

+ (void) loginWithUser:(NSString *)user password:(NSString *)password rememberEmail:(BOOL)rememberEmail andPushToken:(NSString *)pushToken completion:(void (^)(BOOL))callBack
{
    NSString * urlString = [CreateAPIStrings loginWithUser:user password:password andPushToken:pushToken];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSLog(@"login response : %@", responseDictionary);
            NSString * sessionKey = [DataMethods checkForNull:[responseDictionary valueForKey:@"sessionKey"] withAlternative:@""];
            
            if ( error || [sessionKey length] == 0)
            {
                NSLog(@"error : %@", error);
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    callBack(NO);
                });
            }
            else
            {
                if ( [[AccountManager sharedInstance] shouldAddPushToken] )
                {
                    [AccountManager addPushToken:[[NSUserDefaults standardUserDefaults] valueForKey:@"pushTokenString"] completion:^(BOOL success)
                    {
                        if ( success )
                        {
                            /*[[[UIAlertView alloc] initWithTitle:@"Push Token"
                                                        message:@"Push token added successfully"
                                               cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^
                                                                {
                                                                     
                                                                }]
                                               otherButtonItems:nil] show];*/
                        }
                        else
                        {
                            /*[[[UIAlertView alloc] initWithTitle:@"Push Token"
                                                        message:@"Failed to add push token"
                                               cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^
                                                                {
                                                                     
                                                                }]
                                               otherButtonItems:nil] show];*/
                        }
                    }];
                }
                else if ( [[AccountManager sharedInstance] shouldUpdatePushToken] )
                {
                    [AccountManager updatePushToken:[[NSUserDefaults standardUserDefaults] valueForKey:@"pushTokenString"] forOldPushToken:[[NSUserDefaults standardUserDefaults] valueForKey:@"oldPushTokenString"] completion:^(BOOL success)
                    {
                        if ( success )
                        {
                            [[NSUserDefaults standardUserDefaults] setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"pushTokenString"] forKey:@"oldPushTokenString"];
                            /*[[[UIAlertView alloc] initWithTitle:@"Push Token"
                                                        message:@"Push token updated successfully"
                                               cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^
                                                                 {
                                                                     
                                                                 }]
                                               otherButtonItems:nil] show];*/
                        }
                        else
                        {
                            /*[[[UIAlertView alloc] initWithTitle:@"Push Token"
                                                        message:@"Push token failed to update"
                                               cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^
                                                                 {
                                                                     
                                                                 }]
                                               otherButtonItems:nil] show];*/
                        }
                    }];
                }
                
                if ( rememberEmail )
                    [[AccountManager sharedInstance] setRememberedEmail:user];
                else
                    [[AccountManager sharedInstance] setRememberedEmail:nil];
                
                //convert the camelcased name from the reponse to include spaces
                NSString * camelCaseName = [responseDictionary valueForKey:@"sellerName"];
                if ( [camelCaseName isEqualToString:@"OakBrookMall"] )
                    camelCaseName = @"OakbrookMall"; //backend should change their response. oakbrook is one word
                NSMutableString * spacedName = [NSMutableString string];
                
                for ( int i = 0 ; i < camelCaseName.length; i++ )
                {
                    NSString * ch = [camelCaseName substringWithRange:NSMakeRange(i, 1)];
                    if ( [ch rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location != NSNotFound  && i != 0)
                        [spacedName appendString:@" "];

                    [spacedName appendString:ch];
                }
                
                Mall * tmpMall = [[Mall alloc] init];
                tmpMall.name = spacedName;
                tmpMall.name = [tmpMall.name capitalizedString];
                tmpMall.mallId = [responseDictionary valueForKey:@"sellerId"];
                tmpMall.sessionKey = [responseDictionary valueForKey:@"sessionKey"];
                [[AccountManager sharedInstance] setSelectedMall:tmpMall];
                [[[AccountManager sharedInstance] authenticatedMalls] addObject:tmpMall];
                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    callBack(YES);
                });
            }
        }] resume];
     }];
}


+ (void) forgotPasswordForUser:(NSString *)user completion:(void (^)(BOOL success))callBack
{
    NSString * urlString = [CreateAPIStrings forgotPasswordForUser:user];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
        
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSLog(@"forgot password response : %@", responseDictionary);
            
            if ( error )
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    callBack(NO);
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    callBack(NO); //fix this once i set up the forgot password API
                });
            }
            
        }] resume];
    }];
}

+ (void) synchronizePushToken:(NSData *)newPushToken
{
    const unsigned * tokenBytes = [newPushToken bytes];
    NSString * newPushTokenString = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                                     ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                                     ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                                     ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    NSString * oldPushTokenString = [[NSUserDefaults standardUserDefaults] valueForKey:@"pushTokenString"];
    
    if ( [oldPushTokenString length] > 0 )
    {
        if ( ! [newPushTokenString isEqualToString:oldPushTokenString] )
        {
            [[AccountManager sharedInstance] setShouldUpdatePushToken:YES];
            /*[[[UIAlertView alloc] initWithTitle:@"Push Token"
                                        message:@"update push is yes"
                               cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^
                                                 {
                                                     
                                                 }]
                               otherButtonItems:nil] show];*/
        }
    }
    else
    {
        [[AccountManager sharedInstance] setShouldAddPushToken:YES];
        /*[[[UIAlertView alloc] initWithTitle:@"Push Token"
                                    message:@"add push is yes"
                           cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^
                                             {
                                                 
                                             }]
                           otherButtonItems:nil] show];*/
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:newPushTokenString forKey:@"pushTokenString"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (void) addPushToken:(NSString *)pushTokenString completion:(void (^)(BOOL success))callBack
{
    NSString * urlString = [CreateAPIStrings addPushToken:pushTokenString];
    /*[[[UIAlertView alloc] initWithTitle:@"request:"
                                message:urlString
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^
                                         {
                                             //
                                         }]
                       otherButtonItems:nil] show];*/
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            /*NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [[[UIAlertView alloc] initWithTitle:@"addPushToken"
                                            message:[NSString stringWithFormat:@"response: %@", responseDictionary]
                                   cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^
                                                    {
                                                        //
                                                    }]
                                   otherButtonItems:nil] show];
            });*/
            
            
            if ( error )
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    callBack(NO);
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    callBack(YES);
                });
            }
               
        }] resume];
    }];
}

+ (void) updatePushToken:(NSString *)newPushTokenString forOldPushToken:(NSString *)oldPushTokenString completion:(void (^)(BOOL))callBack
{
    NSString * urlString = [CreateAPIStrings updatePushToken:newPushTokenString forOldPushToken:oldPushTokenString];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            /*NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            [[[UIAlertView alloc] initWithTitle:@"updatePushToken"
                                        message:[NSString stringWithFormat:@"%@", responseDictionary]
                               cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^
                                                    {
                                                        
                                                    }]
                                  otherButtonItems:nil] show];*/
               
            if ( error )
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    callBack(NO);
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    callBack(YES);
                });
            }
               
        }] resume];
    }];
}

+ (void) nearbyMalls:(void (^)(NSArray *))callBack
{
    if ( [[AccountManager sharedInstance] nearbyMalls] )
    {
        callBack([[AccountManager sharedInstance] nearbyMalls]);
        return;
    }
        
    NSURLSession * session = [NSURLSession sharedSession];
    NSURLRequest * request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.google.com"]];
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        [NSThread sleepForTimeInterval:1];
        dispatch_async(dispatch_get_main_queue(), ^
        {
            NSArray * tmpMalls = @[@"Oakbrook Mall", @"Water Tower Mall"];
            [[AccountManager sharedInstance] setNearbyMalls:tmpMalls];
            callBack(tmpMalls);
        });
    }] resume];
}

+ (void) logout:(void (^)())callBack
{
    [[AccountManager sharedInstance] setSelectedMall:nil];
    [[[AccountManager sharedInstance] authenticatedMalls] removeAllObjects];
    callBack();
}

- (void) setRememberedEmail:(NSString *)rememberedEmail
{
    [[NSUserDefaults standardUserDefaults] setValue:rememberedEmail forKey:@"sellerEmail"];
    _rememberedEmail = rememberedEmail;
}

@end
