//
//  OTBag+OTKeychain.h
//  onetime
//
//  Created by Leptos on 4/25/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "OTBag.h"

// Private
@interface OTBag (OTKeychain)

// syncs current bag properties to the keychain
// this method doesn't mutate the current object,
// other than potentially updating the keychainAttributes property
- (OSStatus)syncToKeychain;
// deletes the key and other attributes from keychain, not recoverable
- (OSStatus)deleteFromKeychain;

@end
