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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add" message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Random" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (!weakself) {
            return;
        }
        __typeof(self) strongself = weakself;
        NSInteger const start = strongself->_dataSource.count;
        for (NSInteger i = start; i < (start + 5); i++) {
            OTPTime *totp = [OTPTime new];
            OTBag *bag = [[OTBag alloc] initWithGenerator:totp];
            bag.issuer = @"LeptosInternal";
            bag.account = [NSString stringWithFormat:@"leptos.testing.%@", @(i)];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //    OTPassTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //    NSString *password = cell.bag.generator.password;
    //    UIPasteboard.generalPasteboard.string = password;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/4), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

// Override to support editing the table view.
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

@end
