//
//  OTBag+CSItem.m
//  onetime
//
//  Created by Leptos on 1/14/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <CoreServices/CoreServices.h>

#import "OTBag+CSItem.h"

@implementation OTBag (CSItem)

- (CSSearchableItem *)searchableItem {
    NSString *type = (NSString *)kUTTypeItem;
    CSSearchableItemAttributeSet *attribs = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:type];
    
    attribs.relatedUniqueIdentifier = self.uniqueIdentifier;
    
    attribs.subject = self.issuer;
    attribs.contentDescription = self.account;
    attribs.creator = @"One Time"; // this app
    attribs.kind = @"One-Time Password Item";
    
    attribs.comment = self.comment;
    attribs.accountIdentifier = self.account;
    attribs.organizations = @[ self.issuer ];
    
    if (@available(iOS 11.0, *)) {
        attribs.userCurated = @(YES);
    }
    attribs.keywords = @[
        @"code",
        @"token",
        @"password",
        @"OTP"
    ];
    return [[CSSearchableItem alloc] initWithUniqueIdentifier:self.uniqueIdentifier
                                             domainIdentifier:NULL
                                                 attributeSet:attribs];
}

@end
