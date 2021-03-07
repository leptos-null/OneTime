//
//  OTSecondKeeper.m
//  OneTime
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

+ (void)_fireAtTopOfNextSecond {
    struct timespec time;
    clock_gettime(CLOCK_REALTIME, &time);
    time.tv_nsec = 0;
    dispatch_after(dispatch_walltime(&time, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[self keepCenter] postNotificationName:[self everySecondName] object:nil];
        [self _fireAtTopOfNextSecond];
    });
}

+ (void)initialize {
    // seperate method, only because it's probably not a good idea to
    // call `+initialize` multiple times (though it's theoretically safe)
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self _fireAtTopOfNextSecond];
    });
}

@end
