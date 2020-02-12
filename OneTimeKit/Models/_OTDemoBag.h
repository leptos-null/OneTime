//
//  _OTDemoBag.h
//  onetime
//
//  Created by Leptos on 1/26/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#ifndef OTShouldUseDemoBags
#   define OTShouldUseDemoBags 0
#endif

#import "OTBag.h"

@interface _OTDemoBag : OTBag

+ (NSArray<OTBag *> *)keychainBags NS_UNAVAILABLE;
+ (NSArray<OTBag *> *)demoBags;

@end
