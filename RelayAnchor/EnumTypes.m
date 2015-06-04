//
//  EnumTypes.m
//  RelayAnchor
//
//  Created by chuck johnston on 4/17/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "EnumTypes.h"

@implementation EnumTypes

+ (NSString *)stringFromLoadOrderStatus:(LoadOrderStatus)loadOrderStatus
{
    switch (loadOrderStatus)
    {
        case kLoadOrderStatusAll:
            return @"LoadOrderStatusAll";
            
        case kLoadOrderStatusOpen:
            return @"LoadOrderStatusOpen";
            
        case kLoadOrderStatusReady:
            return @"LoadOrderStatusReady";
            
        case kLoadOrderStatusDelivered:
            return @"LoadOrderStatusDelivered";
            
        case kLoadOrderStatusCancelledReturned:
            return @"LoadOrderStatusCancelledReturned";
            
        default:
            NSLog(@"Invalid LoadOrderStatus");
            return @"Invalid LoadOrderStatus";
    }
}

+ (NSString *)stringFromBottomViewStatus:(BottomViewStatus)bottomViewStatus
{
    switch (bottomViewStatus)
    {
        case kBottomViewStatusNil:
            return @"BottomViewStatusNil";
            
        case kBottomViewStatusOpen:
            return @"BottomViewStatusOpen";
            
        case kBottomViewStatusReady:
            return @"BottomViewStatusReady";
            
        case kBottomViewStatusDelivered:
            return @"BottomViewStatusDelivered";
            
        case kBottomViewStatusCancelledReturned:
            return @"BottomViewStatusCancelledReturned";
            
        default:
            NSLog(@"Invalid BottomViewStatus");
            return @"Invalid BottomViewStatus";
    }
}

+ (NSString *)stringFromStatus:(Status)status
{
    switch (status)
    {
        case kStatusNil:
            return @"StatusNil";
            
        case kStatusOpen:
            return @"StatusOpen";
            
        case kStatusAtStation:
            return @"StatusAtStation";
            
        case kStatusDelivered:
            return @"StatusDelivered";
            
        case kStatusCancelled:
            return @"StatusCancelled";
            
        case kStatusReturned:
            return @"StatusReturned";
            
        case kStatusReturnRejected:
            return @"StatusReturnRejected";
            
        default:
            NSLog(@"Invalid Status");
            return @"Invalid Status";
    }
}

+ (NSString *)stringFromRunnerStatus:(RunnerStatus)runnerStatus
{
    switch (runnerStatus)
    {
        case kRunnerStatusNil:
            return @"RunnerStatusNil";
            
        case kRunnerStatusRunning:
            return @"RunnerStatusRunning";
            
        case kRunnerStatusPickedUp:
            return @"RunnerStatusPickedUp";
            
        case kRunnerStatusAtStation:
            return @"RunnerStatusAtStation";
            
        case kRunnerStatusDelivered:
            return @"RunnerStatusDelivered";
            
        default:
            NSLog(@"Invalid RunnerStatus");
            return @"Invalid RunnerStatus";
    }
}

+ (NSString *)stringFromAnchorStatus:(AnchorStatus)anchorStatus
{
    switch (anchorStatus)
    {
        case kAnchorStatusNil:
            return @"AnchorStatusNil";
            
        case kAnchorStatusPickedUp:
            return @"AnchorStatusPickedUp";
            
        case kAnchorStatusRunning:
            return @"AnchorStatusRunning";
            
        case kAnchorStatusAtStation:
            return @"AnchorStatusAtStation";
            
        case kAnchorStatusDelivered:
            return @"AnchorStatusDelivered";
            
        case kAnchorStatusReturnInitiated:
            return @"AnchorStatusReturnInitiated";
            
        default:
            NSLog(@"Invalid AnchorStatus");
            return @"Invalid AnchorStatus";
    }
}

+ (int) enumFromString:(NSString *)enumString
{
    for ( int i = 0; i < kLoadOrderStatusCount; i++ )
    {
        if ( [enumString isEqualToString:[EnumTypes stringFromLoadOrderStatus:i]] )
            return i;
    }
    
    for ( int i = 0; i < kBottomViewStatusCount; i++ )
    {
        if ( [enumString isEqualToString:[EnumTypes stringFromBottomViewStatus:i]] )
            return i;
    }
    
    for ( int i = 0; i < kStatusCount; i++ )
    {
        if ( [enumString isEqualToString:[EnumTypes stringFromStatus:i]] )
            return i;
    }
    
    for ( int i = 0; i < kRunnerStatusCount; i++ )
    {
        if ( [enumString isEqualToString:[EnumTypes stringFromStatus:i]] )
            return i;
    }
    
    for ( int i = 0; i < kAnchorStatusCount; i++ )
    {
        if ( [enumString isEqualToString:[EnumTypes stringFromStatus:i]] )
            return i;
    }

    return 0;
}

+ (int) LoadOrderStatusFromBottomViewStatus:(BottomViewStatus)bottomViewStatus
{
    switch (bottomViewStatus)
    {
        case kBottomViewStatusNil:
            NSLog(@"BottomViewStatusNil - returning kLoadOrderStatusAll");
            return kLoadOrderStatusAll;
            
        case kBottomViewStatusOpen:
            return kLoadOrderStatusOpen;
            
        case kBottomViewStatusReady:
            return kLoadOrderStatusReady;
            
        case kBottomViewStatusDelivered:
            return kLoadOrderStatusDelivered;
            
        case kBottomViewStatusCancelledReturned:
            return kLoadOrderStatusCancelledReturned;
            
        default:
            NSLog(@"Invalid BottomViewStatus - returning kLoadOrderStatusAll");
            return kLoadOrderStatusAll;
    }
}

@end
