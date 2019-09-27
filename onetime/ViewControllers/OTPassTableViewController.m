//
//  OTPassTableViewController.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPassTableViewController.h"

#import "../../OneTimeKit/Models/OTBag.h"
#import "../../OneTimeKit/Models/OTPTime.h"
#import "../../OneTimeKit/Models/OTPHash.h"

#import "../Models/NSString+OTDistance.h"
#import "../Models/_OTBagScore.h"

@implementation OTPassTableViewController {
    NSArray<OTBag *> *_dataSource;
    NSArray<OTBag *> *_filteredSource;
    
    // if the receiver is editing per the edit button being clicked
    BOOL _editModeFromButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[
        self.editButtonItem,
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(_addButtonHit:)]
    ];
    self.editButtonItem.target = self;
    self.editButtonItem.action = @selector(_editButtonHit:);
    
    // Settings should include local auth, code display/format preferences
    // self.navigationItem.leftBarButtonItem = /* TODO: Settings */;
    
    [self updateDataSource];
    
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.searchResultsUpdater = self;
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = searchController;
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    } else {
        self.tableView.tableHeaderView = searchController.searchBar;
    }
    _searchController = searchController;
}

- (NSArray<OTBag *> *)activeDataSource {
    return self.searchController.active ? _filteredSource : _dataSource;
}

- (void)updateDataSource {
    _dataSource = [OTBag.keychainBags sortedArrayUsingFunction:OTBagCompareUsingIndex context:NULL];
}

- (void)_addButtonHit:(UIBarButtonItem *)button {
    __weak __typeof(self) weakself = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Code" message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Scan QR Code (Live)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            OTQRScanViewController *qrScanner = [OTQRScanViewController new];
            qrScanner.delegate = weakself;
            qrScanner.title = action.title;
            [weakself.navigationController pushViewController:qrScanner animated:YES];
        }]];
    }
    if (@available(iOS 11.0, *)) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Scan QR Code (Saved)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIImagePickerController *imagePicker = [UIImagePickerController new];
            imagePicker.delegate = weakself;
            [weakself presentViewController:imagePicker animated:YES completion:NULL];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Manual Entry" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSBundle *manualBundle = [NSBundle bundleForClass:[OTManualEntryViewController class]];
        UIStoryboard *manualStoryboard = [UIStoryboard storyboardWithName:@"Manual" bundle:manualBundle];
        OTManualEntryViewController *manual = [manualStoryboard instantiateInitialViewController];
        manual.delegate = weakself;
        manual.title = action.title;
        [weakself.navigationController pushViewController:manual animated:YES];
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

- (void)_addBagsToTable:(NSArray<OTBag *> *)bags scroll:(BOOL)shouldScroll animated:(BOOL)animated {
    NSInteger const rowTarget = _dataSource.count;
    NSMutableArray<NSIndexPath *> *newPaths = [NSMutableArray arrayWithCapacity:bags.count];
    NSMutableArray<OTBag *> *newSource = [_dataSource mutableCopy];
    [bags enumerateObjectsUsingBlock:^(OTBag *bag, NSUInteger idx, BOOL *stop) {
        NSInteger const row = rowTarget + idx;
        bag.index = row;
        OSStatus syncStatus = [bag syncToKeychain];
        if (syncStatus == errSecSuccess) {
            newPaths[idx] = [NSIndexPath indexPathForRow:row inSection:0];
            newSource[row] = bag;
        } else {
            NSString *errorStr = OTSecErrorToString(syncStatus);
            NSLog(@"syncToKeychain: %@ (%" __INT32_FMTd__ ")", errorStr, syncStatus);
            NSString *message = [@"Failed to add token to keychain: " stringByAppendingString:errorStr];
            [self surfaceUserMessage:message viewHint:nil dismissAfter:0];
        }
    }];
    
    if (shouldScroll && (rowTarget >= 1)) {
        NSIndexPath *scrollTarget = [NSIndexPath indexPathForRow:(rowTarget - 1) inSection:0];
        [self.tableView scrollToRowAtIndexPath:scrollTarget atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
    _dataSource = [newSource copy];
    UITableViewRowAnimation anim = animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone;
    [self.tableView insertRowsAtIndexPaths:newPaths withRowAnimation:anim];
}

- (void)bagsForQRCodeInImage:(UIImage *)image completionHandler:(void(^)(NSArray<OTBag *> *, NSError *))completion API_AVAILABLE(ios(11.0), tvos(11.0)) {
    VNRequestCompletionHandler barcodeHandler = ^(VNRequest *request, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        NSMutableArray<OTBag *> *bags = [NSMutableArray array];
        for (VNBarcodeObservation *barcode in request.results) {
            OTBag *bag = [[OTBag alloc] initWithURL:[NSURL URLWithString:barcode.payloadStringValue]];
            if (bag) {
                [bags addObject:bag];
            }
        }
        completion([bags copy], nil);
    };
    
    VNDetectBarcodesRequest *qrRequest = [[VNDetectBarcodesRequest alloc] initWithCompletionHandler:barcodeHandler];
    qrRequest.symbologies = @[ VNBarcodeSymbologyQR ];
    VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{
        
    }];
    NSError *err = NULL;
    [requestHandler performRequests:@[ qrRequest ] error:&err];
    if (err) {
        completion(nil, err);
    }
}

// MARK: - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (@available(iOS 11.0, *)) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        __weak __typeof(self) weakself = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [weakself bagsForQRCodeInImage:image completionHandler:^(NSArray<OTBag *> *bags, NSError *error) {
                if (error) {
                    NSLog(@"bagsForQRCodeInImage: %@", error);
                    [picker surfaceUserMessage:error.localizedDescription viewHint:nil dismissAfter:0];
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (bags.count) {
                        [picker dismissViewControllerAnimated:YES completion:NULL];
                        [weakself _addBagsToTable:bags scroll:YES animated:YES];
                    } else {
                        [picker surfaceUserMessage:@"No valid codes found" viewHint:nil dismissAfter:0.85];
                    }
                });
            }];
        });
    }
}

