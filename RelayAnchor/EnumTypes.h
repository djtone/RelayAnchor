//
//  EnumTypes.h
//  RelayAnchor
//
//  Created by chuck johnston on 4/17/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LoadOrderStatus)
{
    kLoadOrderStatusAll,
    kLoadOrderStatusOpen,
    kLoadOrderStatusReady,
    kLoadOrderStatusDelivered,
    kLoadOrderStatusCancelledReturned,
    kLoadOrderStatusCount
};

typedef NS_ENUM(NSUInteger, BottomViewStatus)
{
    kBottomViewStatusNil,
    kBottomViewStatusOpen,
    kBottomViewStatusReady,
    kBottomViewStatusDelivered,
    kBottomViewStatusCancelledReturned,
    kBottomViewStatusCount
};

#pragma mark - statuses for order objects
typedef NS_ENUM(NSUInteger, Status)
{
    kStatusNil,
    kStatusOpen,
    kStatusAtStation,
    kStatusDelivered,
    kStatusCancelled,
    kStatusReturned,
    kStatusReturnRejected,
    kStatusCount
};

typedef NS_ENUM(NSUInteger, RunnerStatus)
{
    kRunnerStatusNil,
    kRunnerStatusRunning,
    kRunnerStatusPickedUp,
    kRunnerStatusAtStation,
    kRunnerStatusDelivered,
    kRunnerStatusCount
};

typedef NS_ENUM(NSUInteger, AnchorStatus)
{
    kAnchorStatusNil,
    kAnchorStatusRunning,
    kAnchorStatusPickedUp,
    kAnchorStatusAtStation,
    kAnchorStatusDelivered,
    kAnchorStatusReturnInitiated,
    kAnchorStatusCount
};

@interface EnumTypes : NSObject

+ (NSString *)stringFromLoadOrderStatus:(LoadOrderStatus)loadOrderStatus;
+ (NSString *)stringFromBottomViewStatus:(BottomViewStatus)bottomViewStatus;
+ (NSString *)stringFromStatus:(Status)status;
+ (NSString *)stringFromRunnerStatus:(RunnerStatus)runnerStatus;
+ (NSString *)stringFromAnchorStatus:(AnchorStatus)anchorStatus;
+ (int)enumFromString:(NSString *)enumString;

+ (int)LoadOrderStatusFromBottomViewStatus:(BottomViewStatus)bottomViewStatus;

@end
