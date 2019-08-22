//
//  OTInterfaceController.m
//  nano Extension
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTInterfaceController.h"
#import "OTPassRowController.h"

@implementation OTInterfaceController

- (void)didAppear {
    [super didAppear];
    
    if (@available(watchOS 5.1, *)) {
        // for cells of this size (being larger), I think this looks better
        self.passcodesTable.curvesAtTop = YES;
        self.passcodesTable.curvesAtBottom = YES;
    }
}

- (void)updatePasscodesTable {
#if TARGET_OS_SIMULATOR || 1 /* currently watchOS: "No iCloud Keychain" */
    uint32_t const bagCount = arc4random_uniform(8) + 2;
    NSMutableArray<OTBag *> *bags = [NSMutableArray arrayWithCapacity:bagCount];
    for (uint32_t i = 0; i < bagCount; i++) {
        OTPBase *generator = arc4random_uniform(2) ? [OTPTime new] : [OTPHash new];
        OTBag *bag = [[OTBag alloc] initWithGenerator:generator];
        /* Strings used for visual purposes only
         *   Issuer
         *   Is___r
         *
         *   account
         *   ac___nt
         */
        bag.issuer  = [NSString stringWithFormat:@"Is%03dr",  arc4random_uniform(1000)];
        bag.account = [NSString stringWithFormat:@"ac%03dnt", arc4random_uniform(1000)];
        bags[i] = bag;
    }
#else
    NSArray<OTBag *> *bags = [OTBag.keychainBags sortedArrayUsingFunction:OTBagCompareUsingIndex context:NULL];
#endif
    [self.passcodesTable setNumberOfRows:bags.count withRowType:OTPassRowController.reusableIdentifier];
    [bags enumerateObjectsUsingBlock:^(OTBag *bag, NSUInteger idx, BOOL *stop) {
        OTPassRowController *row = [self.passcodesTable rowControllerAtIndex:idx];
        row.bag = bag;
    }];
}

- (void)willActivate {
    [super willActivate];
    [self updatePasscodesTable];
}

- (void)didDeactivate {
    [super didDeactivate];
    
    NSInteger const count = self.passcodesTable.numberOfRows;
    for (NSInteger idx = 0; idx < count; idx++) {
        OTPassRowController *row = [self.passcodesTable rowControllerAtIndex:idx];
        [row stopTimingElements];
    }
}

@end
