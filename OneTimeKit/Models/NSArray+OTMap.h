//
//  NSArray+OTMap.h
//  onetime
//
//  Created by Leptos on 1/14/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray<__covariant ObjectType> (OTMap)

- (NSArray *)map:(id(^)(ObjectType obj))transform;
- (NSArray *)compactMap:(id(^)(ObjectType obj))transform;

@end
