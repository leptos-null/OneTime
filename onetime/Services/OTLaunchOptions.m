//
//  OTLaunchOptions.m
//  OneTime
//
//  Created by Leptos on 10/29/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTLaunchOptions.h"

@implementation OTLaunchOptions

+ (OTLaunchOptions *)defaultOptions {
    static id ret;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = [self new];
    });
    return ret;
}

@end
