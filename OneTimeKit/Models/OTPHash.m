//
//  OTPHash.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPHash.h"

@implementation OTPHash

+ (unsigned)type {
    return 'hash';
}
+ (NSString *)domain {
    return @"hotp";
}

+ (uint64_t)defaultCounter {
    return 1;
}

- (instancetype)init {
    if (self = [super init]) {
        _counter = [[self class] defaultCounter];
    }
    return self;
}

- (instancetype)initWithKey:(NSData *)key algorithm:(CCHmacAlgorithm)algorithm digits:(size_t)digits {
    return [self initWithKey:key algorithm:algorithm digits:digits counter:[[self class] defaultCounter]];
}

- (instancetype)initWithKey:(NSData *)key algorithm:(CCHmacAlgorithm)algorithm digits:(size_t)digits counter:(uint64_t)counter {
    if (self = [super initWithKey:key algorithm:algorithm digits:digits]) {
        _counter = counter;
    }
    return self;
}

- (instancetype)initWithKey:(NSData *)key properties:(NSDictionary *)properties {
    if (self = [super initWithKey:key properties:properties]) {
        _counter = [properties[OTPCounterPropertyKey] unsignedLongLongValue];
    }
    return self;
}

- (NSString *)password {
    NSString *pass = [super passwordForFactor:_counter];
    _counter++;
    return pass;
}

- (NSDictionary *)properties {
    NSMutableDictionary *props = [[super properties] mutableCopy];
    props[OTPCounterPropertyKey] = @(self.counter);
    return props;
}

- (NSURLQueryItem *)specificQuery {
    return [NSURLQueryItem queryItemWithName:@"counter" value:@(self.counter).stringValue];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, counter: %" __UINT64_FMTu__, [super description], self.counter];
}

@end