//
//  OTPassTableViewCell.h
//  onetime
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "../../OneTimeKit/Models/OTBag.h"

#import "OTPadTextField.h"

@protocol OTEditingDataSource <NSObject>

- (BOOL)interfaceIsEditing;

@end

/// An object that can provide a UI for bag-related prompts
@protocol OTBagActionDelegate <NSObject>
/// Prompts the user to delete @c bag
- (void)promptDeleteBag:(OTBag *)bag;

@end


@interface OTPassTableViewCell : UITableViewCell <UITextFieldDelegate, UIContextMenuInteractionDelegate>

@property (class, strong, nonatomic, readonly) NSString *reusableIdentifier;

@property (strong, nonatomic) OTBag *bag;
@property (weak, nonatomic) id<OTEditingDataSource> editSource;
@property (weak, nonatomic) id<OTBagActionDelegate> actionDelegate;

@property (strong, nonatomic) IBOutlet OTPadTextField *issuerField;
@property (strong, nonatomic) IBOutlet UILabel *passcodeLabel;
@property (strong, nonatomic) IBOutlet OTPadTextField *accountField;
// used as both a "new code" (HOTP) button, and expiry (TOTP) indicator
@property (strong, nonatomic) IBOutlet UIButton *factorIndicator;

@end
