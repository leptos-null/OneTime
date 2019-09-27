//
//  UIViewController+UMSurfacer.h
//  onetime
//
//  Created by Leptos on 9/23/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OTUserMessageSurfacer <NSObject>

- (void)surfaceUserMessage:(NSString *)message viewHint:(UIView *)viewHint dismissAfter:(CGFloat)duration;

@end

@interface UIViewController (OTViewControllerUserMessageSurfacer) <OTUserMessageSurfacer>

@end
