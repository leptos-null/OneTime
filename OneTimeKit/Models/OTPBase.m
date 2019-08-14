//
//  OTPBase.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPBase.h"

@implementation OTPBase {
    size_t _macLength;
}

+ (unsigned)type {
    return 'base';
}
- (unsigned)type {
    return [[self class] type];
}

+ (NSString *)domain {
    return @"otp";
}
- (NSString *)domain {
    return [[self class] domain];
}

+ (NSData *)randomKey {
    uint8_t rand[20];
    arc4random_buf(rand, sizeof(rand));
    return [NSData dataWithBytes:rand length:sizeof(rand)];
}
+ (CCHmacAlgorithm)defaultAlgorithm {
    return kCCHmacAlgSHA1;
}
+ (size_t)defaultDigits {
    return 6;
}

- (instancetype)init {
    Class const cls = [self class];
    return [self initWithKey:[cls randomKey] algorithm:[cls defaultAlgorithm] digits:[cls defaultDigits]];
}

- (instancetype)initWithKey:(NSData *)key algorithm:(CCHmacAlgorithm)algorithm digits:(size_t)digits {
    if (self = [super init]) {
        _key = key;
        _algorithm = algorithm;
        _digits = digits;
        
        size_t macLen;
        switch (algorithm) {
            case kCCHmacAlgSHA1:
                macLen = CC_SHA1_DIGEST_LENGTH;
                break;
            case kCCHmacAlgMD5:
                macLen = CC_MD5_DIGEST_LENGTH;
                break;
            case kCCHmacAlgSHA256:
                macLen = CC_SHA256_DIGEST_LENGTH;
                break;
            case kCCHmacAlgSHA384:
                macLen = CC_SHA384_DIGEST_LENGTH;
                break;
            case kCCHmacAlgSHA512:
                macLen = CC_SHA512_DIGEST_LENGTH;
                break;
            case kCCHmacAlgSHA224:
                macLen = CC_SHA224_DIGEST_LENGTH;
                break;
            default:
                // unknown algorithm
                return nil;
        }
        
        _macLength = macLen;
    }
    return self;
}

- (instancetype)initWithKey:(NSData *)key properties:(NSDictionary *)properties {
    CCHmacAlgorithm alg = [properties[OTPAlgorithmPropertyKey] unsignedIntValue];
    size_t digits = [properties[OTPDigitPropertyKey] unsignedLongValue];
    return [self initWithKey:key algorithm:alg digits:digits];
}

// based on https://wikipedia.org/wiki/HMAC-based_One-time_Password_algorithm#HOTP_value
- (NSString *)passwordForFactor:(uint64_t)factor {
    factor = htonll(factor);
    // put everything we need in local variables to avoid any
    // property values changing in the middle of the procedure
    uint8_t const base = 10;
    NSData *const secretKey = self.key;
    CCHmacAlgorithm const alg = self.algorithm;
    size_t const digits = self.digits;
    size_t const macLength = _macLength;
    
    uint8_t mac[macLength];
    // see git history for using CCHmac family
    // the mac was incorrect when called during a font size change
    CCHmac(alg, secretKey.bytes, secretKey.length, &factor, sizeof(factor), mac);
    
    // top 4 bits
    uint8_t const offset = mac[macLength - 1] & 0xf;
    
    uint32_t head = *(uint32_t *)(mac + offset);
    _Static_assert((sizeof(head) * __CHAR_BIT__) >= 31, "HOTP must be 31 bits");
    head = ntohl(head);
    // mask off the would-be sign bit
    head &= INT32_MAX;
    
    // TODO: Is this the most efficient way of getting the `n` least significant digits?
    
    uint32_t trunc = 1;
    for (size_t td = 0; td < digits; td++) {
        trunc *= 10;
    }
    head %= trunc;
    
    char value[digits];
    char *valuePtr = value;
    valuePtr += digits;
    size_t digitsCpy = digits;
    while (digitsCpy--) {
        *(--valuePtr) = (head % base) + '0';
        head /= base;
    }
    NSString *done = [[NSString alloc] initWithBytes:value length:digits encoding:NSASCIIStringEncoding];
    return done;
}

- (NSString *)password {
    __builtin_unreachable();
}

- (NSDictionary *)properties {
    return @{
        OTPDigitPropertyKey : @(self.digits),
        OTPAlgorithmPropertyKey : @(self.algorithm),
    };
}

- (NSURLQueryItem *)specificQuery {
    __builtin_unreachable();
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> algorithm: %" __UINT32_FMTu__ ", digits: %" __SIZE_FMTu__,
            [self class], self, self.algorithm, self.digits];
}

@end
