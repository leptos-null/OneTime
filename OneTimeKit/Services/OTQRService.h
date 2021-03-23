//
//  OTQRService.h
//  OneTimeKit
//
//  Created by Leptos on 3/22/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>

@interface OTQRService : NSObject

+ (instancetype)shared;

/// QR code image encoding @c data
- (CIImage *)codeImageForData:(NSData *)data;
/// Optimized @c type representation of @c codeImageForData:
/// @param data The data to encode into the QR code image
/// @param type The uniform type identifier (UTI) of the resulting image data.
/// Call @c CGImageDestinationCopyTypeIdentifiers() for supported values.
/// @discussion Generate output in the gray-scale color space, for types that support it.
/// The result from most types is able to be rendered at any scale without distortion.
- (NSData *)codeRepresentationForData:(NSData *)data type:(NSString *)type;

/// Detect QR codes in @c image
- (NSArray<CIQRCodeFeature *> *)codesInImage:(CIImage *)image;

@end
