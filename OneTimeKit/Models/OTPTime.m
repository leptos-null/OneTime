//
//  OTPTime.m
//  OneTimeKit
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
            case OTPropertiesVersion1: {
                NSNumber *step = properties[OTPStepPropertyKey];
                _step = OTKindofClass(step, NSNumber) ? step.doubleValue : [[self class] defaultStep];
            } break;
                
            default:
                break;
        }
    }
    return self;
}

- (instancetype)initWithURLComponents:(NSURLComponents *)urlComponents {
    if (self = [super initWithURLComponents:urlComponents]) {
        NSTimeInterval step = [[self class] defaultStep];
        
        for (NSURLQueryItem *queryItem in urlComponents.queryItems) {
            if ([queryItem.name isEqualToString:@"period"]) {
                step = queryItem.value.doubleValue;
            }
        }
        _step = step;
    }
    return self;
}

- (uint64_t)factorForDate:(NSDate *)date {
    return date.timeIntervalSince1970 / self.step;
}

- (uint64_t)factor {
    return [self factorForDate:[NSDate date]];
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

- (NSArray<NSURLQueryItem *> *)queryItems {
    NSArray<NSURLQueryItem *> *items = [super queryItems];
    return [items arrayByAddingObject:[NSURLQueryItem queryItemWithName:@"period" value:@(self.step).stringValue]];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, step: %f", [super description], self.step];
}

@end