// MARK: - OTQRScanControllerDelegate

- (void)qrScanController:(OTQRScanViewController *)controller didFindPayloads:(NSArray<NSString *> *)payloads {
    // currently not handling multiple good payloads, but it's unlikely, and not a big issue
    //   i.e. as soon as a good payload comes in, we return out, potentially ignoring another
    for (NSString *payload in payloads) {
        OTBag *bag = [[OTBag alloc] initWithURL:[NSURL URLWithString:payload]];
        if (bag) {
            // we're good- stop receiving delegate calls (a little bit of a hack)
            controller.delegate = nil;
            [controller.navigationController popViewControllerAnimated:YES];
            [self _addBagsToTable:@[ bag ] scroll:YES animated:YES];
            return;
        }
    }
}

- (void)qrScanController:(OTQRScanViewController *)controller didFailWithError:(NSError *)error {
    NSLog(@"qrScanControllerDidFailWithError: %@", error);
    [self surfaceUserMessage:error.localizedDescription viewHint:nil  dismissAfter:0];
    [controller.navigationController popViewControllerAnimated:YES];
}

// MARK: - OTManualEntryControllerDelegate

- (void)manualEntryController:(OTManualEntryViewController *)controller createdBag:(OTBag *)bag {
    [controller.navigationController popViewControllerAnimated:YES];
    [self _addBagsToTable:@[ bag ] scroll:YES animated:YES];
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
    cell.messageSurfacer = self;
    cell.bag = self.activeDataSource[indexPath.row];
    if (cell.bag.index != indexPath.row && !self.searchController.active) {
        cell.bag.index = indexPath.row;
        OSStatus syncStatus = [cell.bag syncToKeychain];
        if (syncStatus != errSecSuccess) {
            // this isn't a user initiated event, the user doesn't need to know about it (but we might!)
            NSLog(@"syncToKeychain: %@", OTSecErrorToString(syncStatus));
        }
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(indexPath.section == 0);
    return !self.searchController.active;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(indexPath.section == 0);
    return !self.searchController.active;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(indexPath.section == 0);
    if (self.searchController.active) {
        return;
    }
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        __weak __typeof(self) weakself = self;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Token?" message:@"Deleting a token cannot be undone. This action will not turn off 2FA for the account." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            OTPassTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [cell.bag deleteFromKeychain];
            if (weakself) {
                __typeof(self) strongself = weakself;
                NSMutableArray<OTBag *> *patchSource = [strongself->_dataSource mutableCopy];
                [patchSource removeObjectAtIndex:indexPath.row];
                strongself->_dataSource = [patchSource copy];
                [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }]];
        [self presentViewController:alert animated:YES completion:NULL];
    } else {
        NSLog(@"tableViewCommitUnsupportedEditingStyle: %@", @(editingStyle));
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(fromIndexPath.section == 0);
    NSParameterAssert(toIndexPath.section == 0);
    if (self.searchController.active) {
        return;
    }
    
    NSInteger const
    start = MIN(fromIndexPath.row, toIndexPath.row),
    stop  = MAX(toIndexPath.row, fromIndexPath.row);
    
    NSMutableArray<OTBag *> *bags = [_dataSource mutableCopy];
    OTBag *target = bags[fromIndexPath.row];
    [bags removeObjectAtIndex:fromIndexPath.row];
    [bags insertObject:target atIndex:toIndexPath.row];
    BOOL hasPresentedErr = NO;
    for (NSInteger i = start; i <= stop; i++) {
        bags[i].index = i;
        OSStatus syncStatus = [bags[i] syncToKeychain];
        if (syncStatus != errSecSuccess) {
            NSString *errorStr = OTSecErrorToString(syncStatus);
            NSLog(@"syncToKeychain: %@ (%" __INT32_FMTd__ ")", errorStr, syncStatus);
            if (!hasPresentedErr) {
                hasPresentedErr = YES;
                UIView *viewHint = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                NSString *message = [@"Failed to sync keychain token order: " stringByAppendingString:errorStr];
                [self surfaceUserMessage:message viewHint:viewHint dismissAfter:0];
            }
        }
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
        NSMutableArray<OTBag *> *sorted = [NSMutableArray arrayWithCapacity:distances.count];
        [distances enumerateObjectsUsingBlock:^(_OTBagScore *bagScore, NSUInteger idx, BOOL *stop) {
            sorted[idx] = bagScore.bag;
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakself) {
                __typeof(self) strongself = weakself;
                strongself->_filteredSource = [sorted copy];
                [weakself.tableView reloadData];
            }
        });
    });
}

// MARK: - OTEditingDataSource

- (BOOL)interfaceIsEditing {
    return _editModeFromButton;
}

@end
