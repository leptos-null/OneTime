//
//  OTBag+OTQRCodes.h
//  OneTimeKit
//
//  Created by Leptos on 3/21/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreImage/CoreImage.h>

#import "OTBag.h"

typedef NS_ENUM(NSUInteger, OTImageFileFormat) {
    OTImageFileFormatTIFF API_AVAILABLE(ios(10.0), macos(10.12)),
    OTImageFileFormatHEIF API_AVAILABLE(ios(11.0), macos(10.13)),
    OTImageFileFormatPNG  API_AVAILABLE(ios(11.0), macos(10.13)),
};

@interface OTBag (OTQRCodes)

- (CIImage *)qrCodeImage;

/// Representations that are near-infinitely scalable
/// @discussion Uses CoreImage routines to generate output in the gray-scale color space.
/// The output is expected to be small. Image renderers should be able to scale the output
/// near-infinitely without distortion.
- (NSData *)qrCodeData:(OTImageFileFormat)fileFormat;

- (UIBezierPath *)qrCodePath:(CGFloat)scale;

@end
