//
//  OTScreenshots.m
//  onetimeUITests
//
//  Created by Leptos on 1/28/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface OTScreenshots : XCTestCase

@end

@implementation OTScreenshots

- (void)setUp {
    self.continueAfterFailure = NO;
    
    // In UI tests it’s important to set the initial state - such as interface orientation -
    //   required for your tests before they run. The setUp method is a good place to do this.
}

- (BOOL)_writeScreenshot:(XCUIScreenshot *)screenshot name:(NSString *)name {
    static NSString *pathHead;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFileManager *fileManager = NSFileManager.defaultManager;
        
        NSString *compilePath = @__FILE__;
        NSString *root = compilePath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
        assert([fileManager fileExistsAtPath:root]);
        
        const char *model = getenv("SIMULATOR_MODEL_IDENTIFIER");
        NSCAssert(model, @"Screenshot collection should be run in the simulator");
        pathHead = [[root stringByAppendingPathComponent:@"Screenshots"] stringByAppendingPathComponent:@(model)];
        
        BOOL isDir = NO;
        if ([fileManager fileExistsAtPath:pathHead isDirectory:&isDir]) {
            NSCAssert(isDir, @"File exists at %@", pathHead);
        } else {
            [fileManager createDirectoryAtPath:pathHead withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        const char *const envKeys[] = {
            /* "SIMULATOR_VERSION_INFO", */
            "SIMULATOR_DEVICE_NAME",
            "SIMULATOR_RUNTIME_VERSION",
        };
        const size_t envKeysCount = sizeof(envKeys)/sizeof(envKeys[0]);
        const char *const *const envKeysEnd = envKeys + envKeysCount;
        
        NSMutableString *readme = [NSMutableString string];
        for (const char *const *envKey = envKeys; envKey < envKeysEnd; envKey++) {
            [readme appendFormat:@"%s=%s\n", *envKey, getenv(*envKey)];
        }
        NSString *path = [pathHead stringByAppendingPathComponent:@"README.txt"];
        [readme writeToFile:path atomically:YES encoding:NSASCIIStringEncoding error:NULL];
    });
    NSString *path = [pathHead stringByAppendingPathComponent:name];
    return [screenshot.PNGRepresentation writeToFile:[path stringByAppendingPathExtension:@"png"] atomically:YES];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGetScreenshots {
    XCUIApplication *app = [XCUIApplication new];
    
    [app launch];
    
    XCUIElement *mainNavBar = app.navigationBars[@"One-Time Passwords"];
    
    [mainNavBar.buttons[@"Add"] tap];
    [self _writeScreenshot:app.screenshot name:@"3_menu"];
    
    [app.sheets[@"Add Code"].scrollViews.otherElements.buttons[@"Manual Entry"] tap];
    XCUIElement *manualNavBar = app.navigationBars[@"Manual Entry"];
    [manualNavBar.staticTexts[@"Manual Entry"] tap]; /* we're not waiting on this screen long enough to get the screenshot */
    [self _writeScreenshot:app.screenshot name:@"4_manual"];
    
    [manualNavBar.buttons[@"One-Time Passwords"] tap];
    [self _writeScreenshot:app.screenshot name:@"0_home"];
    
    [mainNavBar.buttons[@"Edit"] tap];
    [self _writeScreenshot:app.screenshot name:@"5_edit"];
    [mainNavBar.buttons[@"Done"] tap];
    
    XCUIElement *searchField = mainNavBar.searchFields[@"Search"];
    [searchField tap];
    [searchField typeText:@"G"];
    [self _writeScreenshot:app.screenshot name:@"2_search"];
    [mainNavBar.buttons[@"Cancel"] tap];
    
    XCUIElement *table = app.tables.element;
    XCUIElement *twitter = [table.cells elementBoundByIndex:1];
    [twitter pressForDuration:1.2];
    [self _writeScreenshot:app.screenshot name:@"1_copy"];
}

@end
