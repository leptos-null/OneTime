//
//  OTPBase.h
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

#define OTPDigitPropertyKey @"null.leptos.onetime.base.digits"
#define OTPAlgorithmPropertyKey @"null.leptos.onetime.base.algorithm"

// abstract superclass, do not use directly
@interface OTPBase : NSObject

@property (class, readonly) unsigned type;
// mirror of the class property
@property (nonatomic, readonly) unsigned type;

@property (strong, nonatomic, readonly) NSData *key;
@property (nonatomic, readonly) CCHmacAlgorithm algorithm;
@property (nonatomic, readonly) size_t digits;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithKey:(NSData *)key algorithm:(CCHmacAlgorithm)algorithm digits:(size_t)digits;
- (instancetype)initWithKey:(NSData *)key properties:(NSDictionary *)properties;

- (NSString *)passwordForFactor:(uint64_t)factor;

// subclasses should provide a default `factor` implementation
- (NSString *)password;

- (NSDictionary *)properties;

@end
