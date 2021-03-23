//
//  OTQRService.m
//  OneTimeKit
//
//  Created by Leptos on 3/22/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import "OTQRService.h"

#import "../Models/NSArray+OTMap.h"

@implementation OTQRService {
    /// Detector used for detecting QR codes in images
    CIDetector *_detector;
    /// Context used for rendering QR codes into gray-scale formats
    CIContext *_context;
}

+ (instancetype)shared {
    static OTQRService *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        NSMutableDictionary<CIContextOption, id> *detectorOptions = [NSMutableDictionary dictionary];
        NSMutableDictionary<CIContextOption, id> *grayOptions = [NSMutableDictionary dictionary];
        
        if (@available(iOS 12.0, *)) {
            detectorOptions[kCIContextName] = @"null.leptos.onetime.detector.qr";
            grayOptions[kCIContextName] = @"null.leptos.onetime.render.grayscale";
        }
        
        CIContext *detectorContext = [CIContext contextWithOptions:detectorOptions];
        _detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:detectorContext options:@{
            // this is so fast, and not going to happen that often - opt into higher accuracy
            CIDetectorAccuracy : CIDetectorAccuracyHigh
        }];
        
        id const colorSpace = CFBridgingRelease(CGColorSpaceCreateDeviceGray());
        grayOptions[kCIContextOutputColorSpace] = colorSpace;
        grayOptions[kCIContextWorkingColorSpace] = colorSpace;
        grayOptions[kCIContextWorkingFormat] = @(kCIFormatL8);
        
        _context = [CIContext contextWithOptions:grayOptions];
        
    }
    return self;
}

- (CIImage *)codeImageForData:(NSData *)data {
    // thanks to https://www.appcoda.com/qr-code-generator-tutorial/
    CIFilter *barcodeCreationFilter = [CIFilter filterWithName:@"CIQRCodeGenerator" withInputParameters:@{
        @"inputMessage" : data,
        // may be one of "L", "M", "Q", "H"
        @"inputCorrectionLevel" : @"M"
    }];
    return barcodeCreationFilter.outputImage;
}

- (NSData *)codeRepresentationForData:(NSData *)data type:(NSString *)type {
    CIImage *image = [self codeImageForData:data];
    
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
    CGImageRef graphic = [_context createCGImage:image fromRect:image.extent format:format colorSpace:colorSpace deferred:YES];
    if (graphic) {
        NSMutableData *resultData = [NSMutableData data];
        CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)resultData, (__bridge CFStringRef)type, 1, NULL);
        if (dest) {
            CGImageDestinationAddImage(dest, graphic, (__bridge CFDictionaryRef)properties);
            if (CGImageDestinationFinalize(dest)) {
                imageData = resultData;
            }
            CFRelease(dest);
        }
        CGImageRelease(graphic);
    }
    CGColorSpaceRelease(colorSpace);
    
    return imageData;
}

- (NSArray<CIQRCodeFeature *> *)codesInImage:(CIImage *)image {
    NSArray<__kindof CIFeature *> *features = [_detector featuresInImage:image];
    return [features compactMap:^CIQRCodeFeature *(__kindof CIFeature *feature) {
        if ([feature isKindOfClass:[CIQRCodeFeature class]]) {
            return feature;
        }
        NSAssert(0, @"Expected feature to be kindof CIQRCodeFeature");
        return nil;
    }];
}

@end
