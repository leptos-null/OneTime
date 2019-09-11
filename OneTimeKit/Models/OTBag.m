//
//  OTBag.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTBag.h"
#import "OTPHash.h"
#import "OTPTime.h"
#import "NSData+OTBase32.h"

@implementation OTBag

+ (NSArray<OTBag *> *)keychainBags {
    CFMutableDictionaryRef attribs = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
    CFDictionarySetValue(attribs, kSecClass, kSecClassGenericPassword);
    CFDictionarySetValue(attribs, kSecAttrSynchronizable, kCFBooleanTrue);
    CFDictionarySetValue(attribs, kSecMatchLimit, kSecMatchLimitAll);
    CFDictionarySetValue(attribs, kSecReturnAttributes, kCFBooleanTrue);
    CFDictionarySetValue(attribs, kSecReturnData, kCFBooleanTrue);
    
    CFTypeRef result = NULL;
    SecItemCopyMatching(attribs, &result);
    CFRelease(attribs);
    NSArray *res = CFBridgingRelease(result);
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:res.count];
    for (NSDictionary *attribs in res) {
        OTBag *bag = [[self alloc] initWithKeychainAttributes:attribs];
        if (bag) {
            [ret addObject:bag];
        }
    }
    return ret;
}

/* x86_64 clang 8.0.0 `-Os` assembly of two versions
 *
 * ; (hex < 0xa) ? (hex + '0') : (hex - 0xa + 'a')
 * singleHexChar:
 *         mov     eax, edi  ; eax = edi
 *         and     al, 15    ; ret &= 0xf
 *         cmp     al, 10    ;    (ret < 0xa)
 *         jb      .upperHex ; if             {
 *         add     al, 87    ;     ret += ('a' - 0xa)
 *         ret               ;     return ret
 * .upperHex:                ; }
 *         or      al, 48    ; ret |= '0'
 *         ret               ; return ret
 *
 * ; hex + ((hex < 0xa) ? '0' : ('a' - 0xa))
 * singleHexChar:
 *         and     dil, 15   ; hex &= 0xf
 *         mov     al, 48    ; ret = '0'
 *         cmp     dil, 10   ;    (hex < 0xa)
 *         jb      .addOffst ; if
 *         mov     al, 87    ;                ret = ('a' - 0xa)
 * .addOffst:
 *         add     al, dil   ; ret += hex
 *         ret               ; return ret
 */
static inline __pure2 char singleHexChar(uint8_t hex) {
    hex &= 0xf;
    return hex + ((hex < 0xa) ? '0' : ('a' - 0xa));
}

