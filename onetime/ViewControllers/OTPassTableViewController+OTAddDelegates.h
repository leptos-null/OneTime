//
//  OTPassTableViewController+OTAddDelegates.h
//  OneTime
//
//  Created by Leptos on 2/16/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import "OTPassTableViewController.h"

#import "OTQRScanViewController.h"
#import "OTManualEntryViewController.h"

@interface OTPassTableViewController (OTQRScanControllerDelegate) <OTQRScanControllerDelegate>

@end

API_DEPRECATED_WITH_REPLACEMENT("OTPickerViewControllerDelegate", ios(2.0, 14.0))
@interface OTPassTableViewController (OTImagePickerControllerDelegate) <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@interface OTPassTableViewController (OTManualEntryControllerDelegate) <OTManualEntryControllerDelegate>

@end

API_AVAILABLE(ios(11.0))
@interface OTPassTableViewController (OTDropInteractionDelegate) <UIDropInteractionDelegate>

@end

API_AVAILABLE(ios(14.0))
@interface OTPassTableViewController (OTPickerViewControllerDelegate) <PHPickerViewControllerDelegate>

@end
