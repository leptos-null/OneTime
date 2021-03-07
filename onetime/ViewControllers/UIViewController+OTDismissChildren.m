//
//  UIViewController+OTDismissChildren.m
//  OneTime
//
//  Created by Leptos on 1/16/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "UIViewController+OTDismissChildren.h"

@implementation UIViewController (OTDismissChildren)

- (void)dismissAllChilderenAnimated:(BOOL)animated completion:(void(^)(void))completion {
    [self.navigationController popToViewController:self animated:animated];
    UIViewController *presentedController = self.presentedViewController;
    if (presentedController) {
        [presentedController dismissViewControllerAnimated:animated completion:completion];
    } else {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
    }
}

@end
