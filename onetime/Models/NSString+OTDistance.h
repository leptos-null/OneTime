//
//  NSString+OTDistance.h
//  OneTime
//
//  Created by Leptos on 8/23/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (OTDistance)

- (NSUInteger)longestCommonSubsequence:(NSString *)string options:(NSStringCompareOptions)options;

@end
