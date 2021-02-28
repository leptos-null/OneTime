//
//  OTBag.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTBag.h"
#import "OTBag+OTKeychain.h"
#import "OTPHash.h"
#import "OTPTime.h"
#import "NSData+OTBase32.h"

@implementation OTBag {
    NSDictionary *_keychainAttributes; // nil if not added to keychain
}

static inline __pure2 char singleHexChar(uint8_t hex) {
    hex &= 0xf;
    return hex + ((hex < 0xa) ? '0' : ('a' - 0xa));
}

- (NSString *)_createUniqueIdentifier {
    uint8_t bytes[16];
    arc4random_buf(bytes, sizeof(bytes));
    char serial[sizeof(bytes) * 2];
    for (size_t i = 0, j = 0; i < sizeof(bytes); i++) {
        serial[j++] = singleHexChar(bytes[i] >> 4);
        serial[j++] = singleHexChar(bytes[i] >> 0);
    }
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
    NSURLComponents *urlComps = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    // ignore scheme
    
    NSString *issuer = nil;
    for (NSURLQueryItem *queryItem in urlComps.queryItems) {
        if ([queryItem.name isEqualToString:@"issuer"]) {
            issuer = queryItem.value;
        }
    }
    
    OTPBase *generator = nil;
    NSString *domain = url.host;
    if ([domain isEqualToString:OTPHash.domain]) {
        generator = [[OTPHash alloc] initWithURLComponents:urlComps];
    } else if ([domain isEqualToString:OTPTime.domain]) {
        generator = [[OTPTime alloc] initWithURLComponents:urlComps];
    }
    if (!generator) {
        return nil;
    }
    NSString *pathComponent = urlComps.path;
    NSString *leadingPath = @"/";
    NSParameterAssert([pathComponent hasPrefix:leadingPath]);
    pathComponent = [pathComponent substringFromIndex:leadingPath.length];
    NSArray<NSString *> *userInfo = [pathComponent componentsSeparatedByString:@":"];
    // "Neither issuer nor account name may themselves contain a colon"
    NSString *account = nil;
    switch (userInfo.count) {
        case 1:
            account = userInfo[0];
            break;
        case 2:
            if (!issuer) {
                issuer = userInfo[0];
            }
            account = userInfo[1];
            break;
        default:
            return nil;
    }
    
    if (self = [self initWithGenerator:generator]) {
        _issuer = issuer;
        _account = account;
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
        NSNumber *versionObj = properties[OTPropertiesVersionPropertyKey];
        if (!OTKindofClass(versionObj, NSNumber)) {
            return nil;
        }
        OTPropertiesVersion const version = versionObj.integerValue;
        OTPBase *generator;
        if (generatorType == OTPHash.type) {
            generator = [[OTPHash alloc] initWithKey:key properties:properties version:version];
        } else if (generatorType == OTPTime.type) {
            generator = [[OTPTime alloc] initWithKey:key properties:properties version:version];
        } else {
            return nil;
        }
        switch (version) {
            case OTPropertiesVersion1: {
                NSNumber *idxObj = properties[OTBagIndexPropertyKey];
                if (OTKindofClass(idxObj, NSNumber)) {
                    _index = idxObj.integerValue;
                }
            } break;
                
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


- (NSURL *)URL {
    NSURLQueryItem *issuerItem = [NSURLQueryItem queryItemWithName:@"issuer" value:self.issuer];
    
    NSURLComponents *urlComps = [NSURLComponents new];
    urlComps.scheme = @"otpauth";
    urlComps.host = [[self.generator class] domain];
    urlComps.path = [NSString stringWithFormat:@"/%@:%@", self.issuer, self.account];
    urlComps.queryItems = [self.generator.queryItems arrayByAddingObject:issuerItem];
    
    return urlComps.URL;
}

NSInteger OTBagCompareUsingIndex(OTBag *a, OTBag *b, void *context) {
    return a.index - b.index;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> generator: %@, issuer: %@, account: %@, index: %@",
            [self class], self, self.generator, self.issuer, self.account, @(self.index)];
}

@end

@implementation OTBag (OTKeychain)

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
    NSDictionary *keychainAttributes = _keychainAttributes;
    if ([keychainAttributes[(NSString *)kSecAttrAccount] isEqualToString:self.uniqueIdentifier]) {
        OSStatus ret = SecItemUpdate((__bridge CFDictionaryRef)[self _uniqueKeychainQuery], (__bridge CFDictionaryRef)attribs);
        if (ret == errSecSuccess) {
            NSMutableDictionary *updatedAttributes = [keychainAttributes mutableCopy];
            [updatedAttributes addEntriesFromDictionary:attribs];
            _keychainAttributes = [updatedAttributes copy];
        }
        return ret;
    }
    attribs[(NSString *)kSecClass] = (NSString *)kSecClassGenericPassword;
    // if I were to do this again, I would save the base32 encoded key,
    //   so that the key would show up in Keychain app
    // (changing this behavior now would break compatibility)
    attribs[(NSString *)kSecValueData] = self.generator.key;
    
    attribs[(NSString *)kSecAttrSynchronizable] = @(YES);
    attribs[(NSString *)kSecAttrAccount] = self.uniqueIdentifier;
    attribs[(NSString *)kSecAttrType] = [NSNumber numberWithUnsignedInt:[[self.generator class] type]];
    attribs[(NSString *)kSecAttrDescription] = @"One-Time Password Generator";
    
    attribs[(NSString *)kSecReturnAttributes] = @(YES);
    attribs[(NSString *)kSecReturnData] = @(YES);
    
    CFTypeRef result = NULL;
    OSStatus ret = SecItemAdd((__bridge CFDictionaryRef)attribs, &result);
    _keychainAttributes = CFBridgingRelease(result);
    return ret;
}

- (OSStatus)deleteFromKeychain {
    return SecItemDelete((__bridge CFDictionaryRef)[self _uniqueKeychainQuery]);
}

@end
