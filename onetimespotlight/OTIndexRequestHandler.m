//
//  OTIndexRequestHandler.m
//  OneTime Spotlight
//
//  Created by Leptos on 1/14/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "OTIndexRequestHandler.h"
#import "../OneTimeKit/Models/OTBag+CSItem.h"
#import "../OneTimeKit/Models/NSArray+OTMap.h"
#import "../OneTimeKit/Services/OTBagCenter.h"

@implementation OTIndexRequestHandler

- (void)searchableIndex:(CSSearchableIndex *)searchableIndex
reindexAllSearchableItemsWithAcknowledgementHandler:(void (^)(void))acknowledgementHandler {
    NSArray<CSSearchableItem *> *items = [[OTBagCenter.defaultCenter keychainBagsCache:NO] map:^CSSearchableItem *(OTBag *bag) {
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
reindexSearchableItemsWithIdentifiers:(NSArray<NSString *> *)identifiers
 acknowledgementHandler:(void (^)(void))acknowledgementHandler {
    NSMutableArray<NSString *> *requestIDs = [identifiers mutableCopy];
    NSArray<CSSearchableItem *> *items = [[OTBagCenter.defaultCenter keychainBagsCache:NO] compactMap:^CSSearchableItem *(OTBag *bag) {
        NSUInteger indx = [requestIDs indexOfObject:bag.uniqueIdentifier];
        if (indx == NSNotFound) {
            return nil;
        }
        [requestIDs removeObjectAtIndex:indx];
        return bag.searchableItem;
    }];
    [searchableIndex fetchLastClientStateWithCompletionHandler:^(NSData *clientState, NSError *fetchErr) {
        if (fetchErr) {
            NSLog(@"fetchLastClientStateCompletedWithError: %@", fetchErr);
            return;
        }
        [searchableIndex beginIndexBatch];
        [searchableIndex deleteSearchableItemsWithIdentifiers:identifiers completionHandler:^(NSError *delErr) {
            if (delErr) {
                NSLog(@"deleteSearchableItemsWithIdentifiersCompletedWithError: %@", delErr);
                return;
            }
            [searchableIndex indexSearchableItems:items completionHandler:^(NSError *addErr) {
                if (addErr) {
                    NSLog(@"indexSearchableItemsCompletedWithError: %@", addErr);
                    return;
                }
                [searchableIndex endIndexBatchWithClientState:clientState completionHandler:^(NSError *endErr) {
                    if (endErr) {
                        NSLog(@"endIndexBatchCompletedWithError: %@", endErr);
                        return;
                    }
                    acknowledgementHandler();
                }];
            }];
        }];
    }];
}

@end
