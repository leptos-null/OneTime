//
//  OTPassTableViewCell.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPassTableViewCell.h"
#import "../Services/OTSecondKeeper.h"

@implementation OTPassTableViewCell {
    NSTimer *_totpTimer;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    NSArray<OTPadTextField *> *borderFields = @[ self.issuerField, self.accountField ];
    for (OTPadTextField *borderField in borderFields) {
        borderField.contentInsets = UIEdgeInsetsMake(6, 6, 6, 6);
        CALayer *borderFieldLayer = borderField.layer;
        borderFieldLayer.borderWidth = 1;
        borderFieldLayer.cornerRadius = 6;
        borderFieldLayer.borderColor = UIColor.clearColor.CGColor;
    }
}

- (void)setBag:(OTBag *)bag {
    _bag = bag;
    
    [_totpTimer invalidate];
    [OTSecondKeeper.keepCenter removeObserver:self name:OTSecondKeeper.everySecondName object:nil];
    
    self.issuerField.text = bag.issuer;
    self.accountField.text = bag.account;
    [self _updatePasscodeLabel];
    [self _updateFactorIndicator];
    
    if ([bag.generator isKindOfClass:[OTPTime class]]) {
        self.factorIndicator.userInteractionEnabled = NO;
        self.factorIndicator.accessibilityLabel = @"Expires in";
        self.factorIndicator.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently;
        
        OTPTime *totp = bag.generator;
        NSDate *firstFire = [totp nextStepPeriodForDate:[NSDate date]];
        _totpTimer = [[NSTimer alloc] initWithFireDate:firstFire interval:totp.step target:self selector:@selector(_updatePasscodeLabel) userInfo:nil repeats:YES];
        [NSRunLoop.mainRunLoop addTimer:_totpTimer forMode:NSDefaultRunLoopMode];
        
        [OTSecondKeeper.keepCenter addObserver:self selector:@selector(_updateFactorIndicator) name:OTSecondKeeper.everySecondName object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_updatePasscodeLabel) name:UIApplicationWillEnterForegroundNotification object:nil];
    } else {
        self.factorIndicator.userInteractionEnabled = YES;
        self.factorIndicator.accessibilityLabel = nil; // use default
        self.factorIndicator.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitStaticText;
    }
}

- (void)_updatePasscodeLabel {
    self.passcodeLabel.text = self.bag.generator.password;
}

- (void)_updateFactorIndicator {
    __kindof OTPBase *generator = self.bag.generator;
    if ([generator isKindOfClass:[OTPTime class]]) {
        OTPTime *totp = generator;
        NSDate *now = [NSDate date];
        NSDate *nextStep = [totp nextStepPeriodForDate:now];
        NSTimeInterval seconds = [nextStep timeIntervalSinceDate:now];
        
        NSTimeInterval const secsPerMin = 60;
        double minutes = floor(seconds / secsPerMin);
        NSString *indicator = [NSString stringWithFormat:@"%02.0f:%02.0f", minutes, seconds - (minutes * secsPerMin)];
        [self.factorIndicator setTitle:indicator forState:UIControlStateNormal];
        
        static NSMeasurementFormatter *timeFormatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            timeFormatter = [NSMeasurementFormatter new];
            timeFormatter.locale = NSLocale.autoupdatingCurrentLocale;
            timeFormatter.unitOptions = NSMeasurementFormatterUnitOptionsNaturalScale;
            timeFormatter.unitStyle = NSFormattingUnitStyleLong;
            timeFormatter.numberFormatter.maximumFractionDigits = 0;
        });
        NSMeasurement *measure = [[NSMeasurement alloc] initWithDoubleValue:seconds unit:[NSUnitDuration seconds]];
        self.factorIndicator.accessibilityValue = [timeFormatter stringFromMeasurement:measure];
        
        UIColor *textColor = nil;
        if (@available(iOS 13.0, *)) {
            textColor = UIColor.labelColor;
        } else {
            textColor = UIColor.darkTextColor;
        }
        [self.factorIndicator setTitleColor:textColor forState:UIControlStateNormal];
    } else {
        [self.factorIndicator setTitle:@"New Code" forState:UIControlStateNormal];
        
        UIColor *color = self.factorIndicator.tintColor;
        [self.factorIndicator setTitleColor:color forState:UIControlStateNormal];
        
        CGFloat hue, saturation, brightness, alpha;
        [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
        color = [UIColor colorWithHue:hue saturation:saturation brightness:(brightness * 0.72) alpha:alpha];
        [self.factorIndicator setTitleColor:color forState:UIControlStateHighlighted];
    }
}

- (IBAction)_didTapFactorIndicator:(UIButton *)button {
    OTBag *bag = self.bag;
    if ([bag.generator isKindOfClass:[OTPHash class]]) {
        OTPHash *hotp = bag.generator;
        [hotp incrementCounter];
        self.passcodeLabel.text = hotp.password;
        [bag syncToKeychain];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (!editing) {
        [self endEditing:YES];
    }
    
    editing = self.editSource.interfaceIsEditing;
    CGColorRef borderColor = editing ? UIColor.systemGrayColor.CGColor : UIColor.clearColor.CGColor;
    self.issuerField.layer.borderColor = borderColor;
    self.accountField.layer.borderColor = borderColor;
}

// MARK: - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // previously, I set each of the textFields to `enabled = editing`
    //   but that caused VoiceOver to read "dimmed" which could be confusing
    return self.editing;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [textField resignFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.issuerField) {
        if ([textField.text isEqualToString:self.bag.issuer]) {
            return;
        }
        self.bag.issuer = textField.text;
    } else if (textField == self.accountField) {
        if ([textField.text isEqualToString:self.bag.account]) {
            return;
        }
        self.bag.account = textField.text;
    } else {
        return;
    }
    [self.bag syncToKeychain];
}

@end
