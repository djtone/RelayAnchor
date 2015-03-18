//
//  AccountManager.h
//  RelayAnchor
//
//  Created by chuck on 8/16/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AccountManager : NSObject

+ (AccountManager *)sharedInstance;

+ (void) loginWithUser:(NSString *)user password:(NSString *)password andPushToken:(NSString *)pushToken completion:(void (^)(BOOL success))callBack;
+ (void) forgotPasswordForUser:(NSString *)user completion:(void (^)(BOOL success))callBack;
+ (void) synchronizePushToken:(NSData *)newPushToken;

@property BOOL shouldAddPushToken;
@property BOOL shouldUpdatePushToken;

@property NSMutableArray * orderSortPreferences;

@end
