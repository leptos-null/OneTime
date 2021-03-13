//
//  OTInterfaceController.h
//  nano OneTime Extension
//
//  Created by Leptos on 8/6/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

#import "../../OneTimeKit/Models/OTBag.h"

@interface OTInterfaceController : WKInterfaceController

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *updateLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceTable *passcodesTable;

@end
