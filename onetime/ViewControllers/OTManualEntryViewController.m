//
//  OTManualEntryViewController.m
//  onetime
//
//  Created by Leptos on 8/14/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTManualEntryViewController.h"

#import "../../OneTimeKit/Models/OTPTime.h"
#import "../../OneTimeKit/Models/OTPHash.h"
#import "../../OneTimeKit/Models/NSData+OTBase32.h"

@implementation OTManualEntryViewController {
    NSArray<NSString *> *_algorithms;
}
// TODO: Provide help text for sections that are less commonly used (e.g. code length, algorithm)
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // I'm setting this in the storyboard, but for some reason it's not working
    self.lengthStepper.value = 6;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveFieldsToBagRequest)];
    
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
    if (key == nil || cleanKey.length == 0 || digits <= 0 || alg < 0) {
        return;
    }
    
    // currently no options for step and counter are being provided (TODO?)
    __kindof OTPBase *generator = nil;
    switch (self.factorTypeOption.selectedSegmentIndex) {
        case OTManualEntryFactorTypeCounter:
            generator = [[OTPHash alloc] initWithKey:key algorithm:alg digits:digits counter:OTPHash.defaultCounter];
            break;
        case OTManualEntryFactorTypeTime:
            generator = [[OTPTime alloc] initWithKey:key algorithm:alg digits:digits step:OTPTime.defaultStep];
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

- (IBAction)_colorSecretTextField:(UITextField *)secretField {
    NSString *interest = secretField.text;
    
    NSMutableAttributedString *markup = [[NSMutableAttributedString alloc] initWithString:interest];
    NSCharacterSet *const badChars = [self _invertedBase32Set];
    NSDictionary *const badCharAttribs = @{
        NSBackgroundColorAttributeName : [UIColor systemPinkColor]
    };
    
    NSRange range = NSMakeRange(0, interest.length);
    while (NSMaxRange(range) <= interest.length) {
        NSRange badRange = [interest rangeOfCharacterFromSet:badChars options:0 range:range];
        if (badRange.location == NSNotFound) {
            break;
        }
        [markup addAttributes:badCharAttribs range:badRange];
        range.location = badRange.location + badRange.length;
        range.length = interest.length - range.location;
    }
    secretField.attributedText = markup;
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

// currently, I like the idea of highlighting invalid characters instead of just blocking them
// - (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
//     if (textField == self.secretField && string.length) {
//         NSRange range = [string rangeOfCharacterFromSet:[self _invertedBase32Set]];
//         return range.location == NSNotFound;
//     }
//     return YES;
// }

// MARK: - UITableViewDelegate

// a bug in the interface builder renderer is preventing some cells to be marked automatic in the storyboard
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
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
