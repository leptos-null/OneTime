//
//  OTSecError.m
//  onetime
//
//  Created by Leptos on 8/25/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import "OTSecError.h"

NSString *OTSecErrorToString(OSStatus status) {
    NSString *ret = nil;
    if (@available(iOS 11.3, watchOS 4.3, *)) {
        ret = CFBridgingRelease(SecCopyErrorMessageString(status, NULL));
    } else {
        // todo: In a localized lookup, support statuses that are likely to be returned by keychain functions
        if (ret == nil) {
            int const unixErr = status - 100000;
            if (unixErr <= sys_nerr) {
                // Apple does `UNIX[%s]`
                ret = @(sys_errlist[unixErr]);
            } else {
                ret = [NSString stringWithFormat:@"OSStatus %" __INT32_FMTd__, (int32_t)status];
            }
        }
    }
    return ret;
}

NSError *OTSecErrorToError(OSStatus status) {
    int const unixErr = status - 100000;
    if (unixErr <= sys_nerr) {
        return [NSError errorWithDomain:NSPOSIXErrorDomain code:unixErr userInfo:@{
            NSLocalizedDescriptionKey : @(sys_errlist[unixErr])
        }];
    } else {
        return [NSError errorWithDomain:@"com.apple.security" code:status userInfo:@{
            NSLocalizedDescriptionKey : OTSecErrorToString(status)
        }];
    }
}
