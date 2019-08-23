//
//  OTNavigationController.m
//  onetime
//
//  Created by Leptos on 8/23/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTNavigationController.h"

@implementation OTNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(iOS 11.0, *)) {
        [self _updateNavigationBarTextAttributes];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 11.0, *)) {
        [self _updateNavigationBarTextAttributes];
    }
}

- (void)_updateNavigationBarTextAttributes API_AVAILABLE(ios(11.0)) {
    UITraitCollection *traitsTarget = self.navigationBar.traitCollection;
    UIFont *fontRef = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1 compatibleWithTraitCollection:traitsTarget];
    self.navigationBar.largeTitleTextAttributes = @{
        NSFontAttributeName : [UIFont systemFontOfSize:fontRef.pointSize weight:UIFontWeightBold]
    };
}

@end
