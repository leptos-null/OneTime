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
#import "../../OneTimeKit/Models/OTBag.h"

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
    UINavigationController *navController = (__kindof UIViewController *)app.keyWindow.rootViewController;
    
    OTPassTableViewController *target = nil;
    for (__kindof UIViewController *controller in navController.viewControllers) {
        if ([controller isKindOfClass:[OTPassTableViewController class]]) {
            target = controller;
        }
    }
    if (target) {
        // todo: (bug) scroll does not work
        [target addBagsToTable:@[ bag ] scroll:YES animated:YES];
        return YES;
    }
    return NO;
}

- (void)application:(UIApplication *)app performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if ([shortcutItem.type isEqualToString:OTAppShortcutAddQRType]) {
        UINavigationController *navController = (__kindof UIViewController *)app.keyWindow.rootViewController;
        
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
            OTQRScanViewController *qrScanner = [OTQRScanViewController new];
            qrScanner.delegate = target;
            void (^readyBlock)(void) = ^{
                [target.navigationController pushViewController:qrScanner animated:NO];
                completionHandler(YES);
            };
            UIViewController *presentedController = target.presentedViewController;
            if (presentedController) {
                [presentedController dismissViewControllerAnimated:NO completion:readyBlock];
            } else {
                readyBlock();
            }
            return;
        }
    }
    completionHandler(NO);
}

@end
