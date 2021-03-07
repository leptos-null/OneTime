//
//  OTBagCenter.h
//  OneTimeKit
//
//  Created by Leptos on 4/19/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "../Models/OTBag.h"

@class OTBagCenter;

@protocol OTBagCenterObserver <NSObject>

- (void)bagCenter:(OTBagCenter *)bagCenter addedBags:(NSArray<OTBag *> *)bags;
- (void)bagCenter:(OTBagCenter *)bagCenter removedBags:(NSArray<OTBag *> *)bags;
- (void)bagCenter:(OTBagCenter *)bagCenter bag:(OTBag *)bag encounteredError:(NSError *)error;

@end

@interface OTBagCenter : NSObject

@property (class, strong, nonatomic, readonly) OTBagCenter *defaultCenter;
@property (nonatomic) id<OTBagCenterObserver> observer;

- (NSArray<OTBag *> *)keychainBagsCache:(BOOL)hitCache;

- (void)addBags:(NSArray<OTBag *> *)bags;
- (void)removeBags:(NSArray<OTBag *> *)bags;
- (void)updateMetadata:(OTBag *)bag;

@end
