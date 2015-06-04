//
//  ContactManager.m
//  RelayAnchor
//
//  Created by chuck on 9/15/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "ContactManager.h"
#import "CreateAPIStrings.h"

@implementation ContactManager

+ (void) sendEmailTo:(NSString *)emailAddress withSubject:(NSString *)subject andBody:(NSString *)body completion:(void (^)(BOOL))callBack
{
    NSString * urlString = [CreateAPIStrings sendEmailTo:emailAddress withSubject:subject andBody:body];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
    
    [CreateAPIStrings splitUrl:urlString ForApis:^(NSString *baseUrl, NSString *paramString)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLRequest * request = [CreateAPIStrings createRequestWithBaseUrl:baseUrl paramString:paramString isPostRequest:YES];
         
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
           NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
           NSLog(@"email response : %@", responseDictionary);
           if ( error )
           {
               NSLog(@"error : %@", error);
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

@end
