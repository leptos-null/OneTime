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

typedef NS_ENUM(NSInteger, OTPropertiesVersion) {
    OTPropertiesVersionUnknown,
    OTPropertiesVersion1,
    OTPropertiesVersionLatest = OTPropertiesVersion1,
};

// abstract superclass, do not use directly
@interface OTPBase : NSObject

@property (class, nonatomic, readonly) unsigned type;
// mirror of the class property
@property (nonatomic, readonly) unsigned type;

@property (class, strong, nonatomic, readonly) NSString *domain;
// mirror of the class property
@property (strong, nonatomic, readonly) NSString *domain;

+ (NSData *)randomKeyForAlgorithm:(CCHmacAlgorithm)algorithm;
@property (class, nonatomic, readonly) CCHmacAlgorithm defaultAlgorithm;
@property (class, nonatomic, readonly) size_t defaultDigits;

@property (strong, nonatomic, readonly) NSData *key;
@property (nonatomic, readonly) CCHmacAlgorithm algorithm;
@property (nonatomic, readonly) size_t digits;

- (instancetype)initWithKey:(NSData *)key algorithm:(CCHmacAlgorithm)algorithm digits:(size_t)digits;
- (instancetype)initWithKey:(NSData *)key properties:(NSDictionary *)properties version:(OTPropertiesVersion)version;

- (NSString *)passwordForFactor:(uint64_t)factor;

// subclasses should provide a default `factor` implementation
- (uint64_t)factor;
- (NSString *)password;

- (NSURLQueryItem *)specificQuery;

// always OTPropertiesVersionLatest
- (NSDictionary *)properties;

@end
