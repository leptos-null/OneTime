//
//  _OTDemoBag.m
//  OneTimeKit
//
//  Created by Leptos on 1/26/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "_OTDemoBag.h"
#import "OTBag+OTKeychain.h"
#import "OTPHash.h"
#import "OTPTime.h"

#if OTShouldUseDemoBags

@implementation _OTDemoBag

- (instancetype)initWithIssuer:(NSString *)issuer account:(NSString *)account
                       comment:(NSString *)comment digits:(size_t)digits algorithm:(CCHmacAlgorithm)algorithm
                       counter:(uint64_t)counter uniqueIdentifier:(NSString *)uniqueIdentifier {
    NSError *propListErr = NULL;
    NSData *serialProperties = [NSPropertyListSerialization dataWithPropertyList:@{
        OTPDigitPropertyKey : @(digits),
        OTPAlgorithmPropertyKey : @(algorithm),
        OTPCounterPropertyKey : @(counter),
        OTPropertiesVersionPropertyKey : @(OTPropertiesVersion1)
    } format:NSPropertyListBinaryFormat_v1_0 options:0 error:&propListErr];
    if (propListErr) {
        return nil;
    }
    
    NSDate *nowDate = [NSDate date];
    return [self initWithKeychainAttributes:@{
        (NSString *)kSecAttrLabel : account,
        (NSString *)kSecAttrService : issuer,
        (NSString *)kSecAttrComment : comment,
        (NSString *)kSecAttrGeneric : serialProperties,
        (NSString *)kSecClass : (NSString *)kSecClassGenericPassword,
        (NSString *)kSecValueData : [OTPHash randomKeyForAlgorithm:algorithm],
        (NSString *)kSecAttrSynchronizable : @(YES),
        (NSString *)kSecAttrAccount : uniqueIdentifier,
        (NSString *)kSecAttrType : [NSNumber numberWithUnsignedInt:[OTPHash type]],
        (NSString *)kSecAttrDescription : @"One-Time Password Generator",
        (NSString *)kSecAttrCreationDate : nowDate,
        (NSString *)kSecAttrModificationDate : nowDate,
        (NSString *)kSecReturnAttributes : @(YES),
        (NSString *)kSecReturnData : @(YES),
    }];
}

- (instancetype)initWithIssuer:(NSString *)issuer account:(NSString *)account
                       comment:(NSString *)comment digits:(size_t)digits algorithm:(CCHmacAlgorithm)algorithm
                          step:(NSTimeInterval)step uniqueIdentifier:(NSString *)uniqueIdentifier {
    NSError *propListErr = NULL;
    NSData *serialProperties = [NSPropertyListSerialization dataWithPropertyList:@{
        OTPDigitPropertyKey : @(digits),
        OTPAlgorithmPropertyKey : @(algorithm),
        OTPStepPropertyKey : @(step),
        OTPropertiesVersionPropertyKey : @(OTPropertiesVersion1)
    } format:NSPropertyListBinaryFormat_v1_0 options:0 error:&propListErr];
    if (propListErr) {
        return nil;
    }
    
    NSDate *nowDate = [NSDate date];
    return [self initWithKeychainAttributes:@{
        (NSString *)kSecAttrLabel : account,
        (NSString *)kSecAttrService : issuer,
        (NSString *)kSecAttrComment : comment,
        (NSString *)kSecAttrGeneric : serialProperties,
        (NSString *)kSecClass : (NSString *)kSecClassGenericPassword,
        (NSString *)kSecValueData : [OTPTime randomKeyForAlgorithm:algorithm],
        (NSString *)kSecAttrSynchronizable : @(YES),
        (NSString *)kSecAttrAccount : uniqueIdentifier,
        (NSString *)kSecAttrType : [NSNumber numberWithUnsignedInt:[OTPTime type]],
        (NSString *)kSecAttrDescription : @"One-Time Password Generator",
        (NSString *)kSecAttrCreationDate : nowDate,
        (NSString *)kSecAttrModificationDate : nowDate,
        (NSString *)kSecReturnAttributes : @(YES),
        (NSString *)kSecReturnData : @(YES),
    }];
}

+ (NSArray<OTBag *> *)demoBags {
    static NSArray<OTBag *> *bags;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _OTDemoBag *google = [[self alloc] initWithIssuer:@"Google" account:@"leptos.0.null@gmail.com"
                                                  comment:@"" digits:[OTPTime defaultDigits] algorithm:[OTPTime defaultAlgorithm]
                                                     step:[OTPTime defaultStep] uniqueIdentifier:@"demo.google"];
        
        _OTDemoBag *twitter = [[self alloc] initWithIssuer:@"Twitter" account:@"@leptos_null"
                                                   comment:@"" digits:[OTPTime defaultDigits] algorithm:[OTPTime defaultAlgorithm]
                                                      step:[OTPTime defaultStep] uniqueIdentifier:@"demo.twitter"];
        
        _OTDemoBag *github = [[self alloc] initWithIssuer:@"GitHub" account:@"leptos-null"
                                                  comment:@"" digits:[OTPTime defaultDigits] algorithm:[OTPTime defaultAlgorithm]
                                                     step:[OTPTime defaultStep] uniqueIdentifier:@"demo.github"];
        
        _OTDemoBag *internal = [[self alloc] initWithIssuer:@"Leptos Internal" account:@"admin"
                                                    comment:@"" digits:[OTPHash defaultDigits] algorithm:[OTPHash defaultAlgorithm]
                                                    counter:[OTPHash defaultCounter] uniqueIdentifier:@"demo.hash"];
        
        _OTDemoBag *amazon = [[self alloc] initWithIssuer:@"Amazon" account:@"leptos.demo"
                                                  comment:@"" digits:[OTPTime defaultDigits] algorithm:[OTPTime defaultAlgorithm]
                                                     step:[OTPTime defaultStep] uniqueIdentifier:@"demo.amazon"];
        
        _OTDemoBag *tenDigits = [[self alloc] initWithIssuer:@"Leptos Internal" account:@"test.digits.ten"
                                                     comment:@"" digits:10 algorithm:[OTPTime defaultAlgorithm]
                                                        step:[OTPTime defaultStep] uniqueIdentifier:@"demo.digits.ten"];
        
        _OTDemoBag *tenSeconds = [[self alloc] initWithIssuer:@"Leptos Internal" account:@"test.time.ten"
                                                      comment:@"" digits:[OTPTime defaultDigits] algorithm:[OTPTime defaultAlgorithm]
                                                         step:10 uniqueIdentifier:@"demo.time.ten"];
        
        bags = @[
            google,
            twitter,
            github,
            internal,
            amazon,
            tenDigits,
            tenSeconds,
        ];
    });
    return bags;
}

- (OSStatus)syncToKeychain {
    return errSecSuccess;
}

- (OSStatus)deleteFromKeychain {
    return errSecSuccess;
}

@end

#endif /* OTShouldUseDemoBags */
