//
//  OTBagCenter.m
//  onetime
//
//  Created by Leptos on 4/19/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "OTBagCenter.h"
#import "../Models/OTBag+OTKeychain.h"
#import "../Models/_OTDemoBag.h"
#import "../Models/NSArray+OTMap.h"

@implementation OTBagCenter {
    NSArray<OTBag *> *_bagCache;
}

+ (OTBagCenter *)defaultCenter {
    static OTBagCenter *center;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [self new];
    });
    return center;
}

- (NSArray<OTBag *> *)keychainBagsCache:(BOOL)hitCache {
    if (!_bagCache || !hitCache) {
#if OTShouldUseDemoBags
        _bagCache = [_OTDemoBag demoBags];
#else
        NSDictionary *attribs = @{
            (NSString *)kSecClass : (NSString *)kSecClassGenericPassword,
            (NSString *)kSecAttrSynchronizable : @(YES),
            (NSString *)kSecMatchLimit : (NSString *)kSecMatchLimitAll,
            (NSString *)kSecReturnAttributes : @(YES),
            (NSString *)kSecReturnData : @(YES)
        };
        
        CFTypeRef result = NULL;
        SecItemCopyMatching((CFDictionaryRef)attribs, &result);
        NSArray<NSDictionary *> *matching = CFBridgingRelease(result);
        NSArray<OTBag *> *bags = [matching compactMap:^OTBag *(NSDictionary *attrs) {
            return [[OTBag alloc] initWithKeychainAttributes:attrs];
        }];
        _bagCache = [bags sortedArrayUsingFunction:OTBagCompareUsingIndex context:NULL];
#endif
    }
    return _bagCache;
}

- (void)addBags:(NSArray<OTBag *> *)bags {
    NSMutableArray<OTBag *> *updateBags = [NSMutableArray arrayWithArray:[self keychainBagsCache:YES]];
    NSMutableArray<OTBag *> *successBags = [NSMutableArray arrayWithCapacity:bags.count];
    
    NSInteger successIndex = updateBags.count;
    for (OTBag *bag in bags) {
        bag.index = successIndex;
        OSStatus const syncStatus = [bag syncToKeychain];
        if (syncStatus == errSecSuccess) {
            updateBags[successIndex] = bag;
            successIndex++;
            [successBags addObject:bag];
        } else {
            [self.observer bagCenter:self bag:bag encounteredError:OTSecErrorToError(syncStatus)];
        }
    }
    _bagCache = [updateBags copy];
    [self.observer bagCenter:self addedBags:successBags];
}

- (void)removeBags:(NSArray<OTBag *> *)bags {
    NSMutableArray<OTBag *> *updateBags = [NSMutableArray arrayWithArray:[self keychainBagsCache:YES]];
    NSMutableArray<OTBag *> *successBags = [NSMutableArray arrayWithCapacity:bags.count];
    
    for (OTBag *bag in bags) {
        OSStatus const syncStatus = [bag deleteFromKeychain];
        if (syncStatus == errSecSuccess) {
            NSUInteger index = [updateBags indexOfObjectIdenticalTo:bag];
            if (index != NSNotFound) {
                [updateBags removeObjectAtIndex:index];
                [successBags addObject:bag];
            }
        } else {
            [self.observer bagCenter:self bag:bag encounteredError:OTSecErrorToError(syncStatus)];
        }
    }
    _bagCache = [updateBags copy];
    [self.observer bagCenter:self removedBags:successBags];
}

- (void)updateMetadata:(OTBag *)bag {
    OSStatus const syncStatus = [bag syncToKeychain];
    if (syncStatus != errSecSuccess) {
        [self.observer bagCenter:self bag:bag encounteredError:OTSecErrorToError(syncStatus)];
    }
}

@end
