//
//  OTPHash.h
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPBase.h"

#define OTPCounterPropertyKey @"null.leptos.onetime.hash.counter"

// https://tools.ietf.org/html/rfc4226
@interface OTPHash : OTPBase

@property (readonly) uint64_t counter;

- (instancetype)initWithKey:(NSData *)key algorithm:(CCHmacAlgorithm)algorithm digits:(size_t)digits counter:(uint64_t)counter;

@end
