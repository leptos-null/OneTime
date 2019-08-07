//
//  OTKeychainHelper.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTKeychainHelper.h"

@implementation OTKeychainHelper

+ (NSArray<OTBag *> *)bags {
    CFMutableDictionaryRef attribs = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
    CFDictionarySetValue(attribs, kSecClass, kSecClassGenericPassword);
    CFDictionarySetValue(attribs, kSecAttrSynchronizable, kCFBooleanTrue);
    CFDictionarySetValue(attribs, kSecMatchLimit, kSecMatchLimitAll);
    CFDictionarySetValue(attribs, kSecReturnAttributes, kCFBooleanTrue);
    CFDictionarySetValue(attribs, kSecReturnData, kCFBooleanTrue);
    
    CFTypeRef result;
    SecItemCopyMatching(attribs, &result);
    NSArray *res = CFBridgingRelease(result);
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:res.count];
    for (NSDictionary *attribs in res) {
        OTBag *bag = [[OTBag alloc] initWithKeychainAttributes:attribs];
        if (bag) {
            [ret addObject:bag];
        }
    }
    return ret;
}

@end
