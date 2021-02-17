//
//  OTPassTableViewController.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPassTableViewController.h"
#import "OTPassTableViewController+OTAddDelegates.h"
#import "UIViewController+UMSurfacer.h"

#import "../../OneTimeKit/Models/OTBag.h"
#import "../../OneTimeKit/Models/OTPTime.h"
#import "../../OneTimeKit/Models/OTPHash.h"
#import "../../OneTimeKit/Models/NSArray+OTMap.h"

#import "../Models/NSString+OTDistance.h"
#import "../Models/_OTBagScore.h"
#import "../Services/OTLaunchOptions.h"

@implementation OTPassTableViewController {
    NSArray<OTBag *> *_dataSource;
    NSArray<OTBag *> *_filteredSource;
    
    // if the receiver is editing per the edit button being clicked
    BOOL _editModeFromButton;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        OTBagCenter.defaultCenter.observer = self;
        [self updateDataSource];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *editButtonItem = self.editButtonItem;
    UIBarButtonItem *saveButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:nil action:nil];
    self.navigationItem.rightBarButtonItems = @[
        editButtonItem,
        saveButtonItem
    ];
    editButtonItem.target = self;
    editButtonItem.action = @selector(_editButtonHit:);
    
    if (@available(iOS 14.0, *)) {
        __weak __typeof(self) weakself = self;
        
        NSMutableArray<UIAction *> *children = [NSMutableArray array];
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            UIImage *cameraImage = [UIImage systemImageNamed:@"camera"];
            UIAction *liveScan = [UIAction actionWithTitle:@"Scan QR Code (Live)" image:cameraImage identifier:nil handler:^(UIAction *action) {
                [weakself pushLiveScanController:action.title];
            }];
            [children addObject:liveScan];
        }
        UIImage *qrImage = [UIImage systemImageNamed:@"qrcode"];
        UIAction *savedScan = [UIAction actionWithTitle:@"Scan QR Code (Saved)" image:qrImage identifier:nil handler:^(UIAction *action) {
            [weakself presentSavedScanController:action.title];
        }];
        [children addObject:savedScan];
        UIImage *writeImage = [UIImage systemImageNamed:@"rectangle.and.pencil.and.ellipsis"];
        UIAction *manualEntry = [UIAction actionWithTitle:@"Manual Entry" image:writeImage identifier:nil handler:^(UIAction *action) {
            [weakself pushManualEntryController:action.title];
        }];
        [children addObject:manualEntry];
        
        saveButtonItem.menu = [UIMenu menuWithTitle:@"Add Code" children:children];
    } else {
        saveButtonItem.target = self;
        saveButtonItem.action = @selector(_addButtonHit:);
    }
    
    // Settings should include local auth, code display/format preferences
    // self.navigationItem.leftBarButtonItem = /* TODO: Settings */;
    
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.searchResultsUpdater = self;
    if (@available(iOS 11.0, *)) {
        // unrelated to search controller, but requires iOS 11 too
        UIDropInteraction *dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
        dropInteraction.allowsSimultaneousDropSessions = YES;
        [self.view addInteraction:dropInteraction];
        
        self.navigationItem.searchController = searchController;
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    } else {
        self.tableView.tableHeaderView = searchController.searchBar;
    }
    _searchController = searchController;
    
    if (OTLaunchOptions.defaultOptions.shouldPushLiveQR) {
        [self pushLiveScanController:@"Scan QR Code (Live)"];
    }
}

- (NSArray<OTBag *> *)activeDataSource {
    return self.searchController.active ? _filteredSource : _dataSource;
}

- (void)updateDataSource {
    _dataSource = [OTBagCenter.defaultCenter keychainBagsCache:NO];
}

- (BOOL)accentuateCellWithBagID:(NSString *)identifier {
    NSInteger target = [self.activeDataSource indexOfObjectPassingTest:^BOOL(OTBag *obj, NSUInteger idx, BOOL *stop) {
        return [obj.uniqueIdentifier isEqualToString:identifier];
    }];
    if (target == NSNotFound) {
        return NO;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:target inSection:0];
    [self _accentuateRowAtIndexPath:indexPath duration:0.5];
    return YES;
}

