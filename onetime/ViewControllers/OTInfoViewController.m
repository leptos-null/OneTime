//
//  OTInfoViewController.m
//  onetime
//
//  Created by Leptos on 8/20/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTInfoViewController.h"

@implementation OTInfoViewController

+ (instancetype)new {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Manual" bundle:[NSBundle bundleForClass:self]];
    OTInfoViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"Info"];
    controller.modalPresentationStyle = UIModalPresentationPopover;
    controller.popoverPresentationController.delegate = controller;
    return controller;
}

- (void)updatePreferredContentSizeForViewController:(UIViewController *)viewController {
    CGSize size = viewController.view.frame.size;
    // approximation of the inset popovers have from the edge of their presenter
    size.width -= 38;
    size.height -= 38;
    [self updatePreferredContentSizeForMaxSize:size];
}

- (void)updatePreferredContentSizeForMaxSize:(CGSize)maxSize {
    // a representation of storyboard constraints
    UIEdgeInsets storyboardConstraints = UIEdgeInsetsMake(8, 8, 8, 8);
    CGFloat horizontalOffset = TARGET_OS_MACCATALYST ? 4 : 0; // TARGET_OS_UIKITFORMAC
    
    maxSize.width -= (storyboardConstraints.left + storyboardConstraints.right + horizontalOffset);
    maxSize.height -= (storyboardConstraints.top + storyboardConstraints.bottom);
    
    CGSize size = [self.textView sizeThatFits:maxSize];
    size.width += (storyboardConstraints.left + storyboardConstraints.right + horizontalOffset);
    size.height += (storyboardConstraints.top + storyboardConstraints.bottom);
    
    self.preferredContentSize = size;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updatePreferredContentSizeForViewController:self.presentingViewController];
}

// MARK: - UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

@end