- (NSString *)_createUniqueIdentifier {
#if 0
    union {
        struct {
            double time;
            uint8_t entropy[8];
        } write;
        uint8_t read[16];
    } bytes;
    _Static_assert(sizeof(bytes.read) == sizeof(bytes.write), "Both components of the union must be of the same size");
    bytes.write.time = CFAbsoluteTimeGetCurrent();
    arc4random_buf(bytes.write.entropy, sizeof(bytes.write.entropy));
    char serial[sizeof(bytes) * 2];
    for (size_t i = 0, j = 0; i < sizeof(bytes); i++) {
        serial[j++] = singleHexChar(bytes.read[i] >> 4);
        serial[j++] = singleHexChar(bytes.read[i] >> 0);
    }
#else
    uint8_t bytes[16];
    arc4random_buf(bytes, sizeof(bytes));
    char serial[sizeof(bytes) * 2];
    for (size_t i = 0, j = 0; i < sizeof(bytes); i++) {
        serial[j++] = singleHexChar(bytes[i] >> 4);
        serial[j++] = singleHexChar(bytes[i] >> 0);
    }
#endif
    return [[NSString alloc] initWithBytes:serial length:sizeof(serial) encoding:NSASCIIStringEncoding];
}

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithGenerator:(OTPBase *)generator {
    if (self = [super init]) {
        _generator = generator;
        _uniqueIdentifier = [self _createUniqueIdentifier];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (!url) {
        return nil;
    }
    if (self = [super init]) {
        NSURLComponents *urlComps = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        // ignore scheme
        CCHmacAlgorithm alg = [OTPBase defaultAlgorithm];
        NSData *key = nil;
        size_t digits = [OTPBase defaultDigits];
        uint64_t counter = [OTPHash defaultCounter];
        NSTimeInterval step = [OTPTime defaultStep];
        
        for (NSURLQueryItem *queryItem in urlComps.queryItems) {
            if ([queryItem.name isEqualToString:@"algorithm"]) {
                if ([queryItem.value isEqualToString:@"SHA1"]) {
                    alg = kCCHmacAlgSHA1;
                } else if ([queryItem.value isEqualToString:@"MD5"]) {
                    alg = kCCHmacAlgMD5;
                } else if ([queryItem.value isEqualToString:@"SHA256"]) {
                    alg = kCCHmacAlgSHA256;
                } else if ([queryItem.value isEqualToString:@"SHA384"]) {
                    alg = kCCHmacAlgSHA384;
                } else if ([queryItem.value isEqualToString:@"SHA512"]) {
                    alg = kCCHmacAlgSHA512;
                } else if ([queryItem.value isEqualToString:@"SHA224"]) {
                    alg = kCCHmacAlgSHA224;
                }
            } else if ([queryItem.name isEqualToString:@"secret"]) {
                key = [[NSData alloc] initWithBase32EncodedString:queryItem.value options:0];
            } else if ([queryItem.name isEqualToString:@"digits"]) {
                digits = queryItem.value.integerValue;
            } else if ([queryItem.name isEqualToString:@"counter"]) {
                counter = strtoull(queryItem.value.UTF8String, NULL, 10);
            } else if ([queryItem.name isEqualToString:@"period"]) {
                step = queryItem.value.doubleValue;
            } else if ([queryItem.name isEqualToString:@"issuer"]) {
                _issuer = queryItem.value;
            }
        }
        
        OTPBase *generator;
        if ([url.host isEqualToString:OTPHash.domain]) {
            generator = [[OTPHash alloc] initWithKey:key algorithm:alg digits:digits counter:counter];
        } else if ([url.host isEqualToString:OTPTime.domain]) {
            generator = [[OTPTime alloc] initWithKey:key algorithm:alg digits:digits step:step];
        }
        if (!generator) {
            return nil;
        }
        NSParameterAssert([urlComps.path hasPrefix:@"/"]); /* these two lines should be looked into */
        NSArray<NSString *> *userInfo = [[urlComps.path substringFromIndex:1] componentsSeparatedByString:@":"];
        // "Neither issuer nor account name may themselves contain a colon"
        if (userInfo.count == 1) {
            _account = userInfo[0];
        } else if (userInfo.count == 2) {
            if (!_issuer) {
                _issuer = userInfo[0];
            }
            _account = userInfo[1];
        } else {
            return nil;
        }
        
        _generator = generator;
        _uniqueIdentifier = [self _createUniqueIdentifier];
    }
    return self;
}

- (instancetype)initWithKeychainAttributes:(NSDictionary *)attributes {
    if (self = [super init]) {
        unsigned generatorType = [attributes[(NSString *)kSecAttrType] unsignedIntValue];
        
        NSData *props = attributes[(NSString *)kSecAttrGeneric];
        NSData *key = attributes[(NSString *)kSecValueData];
        if (!props || !key) {
            return nil;
        }
        NSDictionary *properties = [NSPropertyListSerialization propertyListWithData:props options:0 format:NULL error:NULL];
        if (![properties isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        OTPropertiesVersion const version = [properties[OTPropertiesVersionPropertyKey] integerValue];
        OTPBase *generator;
        if (generatorType == OTPHash.type) {
            generator = [[OTPHash alloc] initWithKey:key properties:properties version:version];
        } else if (generatorType == OTPTime.type) {
            generator = [[OTPTime alloc] initWithKey:key properties:properties version:version];
        } else {
            return nil;
        }
        switch (version) {
            case OTPropertiesVersion1:
                _index = [properties[OTBagIndexPropertyKey] integerValue];
                break;
                
            default:
                break;
        }
        _keychainAttributes = attributes;
        _generator = generator;
        _uniqueIdentifier = attributes[(NSString *)kSecAttrAccount];
        _account = attributes[(NSString *)kSecAttrLabel];
        _issuer = attributes[(NSString *)kSecAttrService];
        _comment = attributes[(NSString *)kSecAttrComment];
    }
    return self;
}

- (NSDictionary *)_uniqueKeychainQuery {
    return @{
        (NSString *)kSecAttrAccount : self.uniqueIdentifier,
        (NSString *)kSecClass : (NSString *)kSecClassGenericPassword,
        (NSString *)kSecAttrSynchronizable : @(YES)
    };
}

- (OSStatus)syncToKeychain {
    NSMutableDictionary *properties = [self.generator.properties mutableCopy];
    properties[OTBagIndexPropertyKey] = @(self.index);
    properties[OTPropertiesVersionPropertyKey] = @(OTPropertiesVersionLatest);
    
    NSError *propListErr = NULL;
    NSData *serialProperties = [NSPropertyListSerialization dataWithPropertyList:properties format:NSPropertyListBinaryFormat_v1_0
                                                                         options:0 error:&propListErr];
    if (propListErr) {
        return errSecCoreFoundationUnknown;
    }
    NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
    attribs[(NSString *)kSecAttrLabel] = self.account ?: @"";
    attribs[(NSString *)kSecAttrService] = self.issuer ?: @"";
    attribs[(NSString *)kSecAttrComment] = self.comment ?: @"";
    attribs[(NSString *)kSecAttrGeneric] = serialProperties;
    
    // be really sure we have the right information
    if ([self.keychainAttributes[(NSString *)kSecAttrAccount] isEqualToString:self.uniqueIdentifier]) {
        OSStatus ret = SecItemUpdate((__bridge CFDictionaryRef)[self _uniqueKeychainQuery], (__bridge CFDictionaryRef)attribs);
        if (ret == errSecSuccess) {
            NSMutableDictionary *props = [self.keychainAttributes mutableCopy];
            [props addEntriesFromDictionary:attribs];
            _keychainAttributes = [props copy];
        }
        return ret;
    }
    attribs[(NSString *)kSecClass] = (NSString *)kSecClassGenericPassword;
    attribs[(NSString *)kSecValueData] = self.generator.key;
    
    attribs[(NSString *)kSecAttrSynchronizable] = @(YES);
    attribs[(NSString *)kSecAttrAccount] = self.uniqueIdentifier;
    attribs[(NSString *)kSecAttrType] = [NSNumber numberWithUnsignedInt:self.generator.type];
    attribs[(NSString *)kSecAttrDescription] = @"One-Time Password Generator";
    
    attribs[(NSString *)kSecReturnAttributes] = @(YES);
    attribs[(NSString *)kSecReturnData] = @(YES);
    
    CFTypeRef result = NULL;
    OSStatus ret = SecItemAdd((__bridge CFDictionaryRef)attribs, &result);
    _keychainAttributes = CFBridgingRelease(result);
    return ret;
}

- (NSURL *)URL {
    NSURLComponents *urlComps = [NSURLComponents new];
    urlComps.scheme = @"otpauth";
    urlComps.host = self.generator.domain;
    urlComps.path = [NSString stringWithFormat:@"/%@:%@", self.issuer, self.account];
    
    NSString *algorithmName = nil;
    switch (self.generator.algorithm) {
        case kCCHmacAlgSHA1:
            algorithmName = @"SHA1";
            break;
        case kCCHmacAlgMD5:
            algorithmName = @"MD5";
            break;
        case kCCHmacAlgSHA256:
            algorithmName = @"SHA256";
            break;
        case kCCHmacAlgSHA384:
            algorithmName = @"SHA384";
            break;
        case kCCHmacAlgSHA512:
            algorithmName = @"SHA512";
            break;
        case kCCHmacAlgSHA224:
            algorithmName = @"SHA224";
            break;
        default:
            // unknown algorithm
            return nil;
    }
    
    NSString *secret = [self.generator.key base32EncodedStringWithOptions:NSDataBase32EncodingOptionsNoPad];
    
    urlComps.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"algorithm" value:algorithmName],
        [NSURLQueryItem queryItemWithName:@"secret" value:secret],
        [NSURLQueryItem queryItemWithName:@"digits" value:@(self.generator.digits).stringValue],
        [NSURLQueryItem queryItemWithName:@"issuer" value:self.issuer],
        self.generator.specificQuery
    ];
    
    return urlComps.URL;
}

NSInteger OTBagCompareUsingIndex(OTBag *a, OTBag *b, void *context) {
    return a.index - b.index;
}

- (OSStatus)deleteFromKeychain {
    return SecItemDelete((__bridge CFDictionaryRef)[self _uniqueKeychainQuery]);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> generator: %@, issuer: %@, account: %@, index: %@",
            [self class], self, self.generator, self.issuer, self.account, @(self.index)];
}

@end
