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
#import "../Views/OTPassTableViewCell.h"

@interface OTPassTableViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDropInteractionDelegate, UISearchResultsUpdating, OTQRScanControllerDelegate, OTManualEntryControllerDelegate, OTEditingDataSource>

@property (strong, nonatomic, readonly) UISearchController *searchController;

- (void)addBagsToTable:(NSArray<OTBag *> *)bags scroll:(BOOL)shouldScroll animated:(BOOL)animated;
- (BOOL)accentuateCellWithBagID:(NSString *)identifier;

@end
