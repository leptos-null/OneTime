//
//  OTManualEntryViewController.h
//  onetime
//
//  Created by Leptos on 8/14/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "../../OneTimeKit/Models/OTBag.h"

@class OTManualEntryViewController;

@protocol OTManualEntryControllerDelegate <NSObject>

- (void)manualEntryController:(OTManualEntryViewController *)controller createdBag:(OTBag *)bag;

@end


typedef NS_ENUM(NSUInteger, OTManualEntryFactorType) {
    OTManualEntryFactorTypeCounter,
    OTManualEntryFactorTypeTime,
    OTManualEntryFactorTypeCaseCount
};

@interface OTManualEntryViewController : UITableViewController <UIPickerViewDataSource, UITextFieldDelegate, UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) id<OTManualEntryControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITextField *issuerField;
@property (strong, nonatomic) IBOutlet UITextField *accountField;
@property (strong, nonatomic) IBOutlet UITextField *secretField;
@property (strong, nonatomic) IBOutlet UILabel *lengthValueLabel;
@property (strong, nonatomic) IBOutlet UIStepper *lengthStepper;
@property (strong, nonatomic) IBOutlet UIPickerView *algorithmPicker;
@property (strong, nonatomic) IBOutlet UISegmentedControl *factorTypeOption;
@property (strong, nonatomic) IBOutlet UITextField *factorField;

@end
