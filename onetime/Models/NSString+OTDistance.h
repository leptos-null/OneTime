//
//  NSString+OTDistance.h
//  onetime
//
//  Created by Leptos on 8/23/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (OTDistance)

- (NSUInteger)levenshteinDistance:(NSString *)string;
- (NSUInteger)longestCommonSubsequence:(NSString *)string;

@end
