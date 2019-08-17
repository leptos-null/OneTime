//
//  OTCaptureVideoView.h
//  onetime
//
//  Created by Leptos on 8/17/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface OTCaptureVideoView : UIView

@property (strong, nonatomic, readonly) AVCaptureVideoPreviewLayer *layer;

@end