- (void)pushLiveScanController:(NSString *)title {
    OTQRScanViewController *qrScanner = [OTQRScanViewController new];
    qrScanner.delegate = self;
    qrScanner.title = title;
    [self.navigationController pushViewController:qrScanner animated:YES];
}
// this API is available prior to iOS 11, however the API used in the delegate callback
//   is iOS 11+ so don't setup, since the picker won't do anything on those versions
- (void)presentSavedScanController:(NSString *)title API_AVAILABLE(ios(11.0), tvos(11.0)) {
    UIImagePickerController *imagePicker = [UIImagePickerController new];
    imagePicker.delegate = self;
    imagePicker.title = title;
    [self presentViewController:imagePicker animated:YES completion:NULL];
}
- (void)pushManualEntryController:(NSString *)title {
    OTManualEntryViewController *manual = [OTManualEntryViewController new];
    manual.delegate = self;
    manual.title = title;
    [self.navigationController pushViewController:manual animated:YES];
}

- (void)_accentuateRowAtIndexPath:(NSIndexPath *)indexPath duration:(NSTimeInterval)duration {
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

- (void)_addButtonHit:(UIBarButtonItem *)button {
    __weak __typeof(self) weakself = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Code" message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Scan QR Code (Live)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakself pushLiveScanController:action.title];
        }]];
    }
    if (@available(iOS 11.0, *)) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Scan QR Code (Saved)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakself presentSavedScanController:action.title];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Manual Entry" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakself pushManualEntryController:action.title];
    }]];
    alert.popoverPresentationController.barButtonItem = button;
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)_editButtonHit:(UIBarButtonItem *)button {
    BOOL newState = !self.editing;
    // our state needs to be set before calling `setEditing:`
    //   because it sends the same message to the table cells
    _editModeFromButton = newState;
    [self setEditing:newState animated:YES];
}

- (IBAction)_refreshControlEvent:(UIRefreshControl *)control {
    [self updateDataSource];
    [self.tableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/4), dispatch_get_main_queue(), ^{
        [control endRefreshing];
    });
}

// MARK: - OTBagCenterObserver

