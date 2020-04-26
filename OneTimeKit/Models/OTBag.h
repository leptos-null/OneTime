//
//  OTBag.h
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

#import "OTPBase.h"
#import "OTSecError.h"

#define OTBagIndexPropertyKey @"null.leptos.onetime.bag.index"
#define OTPropertiesVersionPropertyKey @"null.leptos.onetime.bag.version" // value is OTPropertiesVersion

@interface OTBag : NSObject

@property (strong, nonatomic, readonly) __kindof OTPBase *generator;

@property (strong, nonatomic, readonly) NSString *uniqueIdentifier;

@property (strong, nonatomic, readonly) NSDictionary *keychainAttributes; // nil if not added to keychain

- (instancetype)initWithGenerator:(OTPBase *)generator;

- (instancetype)initWithKeychainAttributes:(NSDictionary *)attributes;

// https://github.com/google/google-authenticator/wiki/Key-Uri-Format
- (instancetype)initWithURL:(NSURL *)url;
- (NSURL *)URL;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// modifying any of these values should be accompanied by a subsequent `syncToKeychain` call
@property (strong, nonatomic) NSString *issuer;
@property (strong, nonatomic) NSString *account;
@property (strong, nonatomic) NSString *comment;
@property (nonatomic) NSInteger index;
NSInteger OTBagCompareUsingIndex(OTBag *a, OTBag *b, void *context);

@end
