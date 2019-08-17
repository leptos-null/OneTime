//
//  OTPadTextField.m
//  onetime
//
//  Created by Leptos on 8/16/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPadTextField.h"

@implementation OTPadTextField

// https://stackoverflow.com/a/17558493

- (CGRect)textRectForBounds:(CGRect)bounds {
    return [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, self.contentInsets)];
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [super editingRectForBounds:UIEdgeInsetsInsetRect(bounds, self.contentInsets)];
}

@end