- (void)bagCenter:(OTBagCenter *)bagCenter addedBags:(NSArray<OTBag *> *)bags {
    NSInteger const originalDataSourceCount = _dataSource.count;
    
    _dataSource = [bagCenter keychainBagsCache:YES];
    if (!self.searchController.active) {
        NSInteger const addedCount = bags.count;
        NSMutableArray<NSIndexPath *> *newPaths = [NSMutableArray arrayWithCapacity:bags.count];
        
        for (NSInteger indexRow = 0; indexRow < addedCount; indexRow++) {
            newPaths[indexRow] = [NSIndexPath indexPathForRow:(originalDataSourceCount + indexRow) inSection:0];
        }
        
        [self.tableView insertRowsAtIndexPaths:newPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        for (NSIndexPath *indexPath in newPaths) {
            [self _accentuateRowAtIndexPath:indexPath duration:0.25];
        }
    }
}

- (void)bagCenter:(OTBagCenter *)bagCenter removedBags:(NSArray<OTBag *> *)bags {
    NSMutableArray<NSIndexPath *> *removePaths = [NSMutableArray arrayWithCapacity:bags.count];
    [[self activeDataSource] enumerateObjectsUsingBlock:^(OTBag *bag, NSUInteger row, BOOL *stop) {
        if ([bags indexOfObjectIdenticalTo:bag] != NSNotFound) {
            [removePaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
        }
    }];
    
    _dataSource = [bagCenter keychainBagsCache:YES];
    
    NSMutableArray<OTBag *> *filterPatch = [_filteredSource mutableCopy];
    for (OTBag *bag in bags) {
        [filterPatch removeObjectIdenticalTo:bag];
    }
    _filteredSource = [filterPatch copy];
    
    [self.tableView deleteRowsAtIndexPaths:removePaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)bagCenter:(OTBagCenter *)bagCenter bag:(OTBag *)bag encounteredError:(NSError *)error {
    NSLog(@"bagCenter: %@ bag: %@ encounteredError: %@", bagCenter, bagCenter, error);
    NSString *message = [NSString stringWithFormat:@"'%@' ('%@') encountered: %@", bag.issuer, bag.account, error.localizedDescription];
    
    NSUInteger bagIndex = [[self activeDataSource] indexOfObjectIdenticalTo:bag];
    UIView *viewHint = nil;
    if (bagIndex != NSNotFound) {
        NSIndexPath *bagPath = [NSIndexPath indexPathForRow:bagIndex inSection:0];
        viewHint = [self.tableView cellForRowAtIndexPath:bagPath];
    }
    [self surfaceUserMessage:message viewHint:viewHint dismissAfter:0];
}

// MARK: - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(section == 0);
    return self.activeDataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(indexPath.section == 0);
    
    NSString *identifier = OTPassTableViewCell.reusableIdentifier;
    OTPassTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    cell.editSource = self;
    cell.actionDelegate = self;
    cell.bag = self.activeDataSource[indexPath.row];
    if (cell.bag.index != indexPath.row && !self.searchController.active) {
        cell.bag.index = indexPath.row;
        [OTBagCenter.defaultCenter updateMetadata:cell.bag];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(indexPath.section == 0);
    return !self.searchController.active;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(indexPath.section == 0);
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OTPassTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self promptDeleteBag:cell.bag];
    } else {
        NSLog(@"tableViewCommitUnsupportedEditingStyle: %@", @(editingStyle));
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(fromIndexPath.section == 0);
    NSParameterAssert(toIndexPath.section == 0);
    
    NSAssert(!self.searchController.active, @"canMoveRowAtIndexPath: should prevent this getting called");
    
    NSInteger const
    start = MIN(fromIndexPath.row, toIndexPath.row),
    stop  = MAX(toIndexPath.row, fromIndexPath.row);
    
    NSMutableArray<OTBag *> *bags = [_dataSource mutableCopy];
    OTBag *target = bags[fromIndexPath.row];
    [bags removeObjectAtIndex:fromIndexPath.row];
    [bags insertObject:target atIndex:toIndexPath.row];
    for (NSInteger i = start; i <= stop; i++) {
        bags[i].index = i;
        [OTBagCenter.defaultCenter updateMetadata:bags[i]];
    }
    _dataSource = [bags copy];
}

// MARK: - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(indexPath.section == 0);
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// MARK: - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *filterKey = searchController.searchBar.text;
    NSArray<OTBag *> *dataSource = _dataSource;
    __weak __typeof(self) weakself = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray<_OTBagScore *> *distances = [NSMutableArray arrayWithCapacity:dataSource.count];
        NSStringCompareOptions const options = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch;
        [dataSource enumerateObjectsUsingBlock:^(OTBag *bag, NSUInteger idx, BOOL *stop) {
            NSInteger score =
            [bag.issuer  longestCommonSubsequence:filterKey options:options] +
            [bag.account longestCommonSubsequence:filterKey options:options] +
            [bag.comment longestCommonSubsequence:filterKey options:options];
            if (score > 0) {
                [distances addObject:[_OTBagScore bagScoreWithBag:bag score:score]];
            }
        }];
        [distances sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(_OTBagScore *a, _OTBagScore *b) {
            NSInteger const diff = a.score - b.score;
            if (diff == 0) {
                return NSOrderedSame;
            } else if (diff > 0) {
                return NSOrderedAscending;
            } else if (diff < 0) {
                return NSOrderedDescending;
            } else {
                __builtin_unreachable();
            }
        }];
        NSArray<OTBag *> *sorted = [distances map:^OTBag *(_OTBagScore *bagScore) {
            return bagScore.bag;
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakself) {
                __typeof(self) strongself = weakself;
                strongself->_filteredSource = sorted;
                [weakself.tableView reloadData];
            }
        });
    });
}

// MARK: - OTEditingDataSource

- (BOOL)interfaceIsEditing {
    return _editModeFromButton;
}

// MARK: - OTBagActionDelegate

- (void)promptDeleteBag:(OTBag *)bag {
    NSString *alertMsg = [NSString stringWithFormat:@""
                          "Deleting a token cannot be undone. This action will not turn off 2FA for the account.\n"
                          "%@: %@", bag.issuer, bag.account];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Token?" message:alertMsg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [OTBagCenter.defaultCenter removeBags:@[ bag ]];
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
}

@end
