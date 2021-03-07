//
//  main.m
//  OneTIcon
//
//  Created by Leptos on 9/5/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "AppDelegate/AppDelegate.h"

int main(int argc, char *argv[]) {
    NSString *appDelegateClassName;
    @autoreleasepool {
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
