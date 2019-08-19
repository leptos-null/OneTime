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

@implementation OTPassTableViewController {
    NSArray<OTBag *> *_dataSource;
    
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
    
    // Are settings needed?
    // self.navigationItem.leftBarButtonItem = /* TODO: Settings */;
    
    [self updateDataSource];
    //    CIQRCodeErrorCorrectionLevel correctionLevel = CIQRCodeErrorCorrectionLevelH;
    //    CIFilter *qrCodeGenerator = [CIFilter filterWithName:@"CIQRCodeGenerator" withInputParameters:@{
    //        @"inputMessage" : [bag.URL.absoluteString dataUsingEncoding:NSISOLatin1StringEncoding],
    //        @"inputCorrectionLevel" : [[NSString alloc] initWithBytes:&correctionLevel length:1 encoding:NSASCIIStringEncoding]
    //    }];
    //    UIImage *qrCode = [UIImage imageWithCIImage:qrCodeGenerator.outputImage];
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

- (void)_addBagsToTable:(NSArray<OTBag *> *)bags animated:(BOOL)animated {
    NSInteger const rowTarget = _dataSource.count;
    NSMutableArray<NSIndexPath *> *newPaths = [NSMutableArray arrayWithCapacity:bags.count];
    NSMutableArray<OTBag *> *newSource = [_dataSource mutableCopy];
    [bags enumerateObjectsUsingBlock:^(OTBag *bag, NSUInteger idx, BOOL *stop) {
        NSInteger const row = rowTarget + idx;
        bag.index = row;
        [bag syncToKeychain];
        newPaths[idx] = [NSIndexPath indexPathForRow:row inSection:0];
        newSource[row] = bag;
    }];
    
    if (animated) {
        // maybe scroll anyway?
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
                    // TODO: Present error to user
                    NSLog(@"bagsForQRCodeInImage: %@", error);
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (bags.count) {
                        [picker dismissViewControllerAnimated:YES completion:NULL];
                        [weakself _addBagsToTable:bags animated:YES];
                    } else {
                        // TODO: Warn user no bags found
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
            [self _addBagsToTable:@[ bag ] animated:YES];
            return;
        }
    }
}

- (void)qrScanController:(OTQRScanViewController *)controller didFailWithError:(NSError *)error {
    // TODO: Present error to user
    NSLog(@"qrScanControllerDidFailWithError: %@", error);
    [controller.navigationController popViewControllerAnimated:YES];
}

// MARK: - OTManualEntryControllerDelegate

- (void)manualEntryController:(OTManualEntryViewController *)controller createdBag:(OTBag *)bag {
    [controller.navigationController popViewControllerAnimated:YES];
    [self _addBagsToTable:@[ bag ] animated:YES];
}

// MARK: - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(section == 0);
    return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(indexPath.section == 0);
    
    OTPassTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PassCell" forIndexPath:indexPath];
    cell.editSource = self;
    cell.bag = _dataSource[indexPath.row];
    if (cell.bag.index != indexPath.row) {
        cell.bag.index = indexPath.row;
        [cell.bag syncToKeychain];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(indexPath.section == 0);
    
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete: {
            __weak __typeof(self) weakself = self;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Token?" message:@"Deleting a token cannot be undone. This action will not turn off 2FA for the account." preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                OTPassTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                [cell.bag deleteFromKeychain];
                [weakself updateDataSource];
                [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
            }]];
            [self presentViewController:alert animated:YES completion:NULL];
        } break;
        case UITableViewCellEditingStyleInsert: {
            // not supported right now
        } break;
            
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(fromIndexPath.section == 0);
    NSParameterAssert(toIndexPath.section == 0);
    
    NSInteger const
    start = MIN(fromIndexPath.row, toIndexPath.row),
    stop  = MAX(toIndexPath.row, fromIndexPath.row);
    
    NSMutableArray<OTBag *> *bags = [_dataSource mutableCopy];
    OTBag *target = bags[fromIndexPath.row];
    [bags removeObjectAtIndex:fromIndexPath.row];
    [bags insertObject:target atIndex:toIndexPath.row];
    for (NSInteger i = start; i <= stop; i++) {
        bags[i].index = i;
        [bags[i] syncToKeychain];
    }
    
    [self updateDataSource];
}

// MARK: - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(indexPath.section == 0);
    // I'm not sure I like the idea of overwriting the clipboard. preference?
    //    OTPassTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //    NSString *password = cell.bag.generator.password;
    //    UIPasteboard.generalPasteboard.string = password;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/4), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

// MARK: - OTEditingDataSource

- (BOOL)interfaceIsEditing {
    return _editModeFromButton;
}

@end
