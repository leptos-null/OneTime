//
//  OTKeychainHelper.h
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../Models/OTBag.h"

@interface OTKeychainHelper : NSObject

+ (NSArray<OTBag *> *)bags;

@end
