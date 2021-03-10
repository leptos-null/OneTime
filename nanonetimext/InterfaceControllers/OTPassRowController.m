//
//  OTPassRowController.m
//  nano OneTime Extension
//
//  Created by Leptos on 8/8/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPassRowController.h"

#import "../../OneTimeKit/Services/OTBagCenter.h"

@implementation OTPassRowController {
    NSTimer *_validityTiming;
}

+ (NSString *)reusableIdentifier {
    return @"PassCell";
}

- (void)setBag:(OTBag *)bag {
    _bag = bag;
    
    self.issuerLabel.text = bag.issuer;
    self.issuerLabel.accessibilityValue = bag.issuer;
    self.accountLabel.text = bag.account;
    self.accountLabel.accessibilityValue = bag.account;
    
    [self updateTimingElements];
    
    BOOL isTotp = [bag.generator isKindOfClass:[OTPTime class]];
    self.validityTimer.hidden = !isTotp;
    self.counterButton.hidden = isTotp;
}

- (void)updateTimingElements {
    __kindof OTPBase *generator = self.bag.generator;
    
    NSString *passcode = generator.password;
    self.passcodeLabel.text = passcode;
    self.passcodeLabel.accessibilityValue = passcode;
    
    [_validityTiming invalidate];
    
    if ([generator isKindOfClass:[OTPTime class]]) {
        NSDate *fireDate = [generator nextStepPeriodForDate:[NSDate date]];
        // Note: WatchKit accessibility elements aren't as smart as their UIKit counterparts
        //   if you set the accessibilityLabel on a UILabel, the text property will be used for the accessibilityValue
        //   doing the same on a WKInterfaceLabel, the accessibilityValue is nil unless manually set
        //   these behaviors are reflected throughout the respective frameworks
        //   for this reason, I'm not setting the accessibilityLabel on validityTimer,
        //     and the readable countdown is provided by the system, reflecting the time on the screen
        //   the result of this is that a screen reader will only say "11 seconds" instead of "valid for 11 seconds"
        self.validityTimer.date = fireDate;
        [self.validityTimer start];
        
        NSTimer *validityTiming = [[NSTimer alloc] initWithFireDate:fireDate interval:0 target:self selector:_cmd userInfo:nil repeats:NO];
        [NSRunLoop.mainRunLoop addTimer:validityTiming forMode:NSDefaultRunLoopMode];
        _validityTiming = validityTiming;
    }
}

- (void)stopTimingElements {
    [_validityTiming invalidate];
    [self.validityTimer stop];
}

- (IBAction)counterButtonHit {
    OTBag *bag = self.bag;
    if ([bag.generator isKindOfClass:[OTPHash class]]) {
        OTPHash *hotp = bag.generator;
        [hotp incrementCounter];
        [self updateTimingElements];
        [OTBagCenter.defaultCenter updateMetadata:bag];
    }
}

@end
