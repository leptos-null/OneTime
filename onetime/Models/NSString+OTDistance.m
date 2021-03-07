//
//  NSString+OTDistance.m
//  OneTime
//
//  Created by Leptos on 8/23/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "NSString+OTDistance.h"

@implementation NSString (OTDistance)

// https://stackoverflow.com/a/26790799

- (NSUInteger)_composedLength {
    __block NSUInteger length = 0;
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length)
                             options:NSStringEnumerationByComposedCharacterSequences | NSStringEnumerationSubstringNotRequired
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        length++;
    }];
    return length;
}

- (NSUInteger)longestCommonSubsequence:(NSString *)string options:(NSStringCompareOptions)options {
    NSUInteger const height = [self _composedLength] + 1, width = [string _composedLength] + 1;
    NSUInteger *const distances = calloc(width * height, sizeof(*distances));
    NSUInteger __block x, y = 0;
    
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substringY, NSRange substringRangeY, NSRange enclosingRangeY, BOOL *stopY) {
        y++;
        x = 0;
        [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substringX, NSRange substringRangeX, NSRange enclosingRangeX, BOOL *stopX) {
            x++;
            distances[y * width + x] = ([substringX compare:substringY options:options] == NSOrderedSame) ? ({
                1 + distances[(y - 1) * width + (x - 1)];
            }) : ({
                MAX(distances[(y - 1) * width + x],
                    distances[y * width + (x - 1)]);
            });
        }];
    }];
    NSUInteger ret = distances[height * width - 1];
    free(distances);
    return ret;
}

@end
