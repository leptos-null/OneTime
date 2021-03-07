//
//  UIViewController+UMSurfacer.m
//  OneTime
//
//  Created by Leptos on 9/23/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "UIViewController+UMSurfacer.h"
#import "OTInfoViewController.h"

@implementation UIViewController (OTViewControllerUserMessageSurfacer)

- (void)surfaceUserMessage:(NSString *)message viewHint:(UIView *)viewHint dismissAfter:(NSTimeInterval)duration {
    UIView *sourceView = self.view;
    
    OTInfoViewController *info = [OTInfoViewController new];
    [info loadViewIfNeeded];
    info.textView.text = message;
    [info updatePreferredContentSizeForViewController:self];
    
    CGRect sourceRect = viewHint ? ({
        [sourceView convertRect:viewHint.frame fromView:viewHint.superview];
    }) : ({
        CGSize sourceSize = sourceView.bounds.size;
        CGRect hitRect;
        hitRect.size.width = 22;
        hitRect.size.height = 22;
        hitRect.origin.x = sourceSize.width * 0.5 - hitRect.size.width/2;
        hitRect.origin.y = sourceSize.height * 0.1 - hitRect.size.height/2;
        hitRect;
    });
    info.popoverPresentationController.sourceView = sourceView;
    info.popoverPresentationController.sourceRect = sourceRect;
    info.popoverPresentationController.permittedArrowDirections = viewHint ? UIPopoverArrowDirectionAny : 0;
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, message);
    [self presentViewController:info animated:YES completion:NULL];
    
    if (duration) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [info dismissViewControllerAnimated:YES completion:NULL];
        });
    }
}

@end
