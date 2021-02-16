//
//  OTAppDelegate.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTAppDelegate.h"
#import "../Services/OTLaunchOptions.h"
#import "../ViewControllers/OTPassTableViewController.h"
#import "../ViewControllers/UIViewController+OTDismissChildren.h"
#import "../../OneTimeKit/Models/OTBag.h"
#import "../../OneTimeKit/Services/OTBagCenter.h"
#import "../../OneTimeKit/Models/OTBag+CSItem.h"

static NSString *const OTAppShortcutAddQRType = @"null.leptos.onetime.add.qr";

@implementation OTAppDelegate

- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)options {
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
        UIApplicationShortcutIcon *icon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeCapturePhoto];
        UIApplicationShortcutItem *item = [[UIApplicationShortcutItem alloc] initWithType:OTAppShortcutAddQRType localizedTitle:@"Scan QR Code" localizedSubtitle:nil icon:icon userInfo:nil];
        app.shortcutItems = @[
            item
        ];
    }
    UIApplicationShortcutItem *shortcutItem = options[UIApplicationLaunchOptionsShortcutItemKey];
    if (shortcutItem) {
        if ([shortcutItem.type isEqualToString:OTAppShortcutAddQRType]) {
            OTLaunchOptions.defaultOptions.shouldPushLiveQR = YES;
        } else {
            return NO;
        }
    }
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options {
    OTBag *bag = [[OTBag alloc] initWithURL:url];
    if (!bag) {
        return NO;
    }
    
    [OTBagCenter.defaultCenter addBags:@[ bag ]];
    return YES;
}

- (void)application:(UIApplication *)app performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if ([shortcutItem.type isEqualToString:OTAppShortcutAddQRType]) {
        UINavigationController *navController = (__kindof UIViewController *)self.window.rootViewController;
        
        OTPassTableViewController *target = nil;
        for (__kindof UIViewController *controller in navController.viewControllers) {
            if ([controller isKindOfClass:[OTPassTableViewController class]]) {
                target = controller;
            } else if ([controller isKindOfClass:[OTQRScanViewController class]]) {
                [navController popToViewController:controller animated:NO];
                completionHandler(YES);
                return;
            }
        }
        if (target) {
            [target dismissAllChilderenAnimated:NO completion:^{
                [target pushLiveScanController:@"Scan QR Code (Live)"];
                completionHandler(YES);
            }];
            return;
        }
    }
    completionHandler(NO);
}

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType {
    NSArray<NSString *> *supported = @[
        CSSearchableItemActionType,
        CSQueryContinuationActionType
    ];
    return [supported containsObject:userActivityType];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *))restorationHandler {
    OTPassTableViewController *target = nil;
    UINavigationController *navController = (__kindof UIViewController *)self.window.rootViewController;
    for (__kindof UIViewController *controller in navController.viewControllers) {
        if ([controller isKindOfClass:[OTPassTableViewController class]]) {
            target = controller;
        }
    }
    if (target) {
        if ([userActivity.activityType isEqualToString:CSQueryContinuationActionType]) {
            NSString *searchKey = userActivity.userInfo[CSSearchQueryString];
            [target dismissAllChilderenAnimated:NO completion:^{
                // this doesn't seem to work as expected sometimes
                target.searchController.searchBar.text = searchKey;
                target.searchController.active = YES;
                CGFloat navHeight = CGRectGetMaxY(target.navigationController.navigationBar.frame);
                target.tableView.contentOffset = CGPointMake(0, -navHeight);
            }];
            return YES;
        } else if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
            NSString *uniqueID = userActivity.userInfo[CSSearchableItemActivityIdentifier];
            [target dismissAllChilderenAnimated:NO completion:NULL];
            return [target accentuateCellWithBagID:uniqueID];
        }
    }
    return NO;
}

@end
