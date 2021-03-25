//
//  ViewController.m
//  OneTIcon
//
//  Created by Leptos on 9/5/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "ViewController.h"

#if !DEBUG
#   error This tool is not for public use
#endif

@implementation ViewController

- (UIImage *)iconForSize:(CGSize)size scale:(CGFloat)scale inset:(BOOL)inset fill:(BOOL)fillBackground {
    CGFloat dimension = fmin(size.width, size.height);
    
    CGFloat const offset = inset ? dimension/16 : 0;
    CGFloat const xInset = (size.width - dimension)/2 + offset;
    CGFloat const yInset = (size.height - dimension)/2 + offset;
    
    CGRect const fullFrame = CGRectMake(0, 0, size.width, size.height);
    dimension -= (offset * 2);
    CGRect const frame = CGRectMake(xInset, yInset, dimension, dimension);
    CGFloat const radius = dimension/2;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    
    if (fillBackground) {
        [[UIColor blackColor] setFill];
        [[UIBezierPath bezierPathWithRect:fullFrame] fill];
    }
    [[UIColor lightGrayColor] setFill];
    [[UIBezierPath bezierPathWithOvalInRect:frame] fill];
    
    [[UIColor darkGrayColor] setFill];
    
    CGFloat const secondCircleFactor = 0.16;
    CGFloat const secondCircleInset = dimension * secondCircleFactor;
    [[UIBezierPath bezierPathWithOvalInRect:CGRectInset(frame, secondCircleInset, secondCircleInset)] fill];
    
    UIBezierPath *ticks = [UIBezierPath bezierPath];
    NSInteger const tickCount = 12;
    for (NSInteger tickIndex = 0; tickIndex < tickCount; tickIndex++) {
        CGFloat const averageTickRadius = dimension*(1 - secondCircleFactor)/2;
        CGFloat const tickHeightDiff = dimension/28; // tick height on each side of the average radius
        CGFloat const innerTickRadius = averageTickRadius - tickHeightDiff, outerTickRadius = averageTickRadius + tickHeightDiff;
        double position = (double)tickIndex/tickCount;
        position *= 2 * M_PI;
        CGFloat const xPos = cos(position), yPos = sin(position);
        [ticks moveToPoint:CGPointMake(xInset + innerTickRadius*xPos + radius, yInset + innerTickRadius*yPos + radius)];
        [ticks addLineToPoint:CGPointMake(xInset + outerTickRadius*xPos + radius, yInset + outerTickRadius*yPos + radius)];
    }
    ticks.lineWidth = dimension/50;
    ticks.lineCapStyle = kCGLineCapRound;
    [[UIColor darkGrayColor] setStroke];
    [ticks stroke];
    
    UIBezierPath *hand = [UIBezierPath bezierPath];
    hand.lineCapStyle = kCGLineCapRound;
    hand.lineWidth = dimension/46;
    
    CGFloat const handleRingDiameter = dimension*0.3;
    UIBezierPath *vaultHandle = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(frame, handleRingDiameter, handleRingDiameter)];
    
    NSInteger const vaultSpokeCount = 5;
    for (NSInteger vaultSpokeIndex = 0; vaultSpokeIndex < vaultSpokeCount; vaultSpokeIndex++) {
        CGFloat const spokeLength = dimension/5;
        double position = (double)vaultSpokeIndex/vaultSpokeCount;
        position *= 2 * M_PI;
        CGFloat const xPos = cos(position), yPos = sin(position);
        [vaultHandle moveToPoint:CGPointMake(xInset + radius, yInset + radius)];
        [vaultHandle addLineToPoint:CGPointMake(xInset + spokeLength*xPos + radius, yInset + spokeLength*yPos + radius)];
    }
    vaultHandle.lineWidth = dimension/42;
    vaultHandle.lineCapStyle = kCGLineCapRound;
    [[UIColor colorWithRed:183.0/0xff green:134.0/0xff blue:039.0/0xff alpha:1] setStroke];
    [vaultHandle stroke];
    
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}

// e.g. "Assets.xcassets/AppIcon.appiconset"
- (void)writeIconAssetsForIconSet:(NSString *)appiconset inset:(BOOL)inset {
    NSString *manifest = [appiconset stringByAppendingPathComponent:@"Contents.json"];
    NSData *parse = [NSData dataWithContentsOfFile:manifest];
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:parse options:(NSJSONReadingMutableContainers) error:&error];
    NSArray<NSString *> *fillIdioms = @[
        @"iphone",
        @"ipad",
        @"watch",
        @"ios-marketing",
        @"watch-marketing"
    ];
    NSArray<NSMutableDictionary<NSString *, NSString *> *> *images = dict[@"images"];
    for (NSMutableDictionary<NSString *, NSString *> *image in images) {
        NSString *scale = image[@"scale"];
        NSString *dimensions = image[@"size"];
        NSInteger scaleLastIndex = scale.length - 1;
        assert([scale characterAtIndex:scaleLastIndex] == 'x');
        NSString *numScale = [scale substringToIndex:scaleLastIndex];
        
        NSArray<NSString *> *sizeParts = [dimensions componentsSeparatedByString:@"x"];
        assert(sizeParts.count == 2);
        NSString *sizeWidth = sizeParts[0];
        NSString *sizeHeight = sizeParts[1];
        
        NSString *fileName = [NSString stringWithFormat:@"AppIcon%@@%@.png", dimensions, scale];
        BOOL fill = [fillIdioms containsObject:image[@"idiom"]];
        CGSize size = CGSizeMake(sizeWidth.doubleValue, sizeHeight.doubleValue);
        
        UIImage *render = [self iconForSize:size scale:numScale.doubleValue inset:inset fill:fill];
        NSData *fileData = UIImagePNGRepresentation(render);
        assert([fileData writeToFile:[appiconset stringByAppendingPathComponent:fileName] atomically:YES]);
        image[@"filename"] = fileName;
    }
    NSData *serial = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    assert([serial writeToFile:manifest atomically:YES]);
}

- (void)writeGitHubPreview:(NSString *)path scale:(CGFloat)scale {
    UIImage *render = [self iconForSize:CGSizeMake(1280/scale, 640/scale) scale:scale inset:YES fill:YES];
    NSData *fileData = UIImagePNGRepresentation(render);
    assert([fileData writeToFile:path atomically:YES]);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *file = @__FILE__;
    NSString *projectRoot = file.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    NSString *mobileSet = [projectRoot stringByAppendingPathComponent:@"onetime/Assets.xcassets/AppIcon.appiconset"];
    NSString *nanoSet = [projectRoot stringByAppendingPathComponent:@"nanonetime/Assets.xcassets/AppIcon.appiconset"];
    [self writeIconAssetsForIconSet:mobileSet inset:YES];
    [self writeIconAssetsForIconSet:nanoSet inset:NO];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIImageView *imageView = self.imageView;
    imageView.image = [self iconForSize:imageView.frame.size scale:0 inset:NO fill:NO];
}

@end
