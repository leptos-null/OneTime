//
//  ViewController.m
//  oneticon
//
//  Created by Leptos on 9/5/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "ViewController.h"

#if !DEBUG
#   error This tool is not for public use
#endif

@implementation ViewController

- (UIImage *)iconForDimension:(CGFloat)dimension scale:(CGFloat)scale inset:(BOOL)inset {
    CGFloat const offset = inset ? dimension/16 : 0;
    CGRect const fullFrame = CGRectMake(0, 0, dimension, dimension);
    dimension -= (offset * 2);
    CGRect const frame = CGRectMake(offset, offset, dimension, dimension);
    CGFloat const radius = dimension/2 + offset;
    
    UIGraphicsBeginImageContextWithOptions(fullFrame.size, NO, scale);
    
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
        [ticks moveToPoint:CGPointMake(innerTickRadius*xPos + radius, innerTickRadius*yPos + radius)];
        [ticks addLineToPoint:CGPointMake(outerTickRadius*xPos + radius, outerTickRadius*yPos + radius)];
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
        [vaultHandle moveToPoint:CGPointMake(radius, radius)];
        [vaultHandle addLineToPoint:CGPointMake(spokeLength*xPos + radius, spokeLength*yPos + radius)];
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
    NSArray<NSMutableDictionary<NSString *, NSString *> *> *images = dict[@"images"];
    for (NSMutableDictionary<NSString *, NSString *> *image in images) {
        NSString *scale = image[@"scale"];
        NSString *size = image[@"size"];
        NSInteger scaleLastIndex = scale.length - 1;
        assert([scale characterAtIndex:scaleLastIndex] == 'x');
        NSString *numScale = [scale substringToIndex:scaleLastIndex];
        
        NSArray<NSString *> *sizeParts = [size componentsSeparatedByString:@"x"];
        assert(sizeParts.count == 2);
        NSString *numSize = sizeParts.firstObject;
        assert([numSize isEqualToString:sizeParts.lastObject]);
        
        NSString *fileName = [NSString stringWithFormat:@"AppIcon%@@%@.png", size, scale];
        UIImage *render = [self iconForDimension:numSize.doubleValue scale:numScale.doubleValue inset:inset];
        NSData *fileData = UIImagePNGRepresentation(render);
        assert([fileData writeToFile:[appiconset stringByAppendingPathComponent:fileName] atomically:YES]);
        image[@"filename"] = fileName;
    }
    NSData *serial = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    assert([serial writeToFile:manifest atomically:YES]);
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
    CGRect const rect = imageView.frame;
    imageView.image = [self iconForDimension:fmin(rect.size.width, rect.size.height) scale:0 inset:NO];
}

@end
