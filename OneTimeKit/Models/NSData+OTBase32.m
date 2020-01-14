/*
 *  NSData+OTBase32.m
 *
 *  Modified from GTMStringEncoding.m
 *
 *  Copyright 2009 Google Inc.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may not
 *  use this file except in compliance with the License.  You may obtain a copy
 *  of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 */

#import "NSData+OTBase32.h"

@implementation NSData (OTBase32)

#define OTBase32_fiveBitMask 0x1f /* 0001 1111 */
#define OTBase32_AlphabetaLength 26 /* len(['a', ... , 'z']) */

/**
 * Convert a 5 bits value into a base32 character.
 * Only the 5 least significant bits are used.
 * https://tools.ietf.org/html/rfc3548#section-5
 */
static char __pure2 OTBase32_encode_char(uint8_t c, BOOL uppercase) {
    c &= OTBase32_fiveBitMask;
    char retval = 0;
    if (c < OTBase32_AlphabetaLength) {
        if (uppercase) {
            retval = c + 'A';
        } else {
            retval = c + 'a';
        }
    } else {
        retval = c + '2' - OTBase32_AlphabetaLength;
    }
    
    return retval;
}
/**
 * Decode given character into a 5 bits value.
 * Returns @c -1 if the argument given was an invalid
 * base32 character or a padding character.
 */
static uint8_t __pure2 OTBase32_decode_char(char c) {
    uint8_t retval = -1;
    if (c >= '2' && c <= '7') {
        retval = c - '2' + OTBase32_AlphabetaLength;
    } else if (c >= 'A' && c <= 'Z') {
        retval = c - 'A';
    } else if (c >= 'a' && c <= 'z') {
        retval = c - 'a';
    }
    return retval;
}

- (instancetype)initWithBase32EncodedString:(NSString *)base32String options:(NSDataBase32DecodingOptions)options {
    return [self initWithBase32EncodedData:[base32String dataUsingEncoding:NSASCIIStringEncoding] options:options];
}

- (NSString *)base32EncodedStringWithOptions:(NSDataBase32EncodingOptions)options {
    return [[NSString alloc] initWithData:[self base32EncodedDataWithOptions:options] encoding:NSASCIIStringEncoding];
}

- (instancetype)initWithBase32EncodedData:(NSData *)base32Data options:(NSDataBase32DecodingOptions)options {
    char const *coded = base32Data.bytes;
    if (!coded) {
        return nil;
    }
    NSUInteger base32Length = base32Data.length;
    const char *padStart = memchr(coded, '=', base32Length);
    // not clear how to deal with padding characters if `IgnoreUnknownCharacters` is set.
    // should the padding characters only be searched for within the last octet?
    if (padStart) {
        base32Length = padStart - coded;
    }
    
    NSUInteger const shift = 5;
    
    NSMutableData *data = [NSMutableData dataWithLength:(base32Length * shift / 8)];
    uint8_t *const plain = data.mutableBytes;
    size_t written = 0;
    
    uint32_t buffer = 0;
    unsigned bitsLeft = 0;
    for (NSUInteger i = 0; i < base32Length; i++) {
        uint8_t val = OTBase32_decode_char(coded[i]);
        if (val > OTBase32_fiveBitMask) {
            if (options & NSDataBase32DecodingOptionsIgnoreUnknownCharacters) {
                continue;
            }
            return nil;
        }
        buffer <<= shift;
        buffer |= val;
        bitsLeft += shift;
        if (bitsLeft >= 8) {
            plain[written++] = (uint8_t)(buffer >> (bitsLeft - 8));
            bitsLeft -= 8;
        }
    }
    
    if (bitsLeft && (buffer & ((1 << bitsLeft) - 1))) {
        return nil;
    }
    data.length = written;
    return [self initWithData:data];
}

- (NSData *)base32EncodedDataWithOptions:(NSDataBase32EncodingOptions)options {
    size_t const len = self.length;
    if (len <= 0) {
        return [NSData dataWithBytes:NULL length:0];
    }
    
    uint8_t const *plain = self.bytes;
    NSUInteger read = 0;
    
    NSUInteger const padLength = 8;
    NSUInteger const shift = 5;

    NSUInteger outLen = (len * 8 + shift - 1) / shift;
    if ((options & NSDataBase32EncodingOptionsNoPad) == 0) {
        outLen = ((outLen + padLength - 1) / padLength) * padLength;
    }
    
    uint8_t *coded = malloc(outLen);
    size_t written = 0;
    
    uint32_t buffer = plain[read++];
    int bitsLeft = 8;
    while (bitsLeft > 0 || read < len) {
        if (bitsLeft < shift) {
            if (read < len) {
                buffer <<= 8;
                buffer |= (plain[read++] & 0xff);
                bitsLeft += 8;
            } else {
                int pad = shift - bitsLeft;
                buffer <<= pad;
                bitsLeft += pad;
            }
        }
        int idx = (buffer >> (bitsLeft - shift)) & 0x1f;
        bitsLeft -= shift;
        coded[written++] = OTBase32_encode_char(idx, options & NSDataBase32EncodingOptionsUppercase);
    }
    
    if ((options & NSDataBase32EncodingOptionsNoPad) == 0) {
        while (written < outLen) {
            coded[written++] = '=';
        }
    }
    assert(written <= outLen);
    return [NSData dataWithBytesNoCopy:coded length:written freeWhenDone:YES];
}

@end
