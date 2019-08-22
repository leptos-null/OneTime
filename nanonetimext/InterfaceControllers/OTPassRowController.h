//
//  OTPassRowController.h
//  nano Extension
//
//  Created by Leptos on 8/8/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

#import "../../OneTimeKit/Models/OTBag.h"
#import "../../OneTimeKit/Models/OTPHash.h"
#import "../../OneTimeKit/Models/OTPTime.h"

@interface OTPassRowController : NSObject

@property (class, strong, nonatomic, readonly) NSString *reusableIdentifier;

@property (strong, nonatomic) OTBag *bag;

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *issuerLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *passcodeLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceTimer *validityTimer;
@property (strong, nonatomic) IBOutlet WKInterfaceButton *counterButton;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *accountLabel;

- (void)updateTimingElements;
- (void)stopTimingElements;

@end
