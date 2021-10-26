//
//  OTCaptureVideoView.h
//  OneTime
//
//  Created by Leptos on 8/17/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

API_AVAILABLE(ios(4.0), macCatalyst(14.0))
@interface OTCaptureVideoView : UIView

@property (strong, nonatomic, readonly) AVCaptureVideoPreviewLayer *layer;

@end
