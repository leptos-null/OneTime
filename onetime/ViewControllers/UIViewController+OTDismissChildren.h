//
//  UIViewController+OTDismissChildren.h
//  onetime
//
//  Created by Leptos on 1/16/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (OTDismissChildren)

/// Dismiss all childeren view controllers on the navigation controller, and any presented view controllers
- (void)dismissAllChilderenAnimated:(BOOL)animated completion:(void(^)(void))completion;

@end
