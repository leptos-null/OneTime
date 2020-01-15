//
//  NSArray+OTMap.m
//  onetime
//
//  Created by Leptos on 1/14/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "NSArray+OTMap.h"

@implementation NSArray (OTMap)

- (NSArray *)map:(id(^)(id))transform {
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ret[idx] = transform(obj);
    }];
    return [ret copy];
}

- (NSArray *)compactMap:(id(^)(id))transform {
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id val = transform(obj);
        if (val) {
            [ret addObject:val];
        }
    }];
    return [ret copy];
}

@end
