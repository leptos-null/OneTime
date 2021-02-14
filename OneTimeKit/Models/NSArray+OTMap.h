//
//  NSArray+OTMap.h
//  onetime
//
//  Created by Leptos on 1/14/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray<__covariant ObjectType> (OTMap)

/// Returns an array containing the results of calling the given transformation with each element of the receiver
- (NSArray *)map:(id(^)(ObjectType obj))transform;
/// Returns an array containing the non-nil results of calling the given transformation with each element of the receiver
- (NSArray *)compactMap:(id(^)(ObjectType obj))transform;

@end
