//
//  NSData+OTBase32.h
//  onetime
//
//  Created by Leptos on 8/7/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, NSDataBase32EncodingOptions) {
    NSDataBase32EncodingOptionsNone = 0,
    NSDataBase32EncodingOptionsNoPad = 1 << 0,
    NSDataBase32EncodingOptionsUppercase = 1 << 1,
};

typedef NS_OPTIONS(NSInteger, NSDataBase32DecodingOptions) {
    NSDataBase32DecodingOptionsNone = 0,
    NSDataBase32DecodingOptionsIgnoreUnknownCharacters = 1 << 0,
};

@interface NSData (OTBase32)

// Create an NSData from a Base-32 encoded NSString using the given options. By default, returns nil when the input is not recognized as valid Base-32.
- (instancetype)initWithBase32EncodedString:(NSString *)base32String options:(NSDataBase32DecodingOptions)options;

// Create a Base-32 encoded NSString from the receiver's contents using the given options.
- (NSString *)base32EncodedStringWithOptions:(NSDataBase32EncodingOptions)options;

// Create an NSData from a Base-32, UTF-8 encoded NSData. By default, returns nil when the input is not recognized as valid Base-32.
- (instancetype)initWithBase32EncodedData:(NSData *)base32Data options:(NSDataBase32DecodingOptions)options;

// Create a Base-32, UTF-8 encoded NSData from the receiver's contents using the given options.
- (NSData *)base32EncodedDataWithOptions:(NSDataBase32EncodingOptions)options;

@end
