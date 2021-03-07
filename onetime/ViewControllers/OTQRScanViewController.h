//
//  OTQRScanViewController.h
//  OneTime
//
//  Created by Leptos on 8/13/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "../../OneTimeKit/Models/OTBag.h"
#import "../Views/OTCaptureVideoView.h"

@class OTQRScanViewController;

@protocol OTQRScanControllerDelegate <NSObject>

- (void)qrScanController:(OTQRScanViewController *)controller didFindPayloads:(NSArray<NSString *> *)payloads;
- (void)qrScanController:(OTQRScanViewController *)controller didFailWithError:(NSError *)error;

@optional
/// The color to highlight a QR code of a given @c payload with
/// @note The alpha component of the color is ignored
- (UIColor *)qrScanController:(OTQRScanViewController *)controller colorForPayload:(NSString *)payload;

@end


@interface OTQRScanViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

@property(strong, nonatomic) OTCaptureVideoView *view;

@property (weak, nonatomic) id<OTQRScanControllerDelegate> delegate;

@end
