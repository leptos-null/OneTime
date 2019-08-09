//
//  OTPassTableViewCell.m
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTPassTableViewCell.h"

@implementation OTPassTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.issuerLabel.accessibilityLabel = @"Issuer";
    self.accountLabel.accessibilityLabel = @"Account";
    self.passcodeLabel.accessibilityLabel = @"Passcode";
    self.overrideLabel.accessibilityLabel = @"Override";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setBag:(OTBag *)bag {
    _bag = bag;
    
    self.issuerLabel.text = bag.issuer;
    self.accountLabel.text = bag.account;
    self.passcodeLabel.text = bag.generator.password;
    // TODO: Where should override information be kept?
    self.overrideLabel.text = @"Default";
}

@end
