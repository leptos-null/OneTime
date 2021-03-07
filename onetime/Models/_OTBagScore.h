//
//  _OTBagScore.h
//  OneTime
//
//  Created by Leptos on 8/24/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../OneTimeKit/Models/OTBag.h"

@interface _OTBagScore : NSObject

@property (strong, nonatomic, readonly) OTBag *bag;
@property (nonatomic, readonly) NSInteger score;

+ (instancetype)bagScoreWithBag:(OTBag *)bag score:(NSInteger)score;
- (instancetype)initWithBag:(OTBag *)bag score:(NSInteger)score;

@end
