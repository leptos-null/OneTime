//
//  OTBag.h
//  OneTimeKit
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

/// Creates a new bag with @c generator
- (instancetype)initWithGenerator:(OTPBase *)generator;
/// Creates a bag from Keychain attributes
- (instancetype)initWithKeychainAttributes:(NSDictionary *)attributes;

// https://github.com/google/google-authenticator/wiki/Key-Uri-Format
- (instancetype)initWithURL:(NSURL *)url;
- (NSURL *)URL;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// modifying any of these values should be accompanied by a subsequent `syncToKeychain` call

/// Human-readable string indicating the provider or service the receiver is associated with
/// @discussion For example, "GitHub"
@property (strong, nonatomic) NSString *issuer;
/// Human-readable string indicating the account the receiver is associated with
/// @discussion For example, "leptos_null"
@property (strong, nonatomic) NSString *account;
/// A user-provided comment
@property (strong, nonatomic) NSString *comment;
/// The index for which the receiver should appear in UI elements
@property (nonatomic) NSInteger index;
NSInteger OTBagCompareUsingIndex(OTBag *a, OTBag *b, void *context);

@end
