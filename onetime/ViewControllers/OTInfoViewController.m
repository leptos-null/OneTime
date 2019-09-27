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

- (void)updatePreferredContentSizeForMaxSize:(CGSize)maxSize {
    NSAttributedString *text = self.textView.attributedText;
    CGRect textRender = [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    CGSize size = textRender.size;
    // per storyboard constraints
    size.height += 16;
    size.width += 16;
    
    UIEdgeInsets containerInsets = self.textView.textContainerInset;
    size.width += (containerInsets.left + containerInsets.right);
    size.height += (containerInsets.top + containerInsets.bottom);
    
    UIEdgeInsets marginInsets = self.textView.layoutMargins;
    size.width += (marginInsets.left + marginInsets.right);
    size.height += (marginInsets.top + marginInsets.bottom);
    
    self.preferredContentSize = size;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updatePreferredContentSizeForMaxSize:self.presentingViewController.view.bounds.size];
}

// MARK: - UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

@end
