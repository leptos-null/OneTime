//
//  OTPassTableViewCell.m
//  OneTime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPassTableViewCell.h"
#import "../Services/OTSecondKeeper.h"
#import "../../OneTimeKit/Models/OTPTime.h"
#import "../../OneTimeKit/Models/OTPHash.h"
#import "../../OneTimeKit/Services/OTBagCenter.h"

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
    
    if (@available(iOS 13.0, *)) {
        UIContextMenuInteraction *menuInteraction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self addInteraction:menuInteraction];
    } else {
        UILongPressGestureRecognizer *longTouch = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longGestureRecognizerFire:)];
        [self addGestureRecognizer:longTouch];
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
    
    self.factorIndicator.hidden = editing;
}

- (void)setBag:(OTBag *)bag {
    _bag = bag;
    
    _lastFactor = -1;
    
    NSNotificationCenter *keepCenter = OTSecondKeeper.keepCenter;
    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    [keepCenter removeObserver:self name:OTSecondKeeper.everySecondName object:nil];
    [defaultCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.issuerField.text = bag.issuer;
    self.accountField.text = bag.account;
    [self _updateFactorIndicator];
    
    if ([bag.generator isKindOfClass:[OTPTime class]]) {
        self.factorIndicator.userInteractionEnabled = NO;
        self.factorIndicator.accessibilityLabel = @"Expires in";
        self.factorIndicator.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently;
        
        SEL const updateSel = @selector(_updateFactorIndicator);
        [keepCenter addObserver:self selector:updateSel name:OTSecondKeeper.everySecondName object:nil];
        [keepCenter addObserver:self selector:updateSel name:UIApplicationWillEnterForegroundNotification object:nil];
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
        [OTBagCenter.defaultCenter updateMetadata:bag];
    }
}

- (void)_longGestureRecognizerFire:(UILongPressGestureRecognizer *)gesture API_DEPRECATED("Use context menu", ios(3.2, 13.0)) {
    if (gesture.state == UIGestureRecognizerStateBegan && !self.editing) {
        [self becomeFirstResponder];
        
        UIMenuController *menu = UIMenuController.sharedMenuController;
        [menu setTargetRect:self.passcodeLabel.frame inView:self];
        [menu setMenuVisible:YES animated:YES];
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
    [OTBagCenter.defaultCenter updateMetadata:bag];
}

// MARK: - UIResponder overrides

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [super canPerformAction:action withSender:sender]
    || (action == @selector(copy:))
    || (action == @selector(delete:));
}

- (void)copy:(id)sender {
    UIPasteboard.generalPasteboard.string = self.bag.generator.password;
}

- (void)delete:(id)sender {
    [self.actionDelegate promptDeleteBag:self.bag];
}

// MARK: - UIContextMenuInteractionDelegate

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location API_AVAILABLE(ios(13.0)) {
    // don't respond if we're editing, because most users
    //   long press on cells to enter the drag lift state
    if (self.editing) {
        return nil;
    }
    
    UIKeyCommand *copyCommand = [UIKeyCommand commandWithTitle:@"Copy Code"
                                                         image:[UIImage systemImageNamed:@"doc.on.clipboard"]
                                                        action:@selector(copy:)
                                                         input:@"c" modifierFlags:UIKeyModifierCommand
                                                  propertyList:nil];
    UIKeyCommand *deleteCommand = [UIKeyCommand commandWithTitle:@"Delete Token"
                                                           image:[UIImage systemImageNamed:@"trash"]
                                                          action:@selector(delete:)
                                                           input:@"\b" modifierFlags:0
                                                    propertyList:nil];
    deleteCommand.attributes = UIMenuElementAttributesDestructive;
    
    NSMutableArray *additionalActions = [NSMutableArray array];
    
    NSURL *bagURL = self.bag.appleURL;
    // `canOpenURL:` seems like it might be a better choice,
    // but for security reasons, I want to avoid a malicious
    // app on e.g. iOS 14 registering for the `apple-otpauth`
    // scheme and being able to obtains these secrets.
    if (@available(iOS 15.0, *)) {
        UIAction *exportAction = [UIAction actionWithTitle:@"Add to System"
                                                     image:[UIImage systemImageNamed:@"key"]
                                                identifier:nil handler:^(__kindof UIAction *action) {
            [UIApplication.sharedApplication openURL:bagURL options:@{} completionHandler:^(BOOL success) {
                NSLog(@"openURLCompletedSuccessfully: %@", success ? @"YES" : @"NO");
            }];
        }];
        [additionalActions addObject:exportAction];
    }
    
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil
                                                    actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
        return [UIMenu menuWithTitle:@"" children:@[
            [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
                copyCommand,
                deleteCommand
            ]],
            [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:additionalActions]
        ]];
    }];
}

@end
