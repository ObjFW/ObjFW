/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#ifdef HAVE_MADVISE
# include <sys/mman.h>
#else
# define madvise(addr, len, advise)
#endif

#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

#import "of_asprintf.h"
#import "unicode.h"

@implementation OFMutableString
- (void)_applyTable: (const of_unichar_t* const[])table
	   withSize: (size_t)tableSize
{
	of_unichar_t c;
	of_unichar_t *unicodeString;
	size_t unicodeLen, newLength, cLen;
	size_t i, j, d;
	char *newString;

	if (!isUTF8) {
		assert(tableSize >= 1);

		uint8_t *p = (uint8_t*)string + length;
		uint8_t t;

		while (--p >= (uint8_t*)string)
			if ((t = table[0][*p]) != 0)
				*p = t;

		return;
	}

	unicodeLen = [self length];
	unicodeString = [self allocMemoryForNItems: unicodeLen
					  withSize: sizeof(of_unichar_t)];

	i = j = 0;
	newLength = 0;

	while (i < length) {
		cLen = of_string_utf8_to_unicode(string + i, length - i, &c);

		if (cLen == 0 || c > 0x10FFFF) {
			[self freeMemory: unicodeString];
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		if (c >> 8 < tableSize) {
			of_unichar_t tc = table[c >> 8][c & 0xFF];

			if (tc)
				c = tc;
		}
		unicodeString[j++] = c;

		if (c < 0x80)
			newLength++;
		else if (c < 0x800)
			newLength += 2;
		else if (c < 0x10000)
			newLength += 3;
		else if (c < 0x110000)
			newLength += 4;
		else {
			[self freeMemory: unicodeString];
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		i += cLen;
	}

	@try {
		newString = [self allocMemoryWithSize: newLength + 1];
	} @catch (id e) {
		[self freeMemory: unicodeString];
		@throw e;
	}

	j = 0;

	for (i = 0; i < unicodeLen; i++) {
		if ((d = of_string_unicode_to_utf8(unicodeString[i],
		    newString + j)) == 0) {
			[self freeMemory: unicodeString];
			[self freeMemory: newString];
			@throw [OFInvalidEncodingException newWithClass: isa];
		}
		j += d;
	}

	assert(j == newLength);
	newString[j] = 0;
	[self freeMemory: unicodeString];

	[self freeMemory: string];
	string = newString;
	length = newLength;
}

- (void)setToCString: (const char*)string_
{
	size_t length_;

	[self freeMemory: string];

	length_ = strlen(string_);

	if (length_ >= 3 && !memcmp(string_, "\xEF\xBB\xBF", 3)) {
		string_ += 3;
		length_ -= 3;
	}

	switch (of_string_check_utf8(string_, length_)) {
	case 0:
		isUTF8 = NO;
		break;
	case 1:
		isUTF8 = YES;
		break;
	case -1:
		string = NULL;
		length = 0;
		isUTF8 = NO;

		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	length = length_;
	string = [self allocMemoryWithSize: length + 1];
	memcpy(string, string_, length + 1);
}

- (void)appendCString: (const char*)string_
{
	size_t length_ = strlen(string_);

	if (length_ >= 3 && !memcmp(string_, "\xEF\xBB\xBF", 3)) {
		string_ += 3;
		length_ -= 3;
	}

	switch (of_string_check_utf8(string_, length_)) {
	case 1:
		isUTF8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	string = [self resizeMemory: string
			     toSize: length + length_ + 1];
	memcpy(string + length, string_, length_ + 1);
	length += length_;
}

- (void)appendCString: (const char*)string_
	   withLength: (size_t)length_
{
	if (length_ >= 3 && !memcmp(string_, "\xEF\xBB\xBF", 3)) {
		string_ += 3;
		length_ -= 3;
	}

	switch (of_string_check_utf8(string_, length_)) {
	case 1:
		isUTF8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	string = [self resizeMemory: string
			     toSize: length + length_ + 1];
	memcpy(string + length, string_, length_);
	length += length_;
	string[length] = 0;
}

- (void)appendCString: (const char*)string_
	 withEncoding: (of_string_encoding_t)encoding
	       length: (size_t)length_
{
	if (encoding == OF_STRING_ENCODING_UTF_8)
		[self appendCString: string_
			 withLength: length_];
	else {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		[self appendString: [OFString stringWithCString: string_
						       encoding: encoding
							 length: length_]];
		[pool release];
	}
}

- (void)appendCStringWithoutUTF8Checking: (const char*)string_
{
	size_t len;

	len = strlen(string_);
	string = [self resizeMemory: string
			     toSize: length + len + 1];
	memcpy(string + length, string_, len + 1);
	length += len;
}

- (void)appendCStringWithoutUTF8Checking: (const char*)string_
				  length: (size_t)length_
{
	string = [self resizeMemory: string
			     toSize: length + length_ + 1];
	memcpy(string + length, string_, length_);
	length += length_;
	string[length] = 0;
}

- (void)appendString: (OFString*)string_
{
	if (string_ == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	[self appendCString: [string_ cString]];
}

- (void)appendFormat: (OFConstantString*)format, ...
{
	va_list arguments;

	va_start(arguments, format);
	[self appendFormat: format
	     withArguments: arguments];
	va_end(arguments);
}

- (void)appendFormat: (OFConstantString*)format
       withArguments: (va_list)arguments
{
	char *t;
	int len;

	if (format == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if ((len = of_vasprintf(&t, [format cString], arguments)) == -1)
		@throw [OFInvalidFormatException newWithClass: isa];

	@try {
		[self appendCString: t
			 withLength: len];
	} @finally {
		free(t);
	}
}

- (void)prependString: (OFString*)string_
{
	return [self insertString: string_
			  atIndex: 0];
}

- (void)reverse
{
	size_t i, j, len = length / 2;

	madvise(string, length, MADV_SEQUENTIAL);

	/* We reverse all bytes and restore UTF-8 later, if necessary */
	for (i = 0, j = length - 1; i < len; i++, j--) {
		string[i] ^= string[j];
		string[j] ^= string[i];
		string[i] ^= string[j];
	}

	if (!isUTF8) {
		madvise(string, length, MADV_NORMAL);
		return;
	}

	for (i = 0; i < length; i++) {
		/* ASCII */
		if (OF_LIKELY(!(string[i] & 0x80)))
			continue;

		/* A start byte can't happen first as we reversed everything */
		if (OF_UNLIKELY(string[i] & 0x40)) {
			madvise(string, length, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Next byte must not be ASCII */
		if (OF_UNLIKELY(length < i + 1 || !(string[i + 1] & 0x80))) {
			madvise(string, length, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Next byte is the start byte */
		if (OF_LIKELY(string[i + 1] & 0x40)) {
			string[i] ^= string[i + 1];
			string[i + 1] ^= string[i];
			string[i] ^= string[i + 1];

			i++;
			continue;
		}

		/* Second next byte must not be ASCII */
		if (OF_UNLIKELY(length < i + 2 || !(string[i + 2] & 0x80))) {
			madvise(string, length, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Second next byte is the start byte */
		if (OF_LIKELY(string[i + 2] & 0x40)) {
			string[i] ^= string[i + 2];
			string[i + 2] ^= string[i];
			string[i] ^= string[i + 2];

			i += 2;
			continue;
		}

		/* Third next byte must not be ASCII */
		if (OF_UNLIKELY(length < i + 3 || !(string[i + 3] & 0x80))) {
			madvise(string, length, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Third next byte is the start byte */
		if (OF_LIKELY(string[i + 3] & 0x40)) {
			string[i] ^= string[i + 3];
			string[i + 3] ^= string[i];
			string[i] ^= string[i + 3];

			string[i + 1] ^= string[i + 2];
			string[i + 2] ^= string[i + 1];
			string[i + 1] ^= string[i + 2];

			i += 3;
			continue;
		}

		/* UTF-8 does not allow more than 4 bytes per character */
		madvise(string, length, MADV_NORMAL);
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	madvise(string, length, MADV_NORMAL);
}

- (void)upper
{
	[self _applyTable: of_unicode_upper_table
		 withSize: OF_UNICODE_UPPER_TABLE_SIZE];
}

- (void)lower
{
	[self _applyTable: of_unicode_lower_table
		 withSize: OF_UNICODE_LOWER_TABLE_SIZE];
}

- (void)insertString: (OFString*)string_
	     atIndex: (size_t)index
{
	size_t newLength;

	if (isUTF8)
		index = of_string_index_to_position(string, index, length);

	if (index > length)
		@throw [OFOutOfRangeException newWithClass: isa];

	newLength = length + [string_ cStringLength];
	string = [self resizeMemory: string
			     toSize: newLength + 1];

	memmove(string + index + [string_ cStringLength], string + index,
	    length - index);
	memcpy(string + index, [string_ cString], [string_ cStringLength]);
	string[newLength] = '\0';

	length = newLength;
}

- (void)deleteCharactersFromIndex: (size_t)start
			  toIndex: (size_t)end
{
	if (isUTF8) {
		start = of_string_index_to_position(string, start, length);
		end = of_string_index_to_position(string, end, length);
	}

	if (start > end)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (end > length)
		@throw [OFOutOfRangeException newWithClass: isa];

	memmove(string + start, string + end, length - end);
	length -= end - start;
	string[length] = 0;

	@try {
		string = [self resizeMemory: string
				     toSize: length + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
		[e release];
	}
}

- (void)deleteCharactersInRange: (of_range_t)range
{
	[self deleteCharactersFromIndex: range.start
				toIndex: range.start + range.length];
}

- (void)replaceCharactersFromIndex: (size_t)start
			   toIndex: (size_t)end
			withString: (OFString*)replacement
{
	size_t newLength;

	if (isUTF8) {
		start = of_string_index_to_position(string, start, length);
		end = of_string_index_to_position(string, end, length);
	}

	if (start > end)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (end > length)
		@throw [OFOutOfRangeException newWithClass: isa];

	newLength = length - (end - start) + [replacement cStringLength];
	string = [self resizeMemory: string
			     toSize: newLength + 1];

	memmove(string + end, string + start + [replacement cStringLength],
	    length - end);
	memcpy(string + start, [replacement cString],
	    [replacement cStringLength]);
	string[newLength] = '\0';

	length = newLength;
}

- (void)replaceCharactersInRange: (of_range_t)range
		      withString: (OFString*)replacement
{
	[self replaceCharactersFromIndex: range.start
				 toIndex: range.start + range.length
			      withString: replacement];
}

- (void)replaceOccurrencesOfString: (OFString*)string_
			withString: (OFString*)replacement
{
	const char *cString = [string_ cString];
	const char *replacementCString = [replacement cString];
	size_t stringLen = [string_ cStringLength];
	size_t replacementLen = [replacement cStringLength];
	size_t i, last, newLength;
	char *newString;

	if (stringLen > length)
		return;

	newString = NULL;
	newLength = 0;

	for (i = 0, last = 0; i <= length - stringLen; i++) {
		if (memcmp(string + i, cString, stringLen))
			continue;

		@try {
			newString = [self resizeMemory: newString
						toSize: newLength + i - last +
							replacementLen + 1];
		} @catch (id e) {
			[self freeMemory: newString];
			@throw e;
		}
		memcpy(newString + newLength, string + last, i - last);
		memcpy(newString + newLength + i - last, replacementCString,
		    replacementLen);
		newLength += i - last + replacementLen;
		i += stringLen - 1;
		last = i + 1;
	}

	@try {
		newString = [self resizeMemory: newString
					toSize: newLength + length - last + 1];
	} @catch (id e) {
		[self freeMemory: newString];
		@throw e;
	}
	memcpy(newString + newLength, string + last, length - last);
	newLength += length - last;
	newString[newLength] = 0;

	[self freeMemory: string];
	string = newString;
	length = newLength;
}

- (void)deleteLeadingWhitespaces
{
	size_t i;

	for (i = 0; i < length; i++)
		if (string[i] != ' '  && string[i] != '\t' &&
		    string[i] != '\n' && string[i] != '\r')
			break;

	length -= i;
	memmove(string, string + i, length);
	string[length] = '\0';

	@try {
		string = [self resizeMemory: string
				     toSize: length + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
		[e release];
	}
}

- (void)deleteTrailingWhitespaces
{
	size_t d;
	char *p;

	d = 0;
	for (p = string + length - 1; p >= string; p--) {
		if (*p != ' ' && *p != '\t' && *p != '\n' && *p != '\r')
			break;

		*p = '\0';
		d++;
	}

	length -= d;

	@try {
		string = [self resizeMemory: string
				     toSize: length + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
		[e release];
	}
}

- (void)deleteLeadingAndTrailingWhitespaces
{
	size_t d, i;
	char *p;

	d = 0;
	for (p = string + length - 1; p >= string; p--) {
		if (*p != ' ' && *p != '\t' && *p != '\n' && *p != '\r')
			break;

		*p = '\0';
		d++;
	}

	length -= d;

	for (i = 0; i < length; i++)
		if (string[i] != ' '  && string[i] != '\t' &&
		    string[i] != '\n' && string[i] != '\r')
			break;

	length -= i;
	memmove(string, string + i, length);
	string[length] = '\0';

	@try {
		string = [self resizeMemory: string
				     toSize: length + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
		[e release];
	}
}

- copy
{
	return [[OFString alloc] initWithString: self];
}
@end
