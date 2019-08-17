//
//  OTPassTableViewCell.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPassTableViewCell.h"

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
    _totpTimer = NULL;
    
    self.issuerField.text = bag.issuer;
    self.accountField.text = bag.account;
    self.passcodeLabel.text = bag.generator.password;
    
    if ([bag.generator isKindOfClass:[OTPTime class]]) {
        OTPTime *totp = bag.generator;
        __weak __typeof(self) weakself = self;
        NSDate *firstFire = [totp nextStepPeriodForDate:[NSDate date]];
        _totpTimer = [[NSTimer alloc] initWithFireDate:firstFire interval:totp.step repeats:YES block:^(NSTimer *timer) {
            weakself.passcodeLabel.text = totp.password;
        }];
        [NSRunLoop.mainRunLoop addTimer:_totpTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (!editing) {
        [self endEditing:YES];
    }
    
    CGColorRef borderColor = editing ? UIColor.systemGrayColor.CGColor : UIColor.clearColor.CGColor;
    self.issuerField.layer.borderColor = borderColor;
    self.accountField.layer.borderColor = borderColor;
}

// MARK: - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // I use to just set each of the textFields to `enabled = editing`
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
