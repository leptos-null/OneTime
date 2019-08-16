//
//  OTPassTableViewController.h
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Vision/Vision.h>

#import "OTQRScanViewController.h"
#import "OTManualEntryViewController.h"

@interface OTPassTableViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, OTQRScanControllerDelegate, OTManualEntryControllerDelegate>

@end
