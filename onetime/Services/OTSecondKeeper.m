//
//  OTSecondKeeper.m
//  onetime
//
//  Created by Leptos on 8/18/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTSecondKeeper.h"

@implementation OTSecondKeeper

+ (NSNotificationCenter *)keepCenter {
    static NSNotificationCenter *keep;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keep = [NSNotificationCenter new];
    });
    return keep;
}

+ (NSNotificationName)everySecondName {
    return @"OTEverySecondNotification";
}

+ (void)initialize {
    NSDate *first = [NSDate dateWithTimeIntervalSinceReferenceDate:floor(NSDate.timeIntervalSinceReferenceDate) + 1];
    NSTimer *timer = [[NSTimer alloc] initWithFireDate:first interval:1 repeats:YES block:^(NSTimer *timer) {
        [[self keepCenter] postNotificationName:[self everySecondName] object:nil];
    }];
    [NSRunLoop.mainRunLoop addTimer:timer forMode:NSDefaultRunLoopMode];
}

@end
