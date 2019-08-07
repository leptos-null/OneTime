//
//  OTPTime.h
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPBase.h"

#define OTPStepPropertyKey @"null.leptos.onetime.time.step"

// https://tools.ietf.org/html/rfc6238
@interface OTPTime : OTPBase

@property (nonatomic, readonly) NSTimeInterval step;

- (instancetype)initWithKey:(NSData *)key algorithm:(CCHmacAlgorithm)algorithm digits:(size_t)digits step:(NSTimeInterval)step;

- (NSString *)passwordForDate:(NSDate *)date;

@end
