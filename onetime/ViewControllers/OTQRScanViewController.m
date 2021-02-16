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
        dispatch_queue_t queue = dispatch_queue_create("null.leptos.onetime.qrscan", DISPATCH_QUEUE_SERIAL);
        AVCaptureMetadataOutput *captureOutput = [AVCaptureMetadataOutput new];
        AVCaptureSession *captureSession = [AVCaptureSession new];
        
        [captureSession addInput:captureInput];
        [captureSession addOutput:captureOutput];
        [captureOutput setMetadataObjectsDelegate:self queue:queue];
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
    NSArray<NSString *> *payloads = [metadataObjects compactMap:^NSString *(AVMetadataMachineReadableCodeObject *metadataObject) {
        if ([metadataObject.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            return metadataObject.stringValue;
        }
        return nil;
    }];
    __weak __typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself.delegate qrScanController:weakself didFindPayloads:payloads];
    });
}

@end
