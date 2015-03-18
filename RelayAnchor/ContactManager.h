//
//  ContactManager.h
//  RelayAnchor
//
//  Created by chuck on 9/15/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContactManager : NSObject

+ (void) sendEmailTo:(NSString *)emailAddress withSubject:(NSString *)subject andBody:(NSString *)body completion:(void (^)(BOOL success))callBack;

@end
