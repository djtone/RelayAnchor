//
//  Mall.h
//  RelayAnchor
//
//  Created by chuck johnston on 3/20/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Mall : NSObject

@property NSString * name;
@property NSString * mallId;
@property NSString * sessionKey;

@property NSMutableDictionary * details;

@end
