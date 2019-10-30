//
//  OTLaunchOptions.h
//  onetime
//
//  Created by Leptos on 10/29/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTLaunchOptions : NSObject

@property (class, strong, nonatomic, readonly) OTLaunchOptions *defaultOptions;

@property (nonatomic) BOOL shouldPushLiveQR;

@end
