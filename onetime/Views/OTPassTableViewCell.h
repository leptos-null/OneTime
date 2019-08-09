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

@interface OTPassTableViewCell : UITableViewCell

@property (strong, nonatomic) OTBag *bag;

@property (strong, nonatomic) IBOutlet UILabel *issuerLabel;
@property (strong, nonatomic) IBOutlet UILabel *accountLabel;
@property (strong, nonatomic) IBOutlet UILabel *passcodeLabel;
@property (strong, nonatomic) IBOutlet UILabel *overrideLabel;

@end
