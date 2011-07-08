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

	if (!s->isUTF8) {
		assert(tableSize >= 1);

		uint8_t *p = (uint8_t*)s->string + s->length;
		uint8_t t;

		while (--p >= (uint8_t*)s->string)
			if ((t = table[0][*p]) != 0)
				*p = t;

		return;
	}

	unicodeLen = [self length];
	unicodeString = [self allocMemoryForNItems: unicodeLen
					  withSize: sizeof(of_unichar_t)];

	i = j = 0;
	newLength = 0;

	while (i < s->length) {
		cLen = of_string_utf8_to_unicode(s->string + i, s->length - i,
		    &c);

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

	[self freeMemory: s->string];
	s->string = newString;
	s->length = newLength;
}

- (void)setToCString: (const char*)string
{
	size_t length = strlen(string);

	if (length >= 3 && !memcmp(string, "\xEF\xBB\xBF", 3)) {
		string += 3;
		length -= 3;
	}

	switch (of_string_check_utf8(string, length)) {
	case 0:
		s->isUTF8 = NO;
		break;
	case 1:
		s->isUTF8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	[self freeMemory: s->string];

	s->length = length;
	s->string = [self allocMemoryWithSize: length + 1];
	memcpy(s->string, string, length + 1);
}

- (void)appendCString: (const char*)string
{
	size_t length = strlen(string);

	if (length >= 3 && !memcmp(string, "\xEF\xBB\xBF", 3)) {
		string += 3;
		length -= 3;
	}

	switch (of_string_check_utf8(string, length)) {
	case 1:
		s->isUTF8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	s->string = [self resizeMemory: s->string
				toSize: s->length + length + 1];
	memcpy(s->string + s->length, string, length + 1);
	s->length += length;
}

- (void)appendCString: (const char*)string
	   withLength: (size_t)length
{
	if (length >= 3 && !memcmp(string, "\xEF\xBB\xBF", 3)) {
		string += 3;
		length -= 3;
	}

	switch (of_string_check_utf8(string, length)) {
	case 1:
		s->isUTF8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	s->string = [self resizeMemory: s->string
				toSize: s->length + length + 1];
	memcpy(s->string + s->length, string, length);
	s->length += length;
	s->string[s->length] = 0;
}

- (void)appendCString: (const char*)string
	 withEncoding: (of_string_encoding_t)encoding
	       length: (size_t)length
{
	if (encoding == OF_STRING_ENCODING_UTF_8)
		[self appendCString: string
			 withLength: length];
	else {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		[self appendString: [OFString stringWithCString: string
						       encoding: encoding
							 length: length]];
		[pool release];
	}
}

- (void)appendCStringWithoutUTF8Checking: (const char*)string
{
	size_t length;

	length = strlen(string);
	s->string = [self resizeMemory: s->string
				toSize: s->length + length + 1];
	memcpy(s->string + s->length, string, length + 1);
	s->length += length;
}

- (void)appendCStringWithoutUTF8Checking: (const char*)string
				  length: (size_t)length
{
	s->string = [self resizeMemory: s->string
				toSize: s->length + length + 1];
	memcpy(s->string + s->length, string, length);
	s->length += length;
	s->string[s->length] = 0;
}

- (void)appendString: (OFString*)string
{
	if (string == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	[self appendCString: [string cString]];
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
	int length;

	if (format == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if ((length = of_vasprintf(&t, [format cString], arguments)) == -1)
		@throw [OFInvalidFormatException newWithClass: isa];

	@try {
		[self appendCString: t
			 withLength: length];
	} @finally {
		free(t);
	}
}

- (void)prependString: (OFString*)string
{
	return [self insertString: string
			  atIndex: 0];
}

- (void)reverse
{
	size_t i, j, length = s->length / 2;

	madvise(s->string, s->length, MADV_SEQUENTIAL);

	/* We reverse all bytes and restore UTF-8 later, if necessary */
	for (i = 0, j = s->length - 1; i < length; i++, j--) {
		s->string[i] ^= s->string[j];
		s->string[j] ^= s->string[i];
		s->string[i] ^= s->string[j];
	}

	if (!s->isUTF8) {
		madvise(s->string, s->length, MADV_NORMAL);
		return;
	}

	for (i = 0; i < s->length; i++) {
		/* ASCII */
		if (OF_LIKELY(!(s->string[i] & 0x80)))
			continue;

		/* A start byte can't happen first as we reversed everything */
		if (OF_UNLIKELY(s->string[i] & 0x40)) {
			madvise(s->string, s->length, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Next byte must not be ASCII */
		if (OF_UNLIKELY(s->length < i + 1 ||
		    !(s->string[i + 1] & 0x80))) {
			madvise(s->string, s->length, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Next byte is the start byte */
		if (OF_LIKELY(s->string[i + 1] & 0x40)) {
			s->string[i] ^= s->string[i + 1];
			s->string[i + 1] ^= s->string[i];
			s->string[i] ^= s->string[i + 1];

			i++;
			continue;
		}

		/* Second next byte must not be ASCII */
		if (OF_UNLIKELY(s->length < i + 2 ||
		    !(s->string[i + 2] & 0x80))) {
			madvise(s->string, s->length, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Second next byte is the start byte */
		if (OF_LIKELY(s->string[i + 2] & 0x40)) {
			s->string[i] ^= s->string[i + 2];
			s->string[i + 2] ^= s->string[i];
			s->string[i] ^= s->string[i + 2];

			i += 2;
			continue;
		}

		/* Third next byte must not be ASCII */
		if (OF_UNLIKELY(s->length < i + 3 ||
		    !(s->string[i + 3] & 0x80))) {
			madvise(s->string, s->length, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Third next byte is the start byte */
		if (OF_LIKELY(s->string[i + 3] & 0x40)) {
			s->string[i] ^= s->string[i + 3];
			s->string[i + 3] ^= s->string[i];
			s->string[i] ^= s->string[i + 3];

			s->string[i + 1] ^= s->string[i + 2];
			s->string[i + 2] ^= s->string[i + 1];
			s->string[i + 1] ^= s->string[i + 2];

			i += 3;
			continue;
		}

		/* UTF-8 does not allow more than 4 bytes per character */
		madvise(s->string, s->length, MADV_NORMAL);
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	madvise(s->string, s->length, MADV_NORMAL);
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

- (void)insertString: (OFString*)string
	     atIndex: (size_t)index
{
	size_t newLength;

	if (s->isUTF8)
		index = of_string_index_to_position(s->string, index,
		    s->length);

	if (index > s->length)
		@throw [OFOutOfRangeException newWithClass: isa];

	newLength = s->length + [string cStringLength];
	s->string = [self resizeMemory: s->string
				toSize: newLength + 1];

	memmove(s->string + index + [string cStringLength], s->string + index,
	    s->length - index);
	memcpy(s->string + index, [string cString], [string cStringLength]);
	s->string[newLength] = '\0';

	s->length = newLength;
}

- (void)deleteCharactersFromIndex: (size_t)start
			  toIndex: (size_t)end
{
	if (s->isUTF8) {
		start = of_string_index_to_position(s->string, start,
		    s->length);
		end = of_string_index_to_position(s->string, end, s->length);
	}

	if (start > end)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (end > s->length)
		@throw [OFOutOfRangeException newWithClass: isa];

	memmove(s->string + start, s->string + end, s->length - end);
	s->length -= end - start;
	s->string[s->length] = 0;

	@try {
		s->string = [self resizeMemory: s->string
					toSize: s->length + 1];
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

	if (s->isUTF8) {
		start = of_string_index_to_position(s->string, start,
		    s->length);
		end = of_string_index_to_position(s->string, end, s->length);
	}

	if (start > end)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (end > s->length)
		@throw [OFOutOfRangeException newWithClass: isa];

	newLength = s->length - (end - start) + [replacement cStringLength];
	s->string = [self resizeMemory: s->string
				toSize: newLength + 1];

	memmove(s->string + end, s->string + start +
	    [replacement cStringLength], s->length - end);
	memcpy(s->string + start, [replacement cString],
	    [replacement cStringLength]);
	s->string[newLength] = '\0';

	s->length = newLength;
}

- (void)replaceCharactersInRange: (of_range_t)range
		      withString: (OFString*)replacement
{
	[self replaceCharactersFromIndex: range.start
				 toIndex: range.start + range.length
			      withString: replacement];
}

- (void)replaceOccurrencesOfString: (OFString*)string
			withString: (OFString*)replacement
{
	const char *cString = [string cString];
	const char *replacementCString = [replacement cString];
	size_t stringLen = [string cStringLength];
	size_t replacementLen = [replacement cStringLength];
	size_t i, last, newLength;
	char *newString;

	if (stringLen > s->length)
		return;

	newString = NULL;
	newLength = 0;

	for (i = 0, last = 0; i <= s->length - stringLen; i++) {
		if (memcmp(s->string + i, cString, stringLen))
			continue;

		@try {
			newString = [self resizeMemory: newString
						toSize: newLength + i - last +
							replacementLen + 1];
		} @catch (id e) {
			[self freeMemory: newString];
			@throw e;
		}
		memcpy(newString + newLength, s->string + last, i - last);
		memcpy(newString + newLength + i - last, replacementCString,
		    replacementLen);
		newLength += i - last + replacementLen;
		i += stringLen - 1;
		last = i + 1;
	}

	@try {
		newString = [self resizeMemory: newString
					toSize: newLength + s->length - last +
						1];
	} @catch (id e) {
		[self freeMemory: newString];
		@throw e;
	}
	memcpy(newString + newLength, s->string + last, s->length - last);
	newLength += s->length - last;
	newString[newLength] = 0;

	[self freeMemory: s->string];
	s->string = newString;
	s->length = newLength;
}

- (void)deleteLeadingWhitespaces
{
	size_t i;

	for (i = 0; i < s->length; i++)
		if (s->string[i] != ' '  && s->string[i] != '\t' &&
		    s->string[i] != '\n' && s->string[i] != '\r')
			break;

	s->length -= i;
	memmove(s->string, s->string + i, s->length);
	s->string[s->length] = '\0';

	@try {
		s->string = [self resizeMemory: s->string
					toSize: s->length + 1];
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
	for (p = s->string + s->length - 1; p >= s->string; p--) {
		if (*p != ' ' && *p != '\t' && *p != '\n' && *p != '\r')
			break;

		*p = '\0';
		d++;
	}

	s->length -= d;

	@try {
		s->string = [self resizeMemory: s->string
					toSize: s->length + 1];
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
	for (p = s->string + s->length - 1; p >= s->string; p--) {
		if (*p != ' ' && *p != '\t' && *p != '\n' && *p != '\r')
			break;

		*p = '\0';
		d++;
	}

	s->length -= d;

	for (i = 0; i < s->length; i++)
		if (s->string[i] != ' '  && s->string[i] != '\t' &&
		    s->string[i] != '\n' && s->string[i] != '\r')
			break;

	s->length -= i;
	memmove(s->string, s->string + i, s->length);
	s->string[s->length] = '\0';

	@try {
		s->string = [self resizeMemory: s->string
					toSize: s->length + 1];
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
