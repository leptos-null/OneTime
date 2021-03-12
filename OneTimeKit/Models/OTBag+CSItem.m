//
//  OTBag+CSItem.m
//  OneTimeKit
//
//  Created by Leptos on 1/14/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <CoreServices/CoreServices.h>

#import "OTBag+CSItem.h"

@implementation OTBag (CSItem)

- (CSSearchableItem *)searchableItem {
    CSSearchableItemAttributeSet *attribs;
    if (@available(iOS 14.0, *)) {
        attribs = [[CSSearchableItemAttributeSet alloc] initWithContentType:UTTypeItem];
    } else {
        attribs = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeItem];
    }
    
    /* CSGeneral */
    attribs.relatedUniqueIdentifier = self.uniqueIdentifier;
    attribs.metadataModificationDate = self.modificationDate;
    if (@available(iOS 11.0, *)) {
        attribs.userCurated = @(YES);
    }
    attribs.keywords = @[
        @"code",
        @"token",
        @"password",
        @"OTP"
    ];
    
    /* CSMedia */
    attribs.comment = self.comment;
    attribs.addedDate = self.creationDate;
    attribs.organizations = @[ self.issuer ];
    
    /* CSDocuments */
    attribs.creator = @"One Time"; // this app
    attribs.kind = @"One-Time Password Item";
    
    /* CSMessaging */
    attribs.accountIdentifier = self.account;
    
    return [[CSSearchableItem alloc] initWithUniqueIdentifier:self.uniqueIdentifier
                                             domainIdentifier:NULL
                                                 attributeSet:attribs];
}

@end
