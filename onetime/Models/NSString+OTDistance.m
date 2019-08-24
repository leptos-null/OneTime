//
//  NSString+OTDistance.m
//  onetime
//
//  Created by Leptos on 8/23/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "NSString+OTDistance.h"

@implementation NSString (OTDistance)

// https://github.com/koyachi/NSString-LevenshteinDistance
- (NSUInteger)levenshteinDistance:(NSString *)string {
    NSUInteger const width = string.length + 1, height = self.length + 1;
    NSUInteger x, y, *distances = calloc(width * height, sizeof(*distances));
    
    for (y = 0; y < height; y++) {
        distances[y * width] = y;
    }
    for (x = 0; x < width; x++) {
        distances[x] = x;
    }
    
    for (y = 1; y < height; y++) {
        for (x = 1; x < width; x++) {
            NSInteger cost = [self characterAtIndex:(y - 1)] != [string characterAtIndex:(x - 1)];
            
            NSUInteger insert  = distances[(y - 1) * width + x] + 1;
            NSUInteger remove  = distances[y * width + (x - 1)] + 1;
            NSUInteger replace = distances[(y - 1) * width + (x - 1)] + cost;
            distances[y * width + x] = MIN(MIN(insert, remove), replace);
        }
    }
    NSUInteger ret = distances[height * width - 1];
    free(distances);
    return ret;
}

// https://stackoverflow.com/a/26790799
- (NSUInteger)longestCommonSubsequence:(NSString *)string {
    NSUInteger const width = string.length + 1, height = self.length + 1;
    NSUInteger x, y, *distances = calloc(width * height, sizeof(*distances));
    
    for (y = 1; y < height; y++) {
        for (x = 1; x < width; x++) {
            distances[y * width + x] = ([self characterAtIndex:(y - 1)] == [string characterAtIndex:(x - 1)]) ? ({
                1 + distances[(y - 1) * width + (x - 1)];
            }) : ({
                MAX(distances[(y - 1) * width + x],
                    distances[y * width + (x - 1)]);
            });
        }
    }

    NSUInteger ret = distances[height * width - 1];
    free(distances);
    return ret;
}

@end
