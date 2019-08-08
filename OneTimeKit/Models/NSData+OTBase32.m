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
 * Originally found at http://fruli.krunch.be/~krunch/src/base32/base32.c
 */

#import "NSData+OTBase32.h"

/**
 * Returns the length of the output buffer required to encode len bytes of
 * data into base32. This is a macro to allow users to define buffer size at
 * compilation time.
 */
#define BASE32_LEN(len) (((len) / 5) * 8 + ((len) % 5 ? 8 : 0))

/**
 * Returns the length of the output buffer required to decode a base32 string
 * of len characters. Please note that len must be a multiple of 8 as per
 * definition of a base32 string. This is a macro to allow users to define
 * buffer size at compilation time.
 */
#define UNBASE32_LEN(len) (((len) / 8) * 5)

/*
 * Let this be a sequence of plain data before encoding:
 *
 *  01234567 01234567 01234567 01234567 01234567
 * +--------+--------+--------+--------+--------+
 * |< 0 >< 1| >< 2 ><|.3 >< 4.|>< 5 ><.|6 >< 7 >|
 * +--------+--------+--------+--------+--------+
 *
 * There are 5 octets of 8 bits each in each sequence.
 * There are 8 blocks of 5 bits each in each sequence.
 *
 * You probably want to refer to that graph when reading the algorithms in this
 * file. We use "octet" instead of "byte" intentionnaly as we really work with
 * 8 bits quantities. This implementation will probably not work properly on
 * systems that don't have exactly 8 bits per (unsigned) char.
 */
@implementation NSData (OTBase32)

/**
 * Convert a 5 bits value into a base32 character.
 * Only the 5 least significant bits are used.
 * https://tools.ietf.org/html/rfc3548#section-5
 */
static char OTBase32_encode_char(uint8_t c) {
    // static const char base32[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    static const char base32[] = "abcdefghijklmnopqrstuvwxyz234567";
    return base32[c & 0x1f]; // 0001 1111
}

/**
 * Decode given character into a 5 bits value.
 * Returns @c -1 if the argument given was an invalid base32 character
 * or a padding character.
 */
static int OTBase32_decode_char(char c) {
    int retval = -1;
    
    if (c >= 'A' && c <= 'Z') {
        retval = c - 'A';
    }
    if (c >= 'a' && c <= 'z') {
        retval = c - 'a';
    }
    if (c >= '2' && c <= '7') {
        retval = c - '2' + 26;
    }
    assert((retval == -1) || ((retval & 0x1F) == retval));
    
    return retval;
}

/**
 * @brief Index of the octet in which the @c block starts
 * @discussion Given a block id between 0 and 7 inclusive, this will return the
 * index of the octet in which this block starts. For example, given 3 it will
 * return 1 because block 3 starts in octet 1:
 * @code
 * +--------+--------+
 * | ......<|.3 >....|
 * +--------+--------+
 *  octet 1 | octet 2
 *  @endcode
 */
static int __pure2 OTBase32_get_octet(int block) {
    assert(block >= 0 && block < 8);
    return (block * 5) / 8;
}

/**
 * @brief Count of bits to drop from the end of the octet for @c block id
 * @discussion Given a block id between 0 and 7 inclusive, this will return how many bits
 * we can drop at the end of the octet in which this block starts.
 * For example, given block 0 it will return 3 because there are 3 bits
 * we don't care about at the end:
 * @code
 *  +--------+-
 *  |< 0 >...|
 *  +--------+-
 * @endcode
 * Given block 1, it will return -2 because there
 * are actually two bits missing to have a complete block:
 * @code
 *  +--------+-
 *  |.....< 1|..
 *  +--------+-
 *  @endcode
 */
static int __pure2 OTBase32_get_offset(int block) {
    assert(block >= 0 && block < 8);
    return (8 - 5 - (5 * block) % 8);
}

/**
 * Like `b >> offset` but it will do the right thing with negative offset.
 * We need this as bitwise shifting by a negative offset is undefined
 * behavior.
 */
static uint8_t __pure2 OTBase32_shift_right(uint8_t byte, char offset) {
    if (offset >= 0) {
        return byte >> offset;
    } else {
        return byte << -offset;
    }
}
/**
 * Like `b << offset` but it will do the right thing with negative offset.
 * We need this as bitwise shifting by a negative offset is undefined
 * behavior.
 */
