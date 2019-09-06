//
//  ViewController.m
//  oneticon
//
//  Created by Leptos on 9/5/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (UIImage *)iconForDimension:(CGFloat)dimension scale:(CGFloat)scale {
    CGRect const frame = CGRectMake(0, 0, dimension, dimension);
    
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, scale);
    
    [[UIColor lightGrayColor] setFill];
    [[UIBezierPath bezierPathWithOvalInRect:frame] fill];
    
    [[UIColor darkGrayColor] setFill];
    CGFloat const secondCircleInset = dimension * 0.16;
    [[UIBezierPath bezierPathWithOvalInRect:CGRectInset(frame, secondCircleInset, secondCircleInset)] fill];
    
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIImageView *imageView = self.imageView;
    CGRect const rect = imageView.frame;
    imageView.image = [self iconForDimension:fmin(rect.size.width, rect.size.height) scale:0];
}

@end
