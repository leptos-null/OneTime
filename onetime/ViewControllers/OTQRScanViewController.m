//
//  OTQRScanViewController.m
//  onetime
//
//  Created by Leptos on 8/13/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTQRScanViewController.h"

@implementation OTQRScanViewController  {
    dispatch_queue_t _queue;
    
    AVCaptureSession *_avSession;
    AVCaptureVideoPreviewLayer *_previewLayer;
}

- (instancetype)init {
    if (self = [super init]) {
        _queue = dispatch_queue_create("null.leptos.onetime.qrscan", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSError *error = NULL;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (error) {
        [self.delegate qrScanController:self didFailWithError:error];
        return;
    }
    AVCaptureMetadataOutput *captureOutput = [AVCaptureMetadataOutput new];
    AVCaptureSession *captureSession = [AVCaptureSession new];
    
    [captureSession addInput:captureInput];
    [captureSession addOutput:captureOutput];
    [captureOutput setMetadataObjectsDelegate:self queue:_queue];
    captureOutput.metadataObjectTypes = @[ AVMetadataObjectTypeQRCode ];
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer];
    previewLayer.frame = self.view.bounds;
    
    [captureSession startRunning];
    
    _previewLayer = previewLayer;
    _avSession = captureSession;
    
    [self updatePreviewLayerForCurrentOrientation];
}

- (void)updatePreviewLayerForCurrentOrientation {
    // this seems odd to me, but it's what's reccomended (not sure how else to do it)
    UIDeviceOrientation deviceOrientation = UIDevice.currentDevice.orientation;
    if (UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation)) {
        AVCaptureVideoOrientation avOrient = AVCaptureVideoOrientationPortrait;
#if 0
        switch (deviceOrientation) {
            case UIDeviceOrientationPortrait: // 1 ("home button on the bottom")
                avOrient = AVCaptureVideoOrientationPortrait; // 1 ("home button on the bottom")
                break;
            case UIDeviceOrientationPortraitUpsideDown: // 2 ("home button on the top")
                avOrient = AVCaptureVideoOrientationPortraitUpsideDown; // 2 ("home button on the top")
                break;
            case UIDeviceOrientationLandscapeLeft: // 3 ("home button on the right")
                avOrient = AVCaptureVideoOrientationLandscapeRight; // 3 ("home button on the right")
                break;
            case UIDeviceOrientationLandscapeRight: // 4 ("home button on the left")
                avOrient = AVCaptureVideoOrientationLandscapeLeft; // 4 ("home button on the left")
                break;
            default:
                break;
        }
#else
        avOrient = deviceOrientation & 0x7; // just need the first three bits, and this makes for a clean cast
#endif
        _previewLayer.connection.videoOrientation = avOrient;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    CGRect frame = CGRectZero;
    frame.size = size;
    _previewLayer.frame = frame;
    
    [self updatePreviewLayerForCurrentOrientation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_avSession stopRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSMutableArray<NSString *> *payloads = [NSMutableArray arrayWithCapacity:metadataObjects.count];
    for (AVMetadataMachineReadableCodeObject *metadataObject in metadataObjects) {
        if ([metadataObject.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            [payloads addObject:metadataObject.stringValue];
        }
    }
    __weak __typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself.delegate qrScanController:weakself didFindPayloads:[payloads copy]];
    });
}

@end
