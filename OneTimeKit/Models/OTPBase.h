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

#if DEBUG
#   define debugassert(e, msg) (__builtin_expect(!(e), 0) ? __assert_rtn(__func__, __FILE__, __LINE__, msg) : (void)0)
#else
#   define debugassert(e, msg) ((void)0)
#endif

#define OTKindofClass(obj, cls) ({ \
    BOOL const _iskind = [obj isKindOfClass:[cls class]]; \
    debugassert(_iskind || !obj, # obj " is not kind of " # cls); \
    _iskind; \
})

typedef NS_ENUM(NSInteger, OTPropertiesVersion) {
    OTPropertiesVersionUnknown,
    OTPropertiesVersion1,
    OTPropertiesVersionLatest = OTPropertiesVersion1,
};

// abstract superclass, do not use directly
@interface OTPBase : NSObject
/// A unique identifier that can be used to determine
/// the type of password generation (e.g. time based)
@property (class, nonatomic, readonly) unsigned type;
/// A unique identifier used to determine the type
/// of password generation. The domain should correspond
/// to the scheme @c https://github.com/google/google-authenticator/wiki/Key-Uri-Format
@property (class, strong, nonatomic, readonly) NSString *domain;

/// Generates a cryptographically random key
/// of length recommended for the given algorithm
+ (NSData *)randomKeyForAlgorithm:(CCHmacAlgorithm)algorithm;
@property (class, nonatomic, readonly) CCHmacAlgorithm defaultAlgorithm;
@property (class, nonatomic, readonly) size_t defaultDigits;

/// The shared secret key used by the hashing algorithm
@property (strong, nonatomic, readonly) NSData *key;
/// The algorithm used to generate passwords
@property (nonatomic, readonly) CCHmacAlgorithm algorithm;
/// The number of digits the password is
@property (nonatomic, readonly) size_t digits;

- (instancetype)initWithKey:(NSData *)key algorithm:(CCHmacAlgorithm)algorithm digits:(size_t)digits;
- (instancetype)initWithKey:(NSData *)key properties:(NSDictionary *)properties version:(OTPropertiesVersion)version;
- (instancetype)initWithURLComponents:(NSURLComponents *)urlComponents;

- (NSString *)passwordForFactor:(uint64_t)factor;

// subclasses must provide a default `factor` implementation
- (uint64_t)factor;
- (NSString *)password;

- (NSArray<NSURLQueryItem *> *)queryItems;

// always OTPropertiesVersionLatest
- (NSDictionary *)properties;

@end
