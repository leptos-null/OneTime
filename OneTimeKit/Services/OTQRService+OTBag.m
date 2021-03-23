//
//  OTQRService+OTBag.m
//  OneTimeKit
//
//  Created by Leptos on 3/22/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import "OTQRService+OTBag.h"
#import "../Models/NSArray+OTMap.h"

@implementation OTQRService (OTBag)

- (NSData *)encodingDataForBag:(OTBag *)bag {
    NSURL *url = [bag URL];
    return [url.absoluteString dataUsingEncoding:NSISOLatin1StringEncoding];
}

- (CIImage *)codeImageForBag:(OTBag *)bag {
    return [self codeImageForData:[self encodingDataForBag:bag]];
}

- (NSData *)codeRepresentationForBag:(OTBag *)bag type:(NSString *)type {
    return [self codeRepresentationForData:[self encodingDataForBag:bag] type:type];
}

- (NSArray<OTBag *> *)bagsInImage:(CIImage *)image {
    return [[self codesInImage:image] compactMap:^id(CIQRCodeFeature *feature) {
        return [[OTBag alloc] initWithURL:[NSURL URLWithString:feature.messageString]];
    }];
}

@end
