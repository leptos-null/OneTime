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

@interface OTBag : NSObject

@property (strong, nonatomic) NSString *issuer;
@property (strong, nonatomic) NSString *account;

@property (strong, nonatomic, readonly) OTPBase *generator;

@property (strong, nonatomic, readonly) NSString *uniqueIdentifier;

@property (strong, nonatomic, readonly) NSDictionary *keychainAttributes; // nil if not added to keychain

- (instancetype)initWithGenerator:(OTPBase *)generator;
- (instancetype)initWithKeychainAttributes:(NSDictionary *)attributes;

- (OSStatus)addToKeychain;

@end
