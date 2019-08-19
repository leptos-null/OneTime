//
//  OTPassTableViewCell.h
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "../../OneTimeKit/Models/OTBag.h"
#import "../../OneTimeKit/Models/OTPTime.h"
#import "../../OneTimeKit/Models/OTPHash.h"

#import "OTPadTextField.h"

@protocol OTEditingDataSource <NSObject>

- (BOOL)interfaceIsEditing;

@end

@interface OTPassTableViewCell : UITableViewCell <UITextFieldDelegate>

@property (strong, nonatomic) OTBag *bag;
@property (weak, nonatomic) id<OTEditingDataSource> editSource;

@property (strong, nonatomic) IBOutlet OTPadTextField *issuerField;
@property (strong, nonatomic) IBOutlet UILabel *passcodeLabel;
@property (strong, nonatomic) IBOutlet OTPadTextField *accountField;
// used as both a "new code" (HOTP) button, and expiry (TOTP) indicator
@property (strong, nonatomic) IBOutlet UIButton *factorIndicator;

@end
