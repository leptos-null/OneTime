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

- (instancetype)initWithKey:(NSData *)key properties:(NSDictionary *)properties version:(OTPropertiesVersion)version {
    if (self = [super initWithKey:key properties:properties version:version]) {
        switch (version) {
            case OTPropertiesVersion1:
                _counter = [properties[OTPCounterPropertyKey] unsignedLongLongValue];
                break;
                
            default:
                break;
        }
    }
    return self;
}

- (instancetype)initWithURLComponents:(NSURLComponents *)urlComponents {
    if (self = [super initWithURLComponents:urlComponents]) {
        uint64_t counter = [[self class] defaultCounter];
        
        for (NSURLQueryItem *queryItem in urlComponents.queryItems) {
            if ([queryItem.name isEqualToString:@"counter"]) {
                counter = strtoull(queryItem.value.UTF8String, NULL, 10);
            }
        }
    }
    return self;
}

- (uint64_t)factor {
    return _counter;
}

- (void)incrementCounter {
    _counter++;
}

- (NSDictionary *)properties {
    NSMutableDictionary *props = [[super properties] mutableCopy];
    props[OTPCounterPropertyKey] = @(self.counter);
    return props;
}

- (NSArray<NSURLQueryItem *> *)queryItems {
    NSArray<NSURLQueryItem *> *items = [super queryItems];
    return [items arrayByAddingObject:[NSURLQueryItem queryItemWithName:@"counter" value:@(self.counter).stringValue]];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, counter: %" __UINT64_FMTu__, [super description], self.counter];
}

@end
