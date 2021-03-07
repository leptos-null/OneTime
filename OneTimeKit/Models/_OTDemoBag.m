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

+ (NSArray<OTBag *> *)demoBags {
    static NSArray<OTBag *> *bags;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _OTDemoBag *google = [[self alloc] initWithGenerator:[OTPTime new]];
        google.issuer = @"Google";
        google.account = @"leptos.0.null@gmail.com";
        
        _OTDemoBag *twitter = [[self alloc] initWithGenerator:[OTPTime new]];
        twitter.issuer = @"Twitter";
        twitter.account = @"@leptos_null";
        
        _OTDemoBag *github = [[self alloc] initWithGenerator:[OTPTime new]];
        github.issuer = @"GitHub";
        github.account = @"leptos-null";
        
        _OTDemoBag *internal = [[self alloc] initWithGenerator:[OTPHash new]];
        internal.issuer = @"Leptos Internal";
        internal.account = @"admin";
        
        _OTDemoBag *amazon = [[self alloc] initWithGenerator:[OTPTime new]];
        amazon.issuer = @"Amazon";
        amazon.account = @"leptos.demo";
        
        bags = @[
            google,
            twitter,
            github,
            internal,
            amazon
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
