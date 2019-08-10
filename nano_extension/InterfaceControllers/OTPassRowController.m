//
//  OTPassRowController.m
//  nano Extension
//
//  Created by Leptos on 8/8/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPassRowController.h"

@implementation OTPassRowController {
    NSTimer *_validityTiming;
}

- (void)setBag:(OTBag *)bag {
    _bag = bag;
    
    [_validityTiming invalidate];
    
    self.issuerLabel.text = bag.issuer;
    self.issuerLabel.accessibilityValue = bag.issuer;
    self.accountLabel.text = bag.account;
    self.accountLabel.accessibilityValue = bag.account;
    
    [self updateTimingElements];
    BOOL isTotp = [bag.generator isKindOfClass:[OTPTime class]];
    self.validityTimer.hidden = !isTotp;
    
    if (isTotp) {
        OTPTime *totp = bag.generator;
        NSDate *date = [totp nextStepPeriodForDate:[NSDate date]];
        _validityTiming = [[NSTimer alloc] initWithFireDate:date interval:totp.step target:self
                                                   selector:@selector(updateTimingElements) userInfo:NULL repeats:YES];
        [NSRunLoop.mainRunLoop addTimer:_validityTiming forMode:NSDefaultRunLoopMode];
    }
}

- (void)updateTimingElements {
    __kindof OTPBase *generator = self.bag.generator;
    
    NSString *passcode = generator.password;
    self.passcodeLabel.text = passcode;
    self.passcodeLabel.accessibilityValue = passcode;
    
    if ([generator isKindOfClass:[OTPTime class]]) {
        // Note: WatchKit accessibility elements aren't as smart as their UIKit counterparts
        //   if you set the accessibilityLabel on a UILabel, the text property will be used for the accessibilityValue
        //   doing the same on a WKInterfaceLabel, the accessibilityValue is nil unless manually set
        //   these behaviors are reflected throughout the respective frameworks
        //   for this reason, I'm not setting the accessibilityLabel on validityTimer,
        //     and the readable countdown is provided by the system, reflecting the time on the screen
        //   the result of this is that a screen reader will only say "11 seconds" instead of "valid for 11 seconds"
        self.validityTimer.date = [generator nextStepPeriodForDate:[NSDate date]];
        [self.validityTimer start];
    }
}

- (void)stopTimingElements {
    [_validityTiming invalidate];
    [self.validityTimer stop];
}

@end
