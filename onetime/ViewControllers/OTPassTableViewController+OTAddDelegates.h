//
//  OTPassTableViewController+OTAddDelegates.h
//  onetime
//
//  Created by Leptos on 2/16/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import "OTPassTableViewController.h"

#import "OTQRScanViewController.h"
#import "OTManualEntryViewController.h"

@interface OTPassTableViewController (OTQRScanControllerDelegate) <OTQRScanControllerDelegate>

@end

API_AVAILABLE(ios(11.0), tvos(11.0))
@interface OTPassTableViewController (OTImagePickerControllerDelegate) <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (void)bagsForQRCodeInImage:(UIImage *)image completionHandler:(void(^)(NSArray<OTBag *> *, NSError *))completion;

@end

@interface OTPassTableViewController (OTManualEntryControllerDelegate) <OTManualEntryControllerDelegate>

@end

API_AVAILABLE(ios(11.0))
@interface OTPassTableViewController (OTDropInteractionDelegate) <UIDropInteractionDelegate>

@end