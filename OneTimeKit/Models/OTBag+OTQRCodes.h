//
//  OTBag+OTQRCodes.h
//  OneTimeKit
//
//  Created by Leptos on 3/21/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import <CoreImage/CoreImage.h>

#import "OTBag.h"

@interface OTBag (OTQRCodes)

- (CIImage *)qrCodeImage;

/// Optimized @c type representation of @c qrCodeImage
/// @param type The uniform type identifier (UTI) of the resulting image file.
/// Call @c CGImageDestinationCopyTypeIdentifiers() for supported values.
/// @discussion Generate output in the gray-scale color space, for types that support it.
/// The result from most types are able to be rendered at any scale without distortion.
- (NSData *)qrCodeData:(NSString *)type;

/// SVG representation of @c qrCodeImage
- (NSString *)qrCodeSVG;

@end
