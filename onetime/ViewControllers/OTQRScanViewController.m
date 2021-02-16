//
//  OTQRScanViewController.m
//  onetime
//
//  Created by Leptos on 8/13/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTQRScanViewController.h"
#import "../../OneTimeKit/Models/NSArray+OTMap.h"

@implementation OTQRScanViewController  {
    AVCaptureSession *_avSession;
    NSArray<CALayer *> *_highlightLayers;
}

@dynamic view;

- (void)loadView {
    OTCaptureVideoView *view = [OTCaptureVideoView new];
    view.layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    self.view = view;
    
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
        [captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        captureOutput.metadataObjectTypes = @[ AVMetadataObjectTypeQRCode ];
        
        self.view.layer.session = captureSession;
        
        _avSession = captureSession;
    }
    [_avSession startRunning];
    [self updatePreviewLayerForCurrentOrientation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_avSession stopRunning];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    __weak __typeof(self) weakself = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [weakself updatePreviewLayerForCurrentOrientation];
    } completion:nil];
}

- (void)updatePreviewLayerForCurrentOrientation {
    UIInterfaceOrientation interfaceOrientation;
    if (@available(iOS 13.0, *)) {
        interfaceOrientation = self.view.window.windowScene.interfaceOrientation;
    } else {
        // this is recommended per UIViewController documentation
        interfaceOrientation = UIApplication.sharedApplication.statusBarOrientation;
    }
    AVCaptureVideoOrientation videoOrientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            videoOrientation = 0; // invalid
    }
    self.view.layer.connection.videoOrientation = videoOrientation;
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    id<OTQRScanControllerDelegate> delegate = self.delegate;
    
    AVCaptureVideoPreviewLayer *previewLayer = self.view.layer;
    NSMutableArray<CALayer *> *layers = [NSMutableArray arrayWithCapacity:metadataObjects.count];
    NSMutableArray<NSString *> *payloads = [NSMutableArray arrayWithCapacity:metadataObjects.count];
    
    for (CALayer *layer in _highlightLayers) {
        [layer removeFromSuperlayer];
    }
    
    for (AVMetadataMachineReadableCodeObject *metadataObject in metadataObjects) {
        if ([metadataObject.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString *payload = metadataObject.stringValue;
            if (payload != nil) {
                if ([delegate respondsToSelector:@selector(qrScanController:colorForPayload:)]) {
                    UIBezierPath *path = [UIBezierPath bezierPath];
                    for (NSDictionary *corner in metadataObject.corners) {
                        CGPoint point;
                        if (CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)corner, &point)) {
                            point = [previewLayer pointForCaptureDevicePointOfInterest:point];
                            if (path.isEmpty) {
                                [path moveToPoint:point];
                            } else {
                                [path addLineToPoint:point];
                            }
                        }
                    }
                    [path closePath];
                    
                    UIColor *color = [delegate qrScanController:self colorForPayload:payload];
                    CAShapeLayer *layer = [CAShapeLayer layer];
                    layer.path = [path CGPath];
                    layer.strokeColor = [[color colorWithAlphaComponent:1.0] CGColor];
                    layer.fillColor = [[color colorWithAlphaComponent:0.4] CGColor];
                    [layers addObject:layer];
                    
                    [previewLayer addSublayer:layer];
                }
                [payloads addObject:payload];
            }
        }
    }
    _highlightLayers = layers;
    
    [delegate qrScanController:self didFindPayloads:payloads];
}

@end
