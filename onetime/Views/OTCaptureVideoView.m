//
//  OTCaptureVideoView.m
//  onetime
//
//  Created by Leptos on 8/17/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTCaptureVideoView.h"

@implementation OTCaptureVideoView
@dynamic layer;

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

@end
