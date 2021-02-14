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

/// Sync current bag properties to Keychain
/// @discussion This method does not mutate the receiver object,
///   other than potentially updating the keychainAttributes property
- (OSStatus)syncToKeychain;
/// Deletes the key and other attributes from Keychain
/// @note Not recoverable
- (OSStatus)deleteFromKeychain;

@end
