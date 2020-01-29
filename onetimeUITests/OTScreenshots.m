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
        const char *model = getenv("SIMULATOR_MODEL_IDENTIFIER");
        NSCAssert(model, @"Screenshot collection should be run in the simulator");
        NSString *compilePath = @__FILE__;
        NSString *root = compilePath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
        pathHead = [[root stringByAppendingPathComponent:@"Screenshots"] stringByAppendingPathComponent:@(model)];
        
        NSFileManager *fileManager = NSFileManager.defaultManager;
        BOOL isDir = NO;
        if ([fileManager fileExistsAtPath:pathHead isDirectory:&isDir]) {
            NSCAssert(isDir, @"File exists at %@", pathHead);
        } else {
            [fileManager createDirectoryAtPath:pathHead withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSMutableString *readme = [NSMutableString string];
        // [readme appendFormat:@"SIMULATOR_VERSION_INFO=%s\n", getenv("SIMULATOR_VERSION_INFO")];
        [readme appendFormat:@"SIMULATOR_DEVICE_NAME=%s\n", getenv("SIMULATOR_DEVICE_NAME")];
        [readme appendFormat:@"SIMULATOR_RUNTIME_VERSION=%s\n", getenv("SIMULATOR_RUNTIME_VERSION")];
        NSString *path = [pathHead stringByAppendingPathComponent:@"README.txt"];
        [readme writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
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
