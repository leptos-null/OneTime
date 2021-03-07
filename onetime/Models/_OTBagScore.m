//
//  _OTBagScore.m
//  OneTime
//
//  Created by Leptos on 8/24/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "_OTBagScore.h"

@implementation _OTBagScore

+ (instancetype)bagScoreWithBag:(OTBag *)bag score:(NSInteger)score {
   return [[self alloc] initWithBag:bag score:score];
}

- (instancetype)initWithBag:(OTBag *)bag score:(NSInteger)score {
    if (self = [super init]) {
        _bag = bag;
        _score = score;
    }
    return self;
}

@end
