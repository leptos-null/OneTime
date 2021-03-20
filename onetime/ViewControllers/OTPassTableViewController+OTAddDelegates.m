//
//  OTPassTableViewController+OTAddDelegates.m
//  OneTime
//
//  Created by Leptos on 2/16/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import <CoreImage/CoreImage.h>

#import "OTPassTableViewController+OTAddDelegates.h"
#import "UIViewController+UMSurfacer.h"
#import "../../OneTimeKit/Models/NSArray+OTMap.h"

@implementation OTPassTableViewController (OTQRScanControllerDelegate)

- (void)qrScanController:(OTQRScanViewController *)controller didFindPayloads:(NSArray<NSString *> *)payloads {
    NSArray<OTBag *> *bags = [payloads compactMap:^OTBag *(NSString *payload) {
        return [[OTBag alloc] initWithURL:[NSURL URLWithString:payload]];
    }];
    if (bags.count != 0) {
        [controller.navigationController popToViewController:self animated:YES];
        [OTBagCenter.defaultCenter addBags:bags];
    }
}

- (void)qrScanController:(OTQRScanViewController *)controller didFailWithError:(NSError *)error {
    NSLog(@"qrScanControllerDidFailWithError: %@", error);
    [self surfaceUserMessage:error.localizedDescription viewHint:nil dismissAfter:0];
    [controller.navigationController popToViewController:self animated:YES];
}

- (UIColor *)qrScanController:(OTQRScanViewController *)controller colorForPayload:(NSString *)payload {
    // if a bag can be created from the payload, color it green, otherwise red
    OTBag *bag = [[OTBag alloc] initWithURL:[NSURL URLWithString:payload]];
    return bag ? UIColor.systemGreenColor : UIColor.systemRedColor;
}

@end


@implementation OTPassTableViewController (OTImagePickerControllerDelegate)

- (NSArray<OTBag *> *)bagsForQRCodeInImage:(UIImage *)image {
    static CIDetector *detector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary<CIContextOption, id> *options = [NSMutableDictionary dictionary];
        if (@available(iOS 12.0, *)) {
            options[kCIContextName] = @"null.leptos.onetime.detector.qr";
        }
        CIContext *context = [CIContext contextWithOptions:options];
        detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:context options:@{
            // this is so fast, and not going to happen that often - opt into higher accuracy
            CIDetectorAccuracy : CIDetectorAccuracyHigh
        }];
    });
    
    CIImage *coreImage = [image CIImage] ?: [CIImage imageWithCGImage:[image CGImage]];
    NSArray<__kindof CIFeature *> *features = [detector featuresInImage:coreImage];
    NSArray<OTBag *> *bags = [features compactMap:^OTBag *(CIQRCodeFeature *feature) {
        if (!OTKindofClass(feature, CIQRCodeFeature)) {
            return nil;
        }
        return [[OTBag alloc] initWithURL:[NSURL URLWithString:feature.messageString]];
    }];
    return bags;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    __weak __typeof(self) weakself = self;
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<OTBag *> *bags = [weakself bagsForQRCodeInImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bags.count) {
                [picker dismissViewControllerAnimated:YES completion:NULL];
                [OTBagCenter.defaultCenter addBags:bags];
            } else {
                [picker surfaceUserMessage:@"No valid codes found" viewHint:nil dismissAfter:0.85];
            }
        });
    });
}

@end


@implementation OTPassTableViewController (OTManualEntryControllerDelegate)

- (void)manualEntryController:(OTManualEntryViewController *)controller createdBag:(OTBag *)bag {
    [controller.navigationController popToViewController:self animated:YES];
    [OTBagCenter.defaultCenter addBags:@[ bag ]];
}

@end


API_AVAILABLE(ios(11.0))
@implementation OTPassTableViewController (OTDropInteractionDelegate)

- (BOOL)dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session {
    return [session canLoadObjectsOfClass:[UIImage class]];
}

- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session {
    return [[UIDropProposal alloc] initWithDropOperation:UIDropOperationCopy];
}

- (void)dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session {
    __typeof(self) weakself = self;
    Class<NSItemProviderReading> const imageClass = [UIImage class];
    
    for (UIDragItem *item in session.items) {
        NSItemProvider *provider = item.itemProvider;
        if (![provider canLoadObjectOfClass:imageClass]) {
            continue;
        }
        [provider loadObjectOfClass:imageClass completionHandler:^(id<NSItemProviderReading> image, NSError *loadErr) {
            if (loadErr) {
                NSLog(@"loadObjectOfClassCompletedWithError: %@", loadErr);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself surfaceUserMessage:loadErr.localizedDescription viewHint:nil dismissAfter:0];
                });
                return;
            }
            if (![image isKindOfClass:imageClass]) {
                NSLog(@"loadObjectOfUIImageClass object is not UIImage");
                return;
            }
            NSArray<OTBag *> *bags = [weakself bagsForQRCodeInImage:(UIImage *)image];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bags.count) {
                    [OTBagCenter.defaultCenter addBags:bags];
                } else {
                    [weakself surfaceUserMessage:@"No valid codes found" viewHint:interaction.view dismissAfter:0];
                }
            });
        }];
    }
}

@end
