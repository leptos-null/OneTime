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

- (NSData *)qrCodeData:(OTImageFileFormat)fileFormat {
    CIImage *image = [self qrCodeImage];
    CIContext *context = [self _grayscale8BitContext];
    
    CGColorSpaceRef const colorSpace = CGColorSpaceCreateDeviceGray();
    CIFormat const format = kCIFormatL8;
    
    NSData *imageData = nil;
    switch (fileFormat) {
        case OTImageFileFormatTIFF:
            imageData = [context TIFFRepresentationOfImage:image format:format colorSpace:colorSpace options:@{
                // no options
            }];
            break;
        case OTImageFileFormatHEIF:
            imageData = [context HEIFRepresentationOfImage:image format:format colorSpace:colorSpace options:@{
                (NSString *)kCGImageDestinationLossyCompressionQuality : @(0)
            }];
            break;
        case OTImageFileFormatPNG:
            imageData = [context PNGRepresentationOfImage:image format:format colorSpace:colorSpace options:@{
                // no options
            }];
            break;
    }
    CGColorSpaceRelease(colorSpace);
    
    return imageData;
}

- (UIBezierPath *)qrCodePath:(CGFloat)scale {
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
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (ptrdiff_t row = 0; row < rowCount; row++) {
        for (ptrdiff_t column = 0; column < columnCount; column++) {
            uint8_t lum = bitmap[row*rowBytes + column];
            if (lum > INT8_MAX) {
                CGRect pathRender = CGRectMake(row * scale, column * scale, scale, scale);
                [path appendPath:[UIBezierPath bezierPathWithRect:pathRender]];
            }
        }
    }
    free(bitmap);
    
    return path;
}

@end