static uint8_t __pure2 OTBase32_shift_left(uint8_t byte, char offset) {
    if (offset >= 0) {
        return byte << offset;
    } else {
        return byte >> -offset;
    }
}

/**
 * Encode a sequence. A sequence is no longer than 5 octets by definition.
 * Thus passing a length greater than 5 to this function is an error. Encoding
 * sequences shorter than 5 octets is supported and padding will be added to the
 * output as per the specification.
 */
static void OTBase32_encode_sequence(const uint8_t *plain, size_t len, char *coded, NSDataBase32EncodingOptions options) {
    assert(CHAR_BIT == 8); // not sure this would work otherwise
    assert(len >= 0 && len <= 5);
    
    for (unsigned block = 0; block < 8; block++) {
        int octet = OTBase32_get_octet(block); // figure out which octet this block starts in
        int junk = OTBase32_get_offset(block); // how many bits do we drop from this octet?
        
        if (octet >= len) { // we hit the end of the buffer
            if ((options & NSDataBase32EncodingOptionsNoPad) == 0) {
                memset(&coded[block], '=', 8 - block);
            }
            return;
        }
        
        uint8_t c = OTBase32_shift_right(plain[octet], junk); // first part
        if (junk < 0        /* is there a second part? */ &&
            octet < len - 1 /* is there still something to read? */) {
            c |= OTBase32_shift_right(plain[octet + 1], 8 + junk);
        }
        coded[block] = OTBase32_encode_char(c);
    }
}

static int OTBase32_decode_sequence(const char *coded, uint8_t *plain, NSDataBase32DecodingOptions options) {
    assert(CHAR_BIT == 8);
    assert(coded && plain);
    
    plain[0] = 0;
    for (unsigned block = 0; block < 8; block++) {
        int offset = OTBase32_get_offset(block);
        int octet = OTBase32_get_octet(block);
        
        int c = OTBase32_decode_char(coded[block]);
        if (c < 0) { // invalid char
            // not sure if this is implemented correctly
            if (options & NSDataBase32DecodingOptionsIgnoreUnknownCharacters) {
                continue;
            } else {
                return octet;
            }
        }
        
        plain[octet] |= OTBase32_shift_left(c, offset);
        if (offset < 0) { // does this block overflows to next octet?
            assert(octet < 4);
            plain[octet + 1] = OTBase32_shift_left(c, 8 + offset);
        }
    }
    return 5;
}

- (instancetype)initWithBase32EncodedString:(NSString *)base32String options:(NSDataBase32DecodingOptions)options {
    return [self initWithBase32EncodedData:[base32String dataUsingEncoding:NSUTF8StringEncoding] options:options];
}

- (NSString *)base32EncodedStringWithOptions:(NSDataBase32EncodingOptions)options {
    return [[NSString alloc] initWithData:[self base32EncodedDataWithOptions:options] encoding:NSASCIIStringEncoding];
}

- (instancetype)initWithBase32EncodedData:(NSData *)base32Data options:(NSDataBase32DecodingOptions)options {
    NSMutableData *ret = [NSMutableData dataWithLength:UNBASE32_LEN(base32Data.length)];
    const char *coded = base32Data.bytes;
    uint8_t *plain = ret.mutableBytes;
    
    size_t written = 0;
    for (size_t i = 0, j = 0; i < base32Data.length; i += 8, j += 5) {
        int n = OTBase32_decode_sequence(&coded[i], &plain[j], options);
        written += n;
        if (n < 5) {
            break;
        }
    }
    ret.length = written;
    return [ret copy];
}

- (NSData *)base32EncodedDataWithOptions:(NSDataBase32EncodingOptions)options {
    size_t const len = self.length;
    NSMutableData *ret = [NSMutableData dataWithLength:BASE32_LEN(len)];
    
    const uint8_t *plain = self.bytes;
    char *coded = ret.mutableBytes;
    for (size_t i = 0, j = 0; i < len; i += 5, j += 8) {
        OTBase32_encode_sequence(&plain[i], MIN(len - i, 5), &coded[j], options);
    }
    return [ret copy];
}

@end
