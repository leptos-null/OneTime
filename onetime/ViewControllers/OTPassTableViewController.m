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

#import "../Views/OTPassTableViewCell.h"

@implementation OTPassTableViewController {
    NSArray<OTBag *> *_dataSource;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[
        self.editButtonItem,
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(_addButtonHit:)]
    ];
    // Are settings needed?
    // self.navigationItem.leftBarButtonItem = /* TODO: Settings */;
    [self.refreshControl addTarget:self action:@selector(_refreshControlEvent:) forControlEvents:UIControlEventValueChanged];
    
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
    // DEBUG
    [alert addAction:[UIAlertAction actionWithTitle:@"Random" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (!weakself) {
            return;
        }
        __typeof(self) strongself = weakself;
        NSInteger const start = strongself->_dataSource.count, stop = start + 5;
        for (NSInteger i = start; i < stop; i++) {
            OTPTime *totp = [OTPTime new];
            OTBag *bag = [[OTBag alloc] initWithGenerator:totp];
            bag.issuer = @"LeptosInternal";
            bag.account = [@"leptos.testing" stringByAppendingPathExtension:@(i).stringValue];
            bag.index = i;
            [bag syncToKeychain];
        }
        
        [strongself updateDataSource];
        [strongself.tableView reloadData];
    }]];
    
    alert.popoverPresentationController.barButtonItem = button;
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)_refreshControlEvent:(UIRefreshControl *)control {
    [self updateDataSource];
    [self.tableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/4), dispatch_get_main_queue(), ^{
        [control endRefreshing];
    });
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
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    __weak __typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakself bagsForQRCodeInImage:image completionHandler:^(NSArray<OTBag *> *bags, NSError *error) {
            if (error) {
                // TODO: Present error to user
                NSLog(@"bagsForQRCodeInImage: %@", error);
                return;
            }
            // TODO: Handle bags
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bags.count) {
                    [picker dismissViewControllerAnimated:YES completion:NULL];
                    
                } else {
                    // TODO: Warn user no bags found
                }
            });
        }];
    });
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
            
            NSInteger const rowTarget = _dataSource.count;
            bag.index = rowTarget;
            [bag syncToKeychain];
            [self updateDataSource];
            
            [controller.navigationController popViewControllerAnimated:YES];
            
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(rowTarget - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            [self.tableView insertRowsAtIndexPaths:@[
                [NSIndexPath indexPathForRow:rowTarget inSection:0]
            ] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    NSInteger const rowTarget = _dataSource.count;
    bag.index = rowTarget;
    [bag syncToKeychain];
    [self updateDataSource];
    
    [controller.navigationController popViewControllerAnimated:YES];
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(rowTarget - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    [self.tableView insertRowsAtIndexPaths:@[
        [NSIndexPath indexPathForRow:rowTarget inSection:0]
    ] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    cell.bag = _dataSource[indexPath.row];
    if (cell.bag.index != indexPath.row) {
        cell.bag.index = indexPath.row;
        [cell.bag syncToKeychain];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete: {
            OTPassTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [cell.bag deleteFromKeychain];
            [self updateDataSource];
            [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
        } break;
        case UITableViewCellEditingStyleInsert: {
            // not supported right now
        } break;
            
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
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
    // I'm not sure I like the idea of overwriting the clipboard. preference?
    //    OTPassTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //    NSString *password = cell.bag.generator.password;
    //    UIPasteboard.generalPasteboard.string = password;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/4), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

@end
