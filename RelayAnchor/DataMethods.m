//
//  DataMethods.m
//  RelayAnchor
//
//  Created by chuck on 8/22/14.
//  Copyright (c) 2014 Sears Holdings, Inc. All rights reserved.
//

#import "DataMethods.h"

@implementation DataMethods

+ (id) checkForNull:(id)dataObject withAlternative:(id)alternative
{
    if ( [dataObject class] ==  nil || [dataObject class] == [NSNull class] )
        return alternative;
    
    return dataObject;
}

+ (NSString *) formmatedPhoneNumber:(NSNumber *)phoneNumber
{
    //phoneNumber = [
    return @"";
}

@end
