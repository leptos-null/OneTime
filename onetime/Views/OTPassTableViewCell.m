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
    uint64_t _lastFactor;
}

+ (NSString *)reusableIdentifier {
    return @"PassCell";
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
    
    UILongPressGestureRecognizer *longTouch = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longGestureRecognizerFire:)];
    [self addGestureRecognizer:longTouch];
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

- (void)setBag:(OTBag *)bag {
    _bag = bag;
    
    _lastFactor = -1;
    [OTSecondKeeper.keepCenter removeObserver:self name:OTSecondKeeper.everySecondName object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.issuerField.text = bag.issuer;
    self.accountField.text = bag.account;
    [self _updateFactorIndicator];
    
    if ([bag.generator isKindOfClass:[OTPTime class]]) {
        self.factorIndicator.userInteractionEnabled = NO;
        self.factorIndicator.accessibilityLabel = @"Expires in";
        self.factorIndicator.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently;
        
        [OTSecondKeeper.keepCenter addObserver:self selector:@selector(_updateFactorIndicator) name:OTSecondKeeper.everySecondName object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_updateFactorIndicator) name:UIApplicationWillEnterForegroundNotification object:nil];
    } else {
        self.factorIndicator.userInteractionEnabled = YES;
        self.factorIndicator.accessibilityLabel = @"New code";
        self.factorIndicator.accessibilityTraits = UIAccessibilityTraitButton;
    }
}

- (NSString *)_displayableStringForSeconds:(NSTimeInterval)seconds {
    static NSNumberFormatter *numberFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        numberFormatter = [NSNumberFormatter new];
        numberFormatter.locale = NSLocale.autoupdatingCurrentLocale;
        numberFormatter.roundingMode = NSNumberFormatterRoundDown;
        numberFormatter.minimumIntegerDigits = 2;
        numberFormatter.maximumFractionDigits = 0;
    });
    
    NSTimeInterval const secsPerMin = 60;
    double minutes = floor(seconds / secsPerMin);
    return [NSString stringWithFormat:@"%@:%@",
            [numberFormatter stringFromNumber:@(minutes)],
            [numberFormatter stringFromNumber:@(seconds - (minutes * secsPerMin))]];
}

- (NSString *)_readableStringForSeconds:(NSTimeInterval)seconds {
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
    return [timeFormatter stringFromMeasurement:measure];
}

- (void)_updateFactorIndicator {
    __kindof OTPBase *generator = self.bag.generator;
    uint64_t currentFactor = generator.factor;
    if (_lastFactor != currentFactor) {
        self.passcodeLabel.text = [generator passwordForFactor:currentFactor];
        _lastFactor = currentFactor;
    }
    
    if ([generator isKindOfClass:[OTPTime class]]) {
        OTPTime *totp = generator;
        NSDate *now = [NSDate date];
        NSDate *nextStep = [totp nextStepPeriodForDate:now];
        NSTimeInterval seconds = [nextStep timeIntervalSinceDate:now];
        
        [self.factorIndicator setTitle:[self _displayableStringForSeconds:seconds] forState:UIControlStateNormal];
        [self.factorIndicator setImage:nil forState:UIControlStateNormal];
        self.factorIndicator.accessibilityValue = [self _readableStringForSeconds:seconds];
    } else {
        UIImage *image;
        UITraitCollection *traitCollection = self.traitCollection;
        // > Clocks still turn clockwise for RTL languages.
        // > The refresh icon shows time moving forward;
        // > the direction is clockwise. The icon is not mirrored.
        //  - https://material.io/design/usability/bidirectionality.html#mirroring-elements
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"arrow.clockwise" compatibleWithTraitCollection:traitCollection];
        } else {
            unichar symbol = 0x21bb;
            NSString *clockwiseCircle = [NSString stringWithCharacters:&symbol length:1];
            UIFont *weightRef = [UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:traitCollection];
            UIFont *sizeRef = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2 compatibleWithTraitCollection:traitCollection];
            NSAttributedString *drawReady = [[NSAttributedString alloc] initWithString:clockwiseCircle attributes:@{
                NSFontAttributeName : [weightRef fontWithSize:sizeRef.pointSize]
            }];
            UIGraphicsBeginImageContextWithOptions([drawReady size], NO, 0);
            [drawReady drawAtPoint:CGPointZero];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        if (image.renderingMode != UIImageRenderingModeAlwaysTemplate) {
            image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        [self.factorIndicator setImage:image forState:UIControlStateNormal];
        [self.factorIndicator setTitle:nil forState:UIControlStateNormal];
        self.factorIndicator.accessibilityValue = nil;
    }
}

- (IBAction)_didTapFactorIndicator:(UIButton *)button {
    OTBag *bag = self.bag;
    if ([bag.generator isKindOfClass:[OTPHash class]]) {
        OTPHash *hotp = bag.generator;
        [hotp incrementCounter];
        self.passcodeLabel.text = hotp.password;
        OSStatus syncStatus = [bag syncToKeychain];
        if (syncStatus != errSecSuccess) {
            NSString *errorStr = OTSecErrorToString(syncStatus);
            NSLog(@"syncToKeychain: %@ (%" __INT32_FMTd__ ")", errorStr, syncStatus);
            NSString *message = [@"Failed to update token counter in keychain: " stringByAppendingString:errorStr];
            [self.messageSurfacer surfaceUserMessage:message viewHint:self dismissAfter:0];
        }
    }
}

- (void)_longGestureRecognizerFire:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan && !self.editing) {
        [self becomeFirstResponder];
        
        UIMenuController *menu = UIMenuController.sharedMenuController;
        UIView *showView = self;
        CGRect showRect = self.passcodeLabel.frame;
        if (@available(iOS 13.0, *)) {
            [menu showMenuFromView:showView rect:showRect];
        } else {
            [menu setTargetRect:showRect inView:showView];
            [menu setMenuVisible:YES animated:YES];
        }
    }
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
    OTBag *bag = self.bag;
    if (textField == self.issuerField) {
        if ([textField.text isEqualToString:bag.issuer]) {
            return;
        }
        bag.issuer = textField.text;
    } else if (textField == self.accountField) {
        if ([textField.text isEqualToString:bag.account]) {
            return;
        }
        bag.account = textField.text;
    } else {
        return;
    }
    OSStatus syncStatus = [bag syncToKeychain];
    if (syncStatus != errSecSuccess) {
        NSString *errorStr = OTSecErrorToString(syncStatus);
        NSLog(@"syncToKeychain: %@ (%" __INT32_FMTd__ ")", errorStr, syncStatus);
        NSString *message = [@"Failed to update token metadata in keychain: " stringByAppendingString:errorStr];
        [self.messageSurfacer surfaceUserMessage:message viewHint:textField dismissAfter:0];
    }
}

// MARK: - UIResponder overrides

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [super canPerformAction:action withSender:sender]
    || (action == @selector(copy:));
}

- (void)copy:(id)sender {
    UIPasteboard.generalPasteboard.string = self.passcodeLabel.text;
}

@end
