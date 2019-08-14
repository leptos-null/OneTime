//
//  OTQRScanViewController.h
//  onetime
//
//  Created by Leptos on 8/13/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "../../OneTimeKit/Models/OTBag.h"

@class OTQRScanViewController;

@protocol OTQRScanControllerDelegate <NSObject>

- (void)qrScanController:(OTQRScanViewController *)controller didFindPayloads:(NSArray<NSString *> *)payloads;
- (void)qrScanController:(OTQRScanViewController *)controller didFailWithError:(NSError *)error;

@end

// This class was based on Google's "AuthScanBarcodeViewController"
@interface OTQRScanViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) id<OTQRScanControllerDelegate> delegate;

@end
