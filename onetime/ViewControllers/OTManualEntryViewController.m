//
//  OTManualEntryViewController.m
//  onetime
//
//  Created by Leptos on 8/14/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTManualEntryViewController.h"
#import "OTInfoViewController.h"

#import "../../OneTimeKit/Models/OTPTime.h"
#import "../../OneTimeKit/Models/OTPHash.h"
#import "../../OneTimeKit/Models/NSData+OTBase32.h"

@implementation OTManualEntryViewController {
    NSArray<NSString *> *_algorithms;
    
    NSString *_counterStoredValue;
    NSString *_timeStoredValue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // I'm setting this in the storyboard, but for some reason it's not working
    self.lengthStepper.value = 6;
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveFieldsToBagRequest)];
    saveButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveButton;
    
    _counterStoredValue = @"1";
    _timeStoredValue = @"30";
    [self _updateFactorFieldForSelectedSegment];
    
    _algorithms = @[
        @"SHA1",
        @"MD5",
        @"SHA256",
        @"SHA384",
        @"SHA512",
        @"SHA224"
    ];
}

- (void)saveFieldsToBagRequest {
    NSString *cleanKey = [self.secretField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData *key = [[NSData alloc] initWithBase32EncodedString:cleanKey options:NSDataBase32DecodingOptionsNone];
    CCHmacAlgorithm alg = (CCHmacAlgorithm)[self.algorithmPicker selectedRowInComponent:0];
    size_t digits = self.lengthStepper.value;
    NSString *factorComponent = self.factorField.text;
    if (key == nil || cleanKey.length == 0 || digits <= 0 || alg < 0 || factorComponent.length == 0) {
        return;
    }
    __kindof OTPBase *generator = nil;
    switch (self.factorTypeOption.selectedSegmentIndex) {
        case OTManualEntryFactorTypeCounter:
            generator = [[OTPHash alloc] initWithKey:key algorithm:alg digits:digits counter:factorComponent.integerValue];
            break;
        case OTManualEntryFactorTypeTime:
            generator = [[OTPTime alloc] initWithKey:key algorithm:alg digits:digits step:factorComponent.doubleValue];
            break;
        default: {
            NSAssert(0, @"An unknown option selected in factorTypeOption: %@", self.factorTypeOption);
        }
    }
    
    OTBag *bag = [[OTBag alloc] initWithGenerator:generator];
    bag.issuer = self.issuerField.text;
    bag.account = self.accountField.text;
    [self.delegate manualEntryController:self createdBag:bag];
}

- (IBAction)_lengthStepperDidChange:(UIStepper *)sender {
    self.lengthValueLabel.text = [NSString stringWithFormat:@"%.0f", sender.value];
}

- (NSCharacterSet *)_invertedBase32Set {
    static NSCharacterSet *ret;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = [NSCharacterSet characterSetWithCharactersInString:@""
               "QWERTYUIOPASDFGHJKLZXCVBNM"
               "qwertyuiopasdfghjklzxcvbnm"
               "234567"
               " " /* also allow ' ' for visual padding */];
        ret = ret.invertedSet;
    });
    return ret;
}

- (IBAction)_updateFactorFieldForSelectedSegment {
    UITextField *correspondingField = self.factorField;
    NSString *infoText = nil;
    switch (self.factorTypeOption.selectedSegmentIndex) {
        case OTManualEntryFactorTypeCounter: {
            infoText = @"Starting counter";
            correspondingField.keyboardType = UIKeyboardTypeNumberPad;
            correspondingField.text = _counterStoredValue;
        } break;
        case OTManualEntryFactorTypeTime: {
            infoText = @"Step seconds";
            correspondingField.keyboardType = UIKeyboardTypeDecimalPad;
            correspondingField.text = _timeStoredValue;
        } break;
            
        default:
            break;
    }
    correspondingField.placeholder = infoText;
    correspondingField.accessibilityLabel = infoText;
    if (correspondingField.isFirstResponder) {
        [correspondingField reloadInputViews];
    }
}

