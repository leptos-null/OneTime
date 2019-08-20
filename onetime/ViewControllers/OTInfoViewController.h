//
//  OTInfoViewController.h
//  onetime
//
//  Created by Leptos on 8/20/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTInfoViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextView *textView;

- (void)updatePreferredContentSizeForMaxSize:(CGSize)maxSize;

@end
