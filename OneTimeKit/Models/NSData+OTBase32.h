/*
 * NSData+OTBase32.h
 *
 * base32 (de)coder implementation as specified by RFC4648.
 *
 * Copyright (c) 2010 Adrien Kunysz
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Originally found at http://fruli.krunch.be/~krunch/src/base32/base32.h
 */

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
