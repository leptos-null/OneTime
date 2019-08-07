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

@implementation OTBag

- (instancetype)initWithGenerator:(OTPBase *)generator {
    if (self = [super init]) {
        _generator = generator;
        
        uint8_t bytes[16];
        arc4random_buf(bytes, sizeof(bytes));
        NSMutableString *serial = [NSMutableString stringWithCapacity:(sizeof(bytes) * 2)];
        for (size_t i = 0; i < sizeof(bytes); i++) {
            [serial appendFormat:@"%02hhx", bytes[i]];
        }
        _uniqueIdentifier = [serial copy];
    }
    return self;
}

- (instancetype)initWithKeychainAttributes:(NSDictionary *)attributes {
    if (self = [super init]) {
        unsigned generatorType = [attributes[(NSString *)kSecAttrType] unsignedIntValue];
        
        NSData *props = attributes[(NSString *)kSecAttrGeneric];
        if (!props) {
            return nil;
        }
        NSDictionary *properties = [NSPropertyListSerialization propertyListWithData:props options:0 format:NULL error:NULL];
        NSData *key = attributes[(NSString *)kSecValueData];
        
        OTPBase *generator;
        if (generatorType == [OTPBase type]) {
            return nil;
        } else if (generatorType == [OTPHash type]) {
            generator = [[OTPHash alloc] initWithKey:key properties:properties];
        } else if (generatorType == [OTPTime type]) {
            generator = [[OTPTime alloc] initWithKey:key properties:properties];
        } else {
            return nil;
        }
        _uniqueIdentifier = attributes[(NSString *)kSecAttrAccount];
        _account = attributes[(NSString *)kSecAttrLabel];
        _issuer = attributes[(NSString *)kSecAttrService];
    }
    return self;
}

- (OSStatus)addToKeychain {
    if (self.keychainAttributes) {
        return noErr;
    }
    
    NSNumber *generatorType = [NSNumber numberWithUnsignedInt:self.generator.type];
    NSData *props = [NSPropertyListSerialization dataWithPropertyList:self.generator.properties format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
    
    CFMutableDictionaryRef attribs = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
    CFDictionarySetValue(attribs, kSecClass, kSecClassGenericPassword);
    CFDictionarySetValue(attribs, kSecValueData, (__bridge CFDataRef)self.generator.key);
    CFDictionarySetValue(attribs, kSecAttrSynchronizable, kCFBooleanTrue);
    CFDictionarySetValue(attribs, kSecReturnAttributes, kCFBooleanTrue);
    CFDictionarySetValue(attribs, kSecReturnData, kCFBooleanTrue);
    CFDictionarySetValue(attribs, kSecAttrGeneric, (__bridge CFDataRef)props);
    CFDictionarySetValue(attribs, kSecAttrAccount, (__bridge CFStringRef)self.uniqueIdentifier);
    CFDictionarySetValue(attribs, kSecAttrLabel, (__bridge CFStringRef)self.account);
    CFDictionarySetValue(attribs, kSecAttrService, (__bridge CFStringRef)self.issuer);
    CFDictionarySetValue(attribs, kSecAttrType, (__bridge CFNumberRef)generatorType);
    CFDictionarySetValue(attribs, kSecAttrDescription, CFSTR("One-Time Password Generator"));
    
    CFTypeRef result;
    OSStatus ret = SecItemAdd(attribs, &result);
    _keychainAttributes = CFBridgingRelease(result);
    return ret;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> issuer: %@, account: %@", [self class], self, self.issuer, self.account];
}

@end
