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

@implementation OTScreenshots {
    NSString *_pathHead;
    NSMutableArray<NSString *> *_screenshotPaths;
}

- (void)setUp {
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    NSString *compilePath = @__FILE__;
    NSString *root = compilePath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    NSAssert([fileManager fileExistsAtPath:root], @"Cannot find project path");
    
    const char *model = getenv("SIMULATOR_MODEL_IDENTIFIER");
    NSAssert(model != NULL, @"Screenshot collection should be run in the simulator");
    NSString *pathHead = [[root stringByAppendingPathComponent:@"Screenshots"] stringByAppendingPathComponent:@(model)];
    
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:pathHead isDirectory:&isDir]) {
        NSAssert(isDir, @"File exists at %@", pathHead);
    } else {
        [fileManager createDirectoryAtPath:pathHead withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    _pathHead = pathHead;
    _screenshotPaths = [NSMutableArray arrayWithCapacity:7];
}

- (void)tearDown {
    NSMutableString *readme = [NSMutableString string];
    [readme appendFormat:@"## %s %s\n\n", getenv("SIMULATOR_DEVICE_NAME"), getenv("SIMULATOR_RUNTIME_VERSION")];
    
    NSArray<NSString *> *screenshotPaths = [_screenshotPaths sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    for (NSString *screenshotPath in screenshotPaths) {
        [readme appendFormat:@"![%@](%@)\n\n", screenshotPath.stringByDeletingPathExtension, screenshotPath];
    }
    
    NSString *path = [_pathHead stringByAppendingPathComponent:@"README.md"];
    [readme writeToFile:path atomically:YES encoding:NSASCIIStringEncoding error:NULL];
}

- (BOOL)_writeScreenshot:(XCUIScreenshot *)screenshot name:(NSString *)name {
    NSString *path = [name stringByAppendingPathExtension:@"png"];
    [_screenshotPaths addObject:path];
    return [screenshot.PNGRepresentation writeToFile:[_pathHead stringByAppendingPathComponent:path] atomically:YES];
}

- (void)testGetScreenshots {
    XCUIApplication *app = [XCUIApplication new];
    
    [app launch];
    
    XCUIElement *mainNavBar = app.navigationBars[@"One-Time Passwords"];
    
    [mainNavBar.buttons[@"Add"] tap];
    [self _writeScreenshot:app.screenshot name:@"3_menu"];
    
    if (@available(iOS 14.0, *)) {
        [app.collectionViews.buttons[@"Manual Entry"] tap];
    } else {
        [app.sheets[@"Add Code"].scrollViews.otherElements.buttons[@"Manual Entry"] tap];
    }
    
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
