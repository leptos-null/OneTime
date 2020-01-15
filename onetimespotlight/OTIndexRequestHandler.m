//
//  OTIndexRequestHandler.m
//  onetime
//
//  Created by Leptos on 1/14/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "OTIndexRequestHandler.h"
#import "../OneTimeKit/Models/OTBag+CSItem.h"
#import "../OneTimeKit/Models/NSArray+OTMap.h"

@implementation OTIndexRequestHandler

- (void)searchableIndex:(CSSearchableIndex *)searchableIndex
reindexAllSearchableItemsWithAcknowledgementHandler:(void (^)(void))acknowledgementHandler {
    NSArray<CSSearchableItem *> *items = [OTBag.keychainBags map:^CSSearchableItem *(OTBag *bag) {
        return bag.searchableItem;
    }];
    [searchableIndex deleteAllSearchableItemsWithCompletionHandler:^(NSError *delErr) {
        if (delErr) {
            NSLog(@"deleteAllSearchableItemsCompletedWithError: %@", delErr);
        } else {
            [searchableIndex indexSearchableItems:items completionHandler:^(NSError *addErr) {
                if (addErr) {
                    NSLog(@"indexSearchableItemsCompletedWithError: %@", addErr);
                } else {
                    acknowledgementHandler();
                }
            }];
        }
    }];
}   

- (void)searchableIndex:(CSSearchableIndex *)searchableIndex
reindexSearchableItemsWithIdentifiers:(NSArray <NSString *> *)identifiers
 acknowledgementHandler:(void (^)(void))acknowledgementHandler {
    NSArray<CSSearchableItem *> *items = [OTBag.keychainBags compactMap:^CSSearchableItem *(OTBag *bag) {
        if ([identifiers containsObject:bag.uniqueIdentifier]) {
            return bag.searchableItem;
        }
        return nil;
    }];
    [searchableIndex deleteSearchableItemsWithIdentifiers:identifiers completionHandler:^(NSError *delErr) {
        if (delErr) {
            NSLog(@"deleteSearchableItemsWithIdentifiersCompletedWithError: %@", delErr);
        } else {
            [searchableIndex indexSearchableItems:items completionHandler:^(NSError *addErr) {
                if (addErr) {
                    NSLog(@"indexSearchableItemsCompletedWithError: %@", addErr);
                } else {
                    acknowledgementHandler();
                }
            }];
        }
    }];
}

@end
