//
//  OTPassTableViewController.h
//  OneTime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "../../OneTimeKit/Services/OTBagCenter.h"

#import "../Views/OTPassTableViewCell.h"

@interface OTPassTableViewController : UITableViewController <UISearchResultsUpdating, OTEditingDataSource, OTBagCenterObserver, OTBagActionDelegate>

@property (strong, nonatomic, readonly) UISearchController *searchController;

@property (strong, nonatomic) IBOutlet UIView *emptyListView;

- (BOOL)accentuateCellWithBagID:(NSString *)identifier;

- (void)pushLiveScanController:(NSString *)title;
- (void)presentSavedScanController:(NSString *)title API_AVAILABLE(ios(11.0), tvos(11.0));
- (void)pushManualEntryController:(NSString *)title;

@end
