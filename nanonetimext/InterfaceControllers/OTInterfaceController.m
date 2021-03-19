//
//  OTInterfaceController.m
//  nano OneTime Extension
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTInterfaceController.h"
#import "OTPassRowController.h"

#import "../../OneTimeKit/Services/OTBagCenter.h"

@implementation OTInterfaceController {
    BOOL _didInitialScroll;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
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

- (void)didAppear {
    [super didAppear];
    
    if (!_didInitialScroll) {
        [self _scrollToTopOfPasscodeTable:NO];
        _didInitialScroll = YES;
    }
}

- (void)didDeactivate {
    [super didDeactivate];
    
    NSInteger const count = self.passcodesTable.numberOfRows;
    for (NSInteger idx = 0; idx < count; idx++) {
        OTPassRowController *row = [self.passcodesTable rowControllerAtIndex:idx];
        [row stopTimingElements];
    }
}

- (void)_scrollToTopOfPasscodeTable:(BOOL)animated {
    WKInterfaceTable *passcodeTable = self.passcodesTable;
    if (@available(watchOS 4.0, *)) {
        [self scrollToObject:passcodeTable atScrollPosition:WKInterfaceScrollPositionTop animated:animated];
    } else {
        // leaves a little bit of the button visible
        [passcodeTable scrollToRowAtIndex:0];
    }
}

- (NSString *)_relativeStringFromDate:(NSDate *)date {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.locale = NSLocale.autoupdatingCurrentLocale;
        dateFormatter.timeZone = NSTimeZone.localTimeZone;
        dateFormatter.calendar = NSCalendar.autoupdatingCurrentCalendar;
        
        dateFormatter.doesRelativeDateFormatting = YES;
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    return [dateFormatter stringFromDate:date];
}

- (IBAction)updateButtonHit:(WKInterfaceButton *)button {
    [self updatePasscodesTable];
    
    [self _scrollToTopOfPasscodeTable:YES];
}

- (void)updatePasscodesTable {
    WKInterfaceTable *table = self.passcodesTable;
    NSArray<OTBag *> *bags = [OTBagCenter.defaultCenter keychainBagsCache:NO];
    
    NSInteger const tableRows = table.numberOfRows;
    NSInteger const bagCount = bags.count;
    if (tableRows > bagCount) {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(bagCount, tableRows - bagCount)];
        [table removeRowsAtIndexes:indexes];
    } else if (bagCount > tableRows) {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tableRows, bagCount - tableRows)];
        [table insertRowsAtIndexes:indexes withRowType:OTPassRowController.reusableIdentifier];
    }
    self.emptyListInterface.hidden = (bagCount != 0);
    [bags enumerateObjectsUsingBlock:^(OTBag *bag, NSUInteger idx, BOOL *stop) {
        OTPassRowController *row = [table rowControllerAtIndex:idx];
        row.bag = bag;
        if (bag.index != idx) {
            bag.index = idx;
            [OTBagCenter.defaultCenter updateMetadata:bag];
        }
    }];
    
    NSDate *now = [NSDate date];
    self.updateLabel.text = [@"Last updated:\n" stringByAppendingString:[self _relativeStringFromDate:now]];
}

@end
