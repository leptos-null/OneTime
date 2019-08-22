//
//  OTPTime.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPTime.h"

@implementation OTPTime

+ (unsigned)type {
    return 'time';
}
+ (NSString *)domain {
    return @"totp";
}

+ (NSTimeInterval)defaultStep {
    return 30;
}

- (instancetype)init {
    if (self = [super init]) {
        _step = [[self class] defaultStep];
    }
    return self;
}

- (instancetype)initWithKey:(NSData *)key algorithm:(CCHmacAlgorithm)algorithm digits:(size_t)digits {
    return [self initWithKey:key algorithm:algorithm digits:digits step:[[self class] defaultStep]];
}

- (instancetype)initWithKey:(NSData *)key algorithm:(CCHmacAlgorithm)algorithm digits:(size_t)digits step:(NSTimeInterval)step {
    if (self = [super initWithKey:key algorithm:algorithm digits:digits]) {
        _step = step;
    }
    return self;
}

- (instancetype)initWithKey:(NSData *)key properties:(NSDictionary *)properties version:(OTPropertiesVersion)version {
    if (self = [super initWithKey:key properties:properties version:version]) {
        switch (version) {
            case OTPropertiesVersion1:
                _step = [properties[OTPStepPropertyKey] doubleValue];
                break;
                
            default:
                break;
        }
    }
    return self;
}

- (NSString *)passwordForDate:(NSDate *)date {
    uint64_t factor = date.timeIntervalSince1970 / self.step;
    return [super passwordForFactor:factor];
}

- (NSString *)password {
    return [self passwordForDate:[NSDate date]];
}

- (NSDate *)nextStepPeriodForDate:(NSDate *)date {
    NSTimeInterval const step = self.step;
    // ceil should not be used here, because theoretically date/step may have a 0 fraction
    NSTimeInterval const next = (floor(date.timeIntervalSince1970 / step) + 1) * step;
    return [NSDate dateWithTimeIntervalSince1970:next];
}

- (NSDictionary *)properties {
    NSMutableDictionary *props = [[super properties] mutableCopy];
    props[OTPStepPropertyKey] = @(self.step);
    return props;
}

- (NSURLQueryItem *)specificQuery {
    return [NSURLQueryItem queryItemWithName:@"period" value:@(self.step).stringValue];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, step: %f", [super description], self.step];
}

@end
