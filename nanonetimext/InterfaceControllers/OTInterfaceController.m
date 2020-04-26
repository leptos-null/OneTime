//
//  OTInterfaceController.m
//  nano Extension
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTInterfaceController.h"
#import "OTPassRowController.h"

#import "../../OneTimeKit/Services/OTBagCenter.h"
#import "../../OneTimeKit/Models/_OTDemoBag.h"

@implementation OTInterfaceController

- (void)didAppear {
    [super didAppear];
    
    if (@available(watchOS 5.1, *)) {
        // for cells of this size (being larger), I think this looks better
        self.passcodesTable.curvesAtTop = YES;
        self.passcodesTable.curvesAtBottom = YES;
    }
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

- (void)updatePasscodesTable {
    NSArray<OTBag *> *bags;
#if OTShouldUseDemoBags
    bags = _OTDemoBag.demoBags;
#else
    bags = [OTBagCenter.defaultCenter keychainBagsCache:NO];
#endif
    [self.passcodesTable setNumberOfRows:bags.count withRowType:OTPassRowController.reusableIdentifier];
    [bags enumerateObjectsUsingBlock:^(OTBag *bag, NSUInteger idx, BOOL *stop) {
        OTPassRowController *row = [self.passcodesTable rowControllerAtIndex:idx];
        row.bag = bag;
    }];
}

@end
