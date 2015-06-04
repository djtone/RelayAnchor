//
//  AccountManager.h
//  RelayAnchor
//
//  Created by chuck on 8/16/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mall.h"

@interface AccountManager : NSObject

+ (AccountManager *)sharedInstance;

+ (void) loginWithUser:(NSString *)user password:(NSString *)password rememberEmail:(BOOL)rememberEmail andPushToken:(NSString *)pushToken completion:(void (^)(BOOL success))callBack;
+ (void) forgotPasswordForUser:(NSString *)user completion:(void (^)(BOOL success))callBack;
+ (void) synchronizePushToken:(NSData *)newPushToken;
+ (void) nearbyMalls:(void(^)(NSArray * malls))callBack;
+ (void) logout:(void(^)())callBack;

@property (nonatomic) NSString * rememberedEmail; //this setter is overriden
@property NSArray * nearbyMalls;
@property Mall * selectedMall;
@property NSMutableArray * authenticatedMalls;

@property BOOL shouldAddPushToken;
@property BOOL shouldUpdatePushToken;

@property NSMutableArray * orderSortPreferences;

@end
