//
//  _OTDemoBag.h
//  OneTimeKit
//
//  Created by Leptos on 1/26/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#ifndef OTShouldUseDemoBags
#   define OTShouldUseDemoBags 0
#endif

#import "OTBag.h"

/// Bags used for demonstration purposes.
/// These bags will not, and are not able to sync to Keychain
@interface _OTDemoBag : OTBag

+ (NSArray<OTBag *> *)demoBags;

@end
