//
//  OTSecondKeeper.h
//  OneTime
//
//  Created by Leptos on 8/18/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTSecondKeeper : NSObject

@property (class, strong, nonatomic, readonly) NSNotificationCenter *keepCenter;
@property (class, strong, nonatomic, readonly) NSNotificationName everySecondName;

@end
