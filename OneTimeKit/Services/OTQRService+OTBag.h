//
//  OTQRService+OTBag.h
//  OneTimeKit
//
//  Created by Leptos on 3/22/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import "OTQRService.h"
#import "../Models/OTBag.h"

@interface OTQRService (OTBag)

/// The data used to encode @c bag
- (NSData *)encodingDataForBag:(OTBag *)bag;

/// QR code image encoding @c bag
- (CIImage *)codeImageForBag:(OTBag *)bag;
/// Optimized @c type representation of @c codeImageForBag:
/// @param bag The bag to encode into the QR code image
/// @param type The uniform type identifier (UTI) of the resulting image data.
/// Call @c CGImageDestinationCopyTypeIdentifiers() for supported values.
/// @discussion Generate output in the gray-scale color space, for types that support it.
/// The result from most types is able to be rendered at any scale without distortion.
- (NSData *)codeRepresentationForBag:(OTBag *)bag type:(NSString *)type;

/// Detect QR-code-encoded bags in @c image
- (NSArray<OTBag *> *)bagsInImage:(CIImage *)image;

@end