- (IBAction)_factorFieldTextDidChange:(UITextField *)sender {
    switch (self.factorTypeOption.selectedSegmentIndex) {
        case OTManualEntryFactorTypeCounter: {
            _counterStoredValue = sender.text;
        } break;
        case OTManualEntryFactorTypeTime: {
            _timeStoredValue = sender.text;
        } break;
            
        default:
            break;
    }
}

- (IBAction)_colorSecretTextField:(UITextField *)secretField {
    NSString *interest = secretField.text;
    BOOL couldSave = (interest.length != 0);
    
    NSMutableAttributedString *markup = [[NSMutableAttributedString alloc] initWithString:interest];
    NSCharacterSet *const badChars = [self _invertedBase32Set];
    NSDictionary *const badCharAttribs = @{
        NSBackgroundColorAttributeName : UIColor.systemPinkColor
    };
    
    NSRange range = NSMakeRange(0, interest.length);
    while (NSMaxRange(range) <= interest.length) {
        NSRange badRange = [interest rangeOfCharacterFromSet:badChars options:0 range:range];
        if (badRange.location == NSNotFound) {
            break;
        }
        couldSave = NO;
        [markup addAttributes:badCharAttribs range:badRange];
        range.location = badRange.location + badRange.length;
        range.length = interest.length - range.location;
    }
    secretField.attributedText = markup;
    self.navigationItem.rightBarButtonItem.enabled = couldSave;
}

- (void)_presentHelpButton:(UIButton *)button text:(NSString *)text {
    OTInfoViewController *info = [OTInfoViewController new];
    [info loadViewIfNeeded];
    info.textView.text = text;
    [info updatePreferredContentSizeForViewController:self];
    
    info.popoverPresentationController.sourceView = self.view;
    info.popoverPresentationController.sourceRect = [self.view convertRect:button.frame fromView:button.superview];
    [self presentViewController:info animated:YES completion:NULL];
}

// MARK: - Help text trampolines

- (IBAction)_secretHelpHit:(UIButton *)sender {
    [self _presentHelpButton:sender text:@"The secret key that you and the service share.\n"
     "If someone else had the secret, they would be able to generate one time codes too.\n"
     "The text you should enter is the base32 encoded key provided by the service.\n"
     "If the service does not provide the secret key, it is not possible to generate one time passwords."];
}

- (IBAction)_digitsHelpHit:(UIButton *)sender {
    [self _presentHelpButton:sender text:@"The length of the password that is generated.\n"
     "This must be the same length that the service is expecting. "
     "If you're not sure what the code length is, it's most likely 6."];
}

- (IBAction)_algorithmHelpHit:(UIButton *)sender {
    [self _presentHelpButton:sender text:@"The algorithm used to derive passwords from the secret.\n"
     "This must be the same algorithm that is used by the service. "
     "If you're not sure what the algorithm used is, it's most likely SHA1."];
}

- (IBAction)_factorHelpHit:(UIButton *)sender {
    [self _presentHelpButton:sender text:@"The factor type is either counter or time based.\n"
     "This must be the same factor type that is used by the service. "
     "If you're not sure what the factor type is, it's most likely time with a period of 30 seconds.\n"
     "If the service indicates it uses a counter, but doesn't say what the starting value is, it's likely 1."];
}

// MARK: - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.secretField) {
        return [textField resignFirstResponder];
    } else if (textField == self.issuerField) {
        return [self.accountField becomeFirstResponder];
    } else if (textField == self.accountField) {
        return [self.secretField becomeFirstResponder];
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if (textField == self.secretField) {
        NSRange range = [textField.text rangeOfCharacterFromSet:[self _invertedBase32Set]];
        return range.location == NSNotFound;
    }
    return YES;
}

// MARK: - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    NSParameterAssert(pickerView == self.algorithmPicker);
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSParameterAssert(pickerView == self.algorithmPicker);
    NSParameterAssert(component == 0);
    return _algorithms.count;
}

// MARK: - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSParameterAssert(pickerView == self.algorithmPicker);
    NSParameterAssert(component == 0);
    return _algorithms[row];
}

@end
