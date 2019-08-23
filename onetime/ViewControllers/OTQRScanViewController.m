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
}

@dynamic view;

- (instancetype)init {
    if (self = [super init]) {
        _queue = dispatch_queue_create("null.leptos.onetime.qrscan", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)loadView {
    self.view = [OTCaptureVideoView new];
    
    AVCaptureVideoPreviewLayer *previewLayer = self.view.layer;
    previewLayer.session = _avSession;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self updatePreviewLayerForCurrentOrientation];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!_avSession) {
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
        
        self.view.layer.session = captureSession;
        
        _avSession = captureSession;
    }
    [_avSession startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_avSession stopRunning];
}

- (void)updatePreviewLayerForCurrentOrientation {
    // this seems odd to me, but it's what's reccomended (not sure how else to do it)
    UIDeviceOrientation deviceOrientation = UIDevice.currentDevice.orientation;
    if (UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation)) {
        // just need the first three bits, and this makes for a clean cast
        self.view.layer.connection.videoOrientation = deviceOrientation & 0b111;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self updatePreviewLayerForCurrentOrientation];
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
