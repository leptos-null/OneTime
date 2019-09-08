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
    CCHmacContext _hmactx;
}

static BOOL CCDigestLengthForHmacAlgorithm(CCHmacAlgorithm algorithm, size_t *length) {
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
            return NO;
    }
    if (length) {
        *length = macLen;
    }
    return YES;
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

+ (NSData *)randomKeyForAlgorithm:(CCHmacAlgorithm)algorithm {
    /* https://tools.ietf.org/html/rfc2104#section-3
     * "[A key for HMAC] less than L [digest_length] bytes is strongly
     * discouraged as it would decrease the security strength of the
     * function. Keys longer than L bytes are acceptable but the extra
     * length would not significantly increase the function strength."
     */
    size_t digestLength;
    if (!CCDigestLengthForHmacAlgorithm(algorithm, &digestLength)) {
        return nil;
    }
    uint8_t rand[digestLength];
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
    CCHmacAlgorithm const alg = [cls defaultAlgorithm];
    return [self initWithKey:[cls randomKeyForAlgorithm:alg] algorithm:alg digits:[cls defaultDigits]];
}

- (instancetype)initWithKey:(NSData *)key algorithm:(CCHmacAlgorithm)algorithm digits:(size_t)digits {
    if (self = [super init]) {
        // null keys are technically fine
        _key = key;
        // algorithm is validated below
        _algorithm = algorithm;
        // only digits [1, 10] are helpful, but all (unsigned) values are handled appropriately
        _digits = digits;
        
        if (!CCDigestLengthForHmacAlgorithm(algorithm, &_macLength)) {
            return nil;
        }
        CCHmacInit(&_hmactx, algorithm, key.bytes, key.length);
    }
    return self;
}

- (instancetype)initWithKey:(NSData *)key properties:(NSDictionary *)properties version:(OTPropertiesVersion)version {
    switch (version) {
        case OTPropertiesVersion1: {
            CCHmacAlgorithm alg = [properties[OTPAlgorithmPropertyKey] unsignedIntValue];
            size_t digits = [properties[OTPDigitPropertyKey] unsignedLongValue];
            return [self initWithKey:key algorithm:alg digits:digits];
        } break;
            
        default: {
            return nil;
        } break;
    }
}

// based on https://wikipedia.org/wiki/HMAC-based_One-time_Password_algorithm#HOTP_value
- (NSString *)passwordForFactor:(uint64_t)factor {
    factor = htonll(factor);
    
    size_t const digits = self.digits;
    size_t const macLength = _macLength;
    
    uint8_t mac[macLength];
    // apparently the same CCHmacContext is not supposed to be updated
    CCHmacContext hmactx = _hmactx;
    CCHmacUpdate(&hmactx, &factor, sizeof(factor));
    CCHmacFinal(&hmactx, mac);
    
    // top 4 bits
    uint8_t const offset = mac[macLength - 1] & 0xf;
    
    uint32_t head = *(uint32_t *)(mac + offset);
    _Static_assert((sizeof(head) * __CHAR_BIT__) >= 31, "HOTP must be 31 bits");
    head = ntohl(head);
    // mask off the would-be sign bit
    head &= INT32_MAX;
    
    // routine description:
    //   for a value `n` create a string `s` of length `d`
    //   `s` should contain the `d` least significant
    //     base 10 digits of `n`, zero (0) padded if necessary
    uint32_t const base = 10;
    char *const value = malloc(digits);
    for (char *valuePtr = value + digits; value < valuePtr; head /= base) {
        *(--valuePtr) = (head % base) + '0';
    }
    return [[NSString alloc] initWithBytesNoCopy:value length:digits encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

- (uint64_t)factor {
    __builtin_unreachable();
}

- (NSString *)password {
    return [self passwordForFactor:[self factor]];
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
