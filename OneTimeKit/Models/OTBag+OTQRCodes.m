//
//  OTBag+OTQRCodes.m
//  OneTimeKit
//
//  Created by Leptos on 3/21/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import "OTBag+OTQRCodes.h"

@implementation OTBag (OTQRCodes)

- (CIContext *)_grayscale8BitContext {
    static CIContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id const colorSpace = CFBridgingRelease(CGColorSpaceCreateDeviceGray());
        
        NSMutableDictionary<CIContextOption, id> *options = [NSMutableDictionary dictionary];
        if (@available(iOS 12.0, *)) {
            options[kCIContextName] = @"null.leptos.onetime.render.grayscale";
        }
        options[kCIContextOutputColorSpace] = colorSpace;
        options[kCIContextWorkingColorSpace] = colorSpace;
        options[kCIContextWorkingFormat] = @(kCIFormatL8);
        
        context = [CIContext contextWithOptions:options];
    });
    return context;
}

- (CIImage *)qrCodeImage {
    // thanks to https://www.appcoda.com/qr-code-generator-tutorial/
    NSData *data = [[[self URL] absoluteString] dataUsingEncoding:NSISOLatin1StringEncoding];
    CIFilter *barcodeCreationFilter = [CIFilter filterWithName:@"CIQRCodeGenerator" withInputParameters:@{
        @"inputMessage" : data,
        // may be one of "L", "M", "Q", "H"
        @"inputCorrectionLevel" : @"M"
    }];
    return barcodeCreationFilter.outputImage;
}

- (NSData *)qrCodeData:(NSString *)type {
    CIImage *image = [self qrCodeImage];
    CIContext *context = [self _grayscale8BitContext];
    
    CGColorSpaceRef const colorSpace = CGColorSpaceCreateDeviceGray();
    CIFormat const format = kCIFormatL8;
    
    NSDictionary *properties = nil;
    
    if ([type isEqualToString:@"public.tiff"]) {
        properties = @{
            (NSString *)kCGImagePropertyTIFFDictionary : @{
                (NSString *)kCGImagePropertyTIFFCompression : @(5), /* LZW */
            }
        };
    } else if ([type isEqualToString:@"public.pvr"]) {
        CGSize imageSize = image.extent.size;
        // PVR requires power-of-two dimensions
        // prefer upscale, since we're confident about preserving quality
        CGFloat xScale = pow(2, ceil(log2(imageSize.width)))/imageSize.width;
        CGFloat yScale = pow(2, ceil(log2(imageSize.height)))/imageSize.height;
        
        image = [image imageByApplyingTransform:CGAffineTransformMakeScale(xScale, yScale)];
    }
    
    NSData *imageData = nil;
    CGImageRef graphic = [context createCGImage:image fromRect:image.extent format:format colorSpace:colorSpace deferred:YES];
    if (graphic) {
        NSMutableData *data = [NSMutableData data];
        CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data, (__bridge CFStringRef)type, 1, NULL);
        if (dest) {
            CGImageDestinationAddImage(dest, graphic, (__bridge CFDictionaryRef)properties);
            if (CGImageDestinationFinalize(dest)) {
                imageData = data;
            }
            CFRelease(dest);
        }
        CGImageRelease(graphic);
    }
    CGColorSpaceRelease(colorSpace);
    
    return imageData;
}

- (NSString *)qrCodeSVG {
    CIImage *image = [self qrCodeImage];
    CIContext *context = [self _grayscale8BitContext];
    
    CGColorSpaceRef const colorSpace = CGColorSpaceCreateDeviceGray();
    CIFormat const format = kCIFormatL8;
    
    CGRect const bounds = [image extent];
    ptrdiff_t const rowCount = floor(bounds.size.height);
    ptrdiff_t const columnCount = floor(bounds.size.width);
    
    ptrdiff_t const formatRowAlignment = 4;
    ptrdiff_t const rowBytes = columnCount + (formatRowAlignment - (columnCount % formatRowAlignment));
    
    uint8_t *bitmap = malloc(rowBytes * rowCount);
    [context render:image toBitmap:bitmap rowBytes:rowBytes bounds:bounds format:format colorSpace:colorSpace];
    CGColorSpaceRelease(colorSpace);
    
    NSMutableString *path = [NSMutableString string];
    [path appendFormat:@"<svg viewbox=\"0 0 %ld %ld\">\n", columnCount, rowCount];
    for (ptrdiff_t row = 0; row < rowCount; row++) {
        for (ptrdiff_t column = 0; column < columnCount; column++) {
            uint8_t lum = bitmap[row*rowBytes + column];
            if (lum <= INT8_MAX) {
                [path appendFormat:@"\t<rect x=\"%ld\" y=\"%ld\" width=\"1\" height=\"1\"/>\n", row, column];
            }
        }
    }
    [path appendString:@"</svg>"];
    
    free(bitmap);
    
    return path;
}

@end
