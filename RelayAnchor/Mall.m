//
//  Mall.m
//  RelayAnchor
//
//  Created by chuck johnston on 3/20/15.
//  Copyright (c) 2015 Sears Holdings, Inc. All rights reserved.
//

#import "Mall.h"

@implementation Mall

- (id) init
{
    if ( self = [super init] )
    {
        //contact tab
        self.details = [[NSMutableDictionary alloc] init];
        
        NSMutableDictionary * nameAndAddress = [[NSMutableDictionary alloc] init];
        [nameAndAddress setValue:@"Apple" forKey:@"Store Name"];
        [nameAndAddress setValue:@"100 Oakbrook Center" forKey:@"Address"];
        [nameAndAddress setValue:@"Oak Brook" forKey:@"City"];
        [nameAndAddress setValue:@"Illinois" forKey:@"State"];
        [nameAndAddress setValue:@"60523" forKey:@"Zip Code"];
        
        NSMutableDictionary * contactInfo = [[NSMutableDictionary alloc] init];
        [contactInfo setValue:@"David Smith" forKey:@"Contact Name"];
        [contactInfo setValue:@"(630) 573-7008" forKey:@"Phone"];
        [contactInfo setValue:@"(630) 573-7009" forKey:@"Fax"];
        
        NSMutableDictionary * contact = [[NSMutableDictionary alloc] init];
        [contact setValue:nameAndAddress forKey:@"Name and Address"];
        [contact setValue:contactInfo forKey:@"Contact Info"];
        [self.details setValue:contact forKey:@"Contact"];
        
        //business tab
        NSMutableDictionary * orderNotification = [[NSMutableDictionary alloc] init];
        [orderNotification setValue:@"apple@oakbrookmall.com" forKey:@"Email"];
        
        NSMutableDictionary * businessDescription = [[NSMutableDictionary alloc] init];
        [businessDescription setValue:@"Music, Books & Entertainment, Technology & Electronics" forKey:@"Description"];
        
        NSMutableDictionary * business = [[NSMutableDictionary alloc] init];
        [business setValue:orderNotification forKey:@"Order Notification"];
        [business setValue:businessDescription forKey:@"Business Description"];
        [self.details setValue:business forKey:@"Business"];
        
        //security tab
        NSMutableDictionary * loginInformation = [[NSMutableDictionary alloc] init];
        [loginInformation setValue:@"apple@oakbrookmall.com" forKey:@"Email"];
        
        NSMutableDictionary * security = [[NSMutableDictionary alloc] init];
        [security setValue:loginInformation forKey:@"Login Information"];
        [self.details setValue:security forKey:@"Security"];
    }
    return self;
}

@end
