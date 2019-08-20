//
//  OTInfoViewController.m
//  onetime
//
//  Created by Leptos on 8/20/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTInfoViewController.h"

@implementation OTInfoViewController

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
    self.preferredContentSize = textRender.size;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updatePreferredContentSizeForMaxSize:self.presentingViewController.view.bounds.size];
}

@end
