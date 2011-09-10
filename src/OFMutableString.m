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
	size_t unicodeLen, newCStringLength, cLen;
	size_t i, j, d;
	char *newCString;

	if (!s->isUTF8) {
		assert(tableSize >= 1);

		uint8_t *p = (uint8_t*)s->cString + s->cStringLength;
		uint8_t t;

		while (--p >= (uint8_t*)s->cString)
			if ((t = table[0][*p]) != 0)
				*p = t;

		return;
	}

	unicodeLen = [self length];
	unicodeString = [self allocMemoryForNItems: unicodeLen
					  withSize: sizeof(of_unichar_t)];

	i = j = 0;
	newCStringLength = 0;

	while (i < s->cStringLength) {
		cLen = of_string_utf8_to_unicode(s->cString + i,
		    s->cStringLength - i, &c);

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
			newCStringLength++;
		else if (c < 0x800)
			newCStringLength += 2;
		else if (c < 0x10000)
			newCStringLength += 3;
		else if (c < 0x110000)
			newCStringLength += 4;
		else {
			[self freeMemory: unicodeString];
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		i += cLen;
	}

	@try {
		newCString = [self allocMemoryWithSize: newCStringLength + 1];
	} @catch (id e) {
		[self freeMemory: unicodeString];
		@throw e;
	}

	j = 0;

	for (i = 0; i < unicodeLen; i++) {
		if ((d = of_string_unicode_to_utf8(unicodeString[i],
		    newCString + j)) == 0) {
			[self freeMemory: unicodeString];
			[self freeMemory: newCString];
			@throw [OFInvalidEncodingException newWithClass: isa];
		}
		j += d;
	}

	assert(j == newCStringLength);
	newCString[j] = 0;
	[self freeMemory: unicodeString];

	[self freeMemory: s->cString];
	s->cString = newCString;
	s->cStringLength = newCStringLength;

	/*
	 * Even though cStringLength can change, length cannot, therefore no
	 * need to change it.
	 */
}

- (void)setToCString: (const char*)newCString
{
	size_t newCStringLength = strlen(newCString);
	size_t newLength;

	if (newCStringLength >= 3 && !memcmp(newCString, "\xEF\xBB\xBF", 3)) {
		newCString += 3;
		newCStringLength -= 3;
	}

	switch (of_string_check_utf8(newCString, newCStringLength,
	    &newLength)) {
	case 0:
		s->isUTF8 = NO;
		break;
	case 1:
		s->isUTF8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	[self freeMemory: s->cString];

	s->cStringLength = newCStringLength;
	s->length = newLength;

	s->cString = [self allocMemoryWithSize: newCStringLength + 1];
	memcpy(s->cString, newCString, newCStringLength + 1);
}

- (void)appendCString: (const char*)cString
{
	size_t cStringLength = strlen(cString);
	size_t length;

	if (cStringLength >= 3 && !memcmp(cString, "\xEF\xBB\xBF", 3)) {
		cString += 3;
		cStringLength -= 3;
	}

	switch (of_string_check_utf8(cString, cStringLength, &length)) {
	case 1:
		s->isUTF8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	s->cString = [self resizeMemory: s->cString
				 toSize: s->cStringLength + cStringLength + 1];
	memcpy(s->cString + s->cStringLength, cString, cStringLength + 1);

	s->cStringLength += cStringLength;
	s->length += length;
}

- (void)appendCString: (const char*)cString
	   withLength: (size_t)cStringLength
{
	size_t length;

	if (cStringLength >= 3 && !memcmp(cString, "\xEF\xBB\xBF", 3)) {
		cString += 3;
		cStringLength -= 3;
	}

	switch (of_string_check_utf8(cString, cStringLength, &length)) {
	case 1:
		s->isUTF8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	s->cString = [self resizeMemory: s->cString
				 toSize: s->cStringLength + cStringLength + 1];
	memcpy(s->cString + s->cStringLength, cString, cStringLength);

	s->cStringLength += cStringLength;
	s->length += length;

	s->cString[s->cStringLength] = 0;
}

- (void)appendCString: (const char*)cString
	 withEncoding: (of_string_encoding_t)encoding
	       length: (size_t)cStringLength
{
	if (encoding == OF_STRING_ENCODING_UTF_8)
		[self appendCString: cString
			 withLength: cStringLength];
	else {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		[self appendString:
		    [OFString stringWithCString: cString
				       encoding: encoding
					 length: cStringLength]];
		[pool release];
	}
}

- (void)appendString: (OFString*)string
{
	size_t cStringLength;

	if (string == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	cStringLength = [string cStringLength];

	s->cString = [self resizeMemory: s->cString
				 toSize: s->cStringLength + cStringLength + 1];
	memcpy(s->cString + s->cStringLength, string->s->cString,
	    cStringLength);

	s->cStringLength += cStringLength;
	s->length += string->s->length;

	s->cString[s->cStringLength] = 0;

	if (string->s->isUTF8)
		s->isUTF8 = YES;
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
	char *cString;
	int cStringLength;

	if (format == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if ((cStringLength = of_vasprintf(&cString, [format cString],
	    arguments)) == -1)
		@throw [OFInvalidFormatException newWithClass: isa];

	@try {
		[self appendCString: cString
			 withLength: cStringLength];
	} @finally {
		free(cString);
	}
}

- (void)prependString: (OFString*)string
{
	return [self insertString: string
			  atIndex: 0];
}

- (void)reverse
{
	size_t i, j;

	madvise(s->cString, s->cStringLength, MADV_SEQUENTIAL);

	/* We reverse all bytes and restore UTF-8 later, if necessary */
	for (i = 0, j = s->cStringLength - 1; i < s->cStringLength / 2;
	    i++, j--) {
		s->cString[i] ^= s->cString[j];
		s->cString[j] ^= s->cString[i];
		s->cString[i] ^= s->cString[j];
	}

	if (!s->isUTF8) {
		madvise(s->cString, s->cStringLength, MADV_NORMAL);
		return;
	}

	for (i = 0; i < s->cStringLength; i++) {
		/* ASCII */
		if (OF_LIKELY(!(s->cString[i] & 0x80)))
			continue;

		/* A start byte can't happen first as we reversed everything */
		if (OF_UNLIKELY(s->cString[i] & 0x40)) {
			madvise(s->cString, s->cStringLength, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Next byte must not be ASCII */
		if (OF_UNLIKELY(s->cStringLength < i + 1 ||
		    !(s->cString[i + 1] & 0x80))) {
			madvise(s->cString, s->cStringLength, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Next byte is the start byte */
		if (OF_LIKELY(s->cString[i + 1] & 0x40)) {
			s->cString[i] ^= s->cString[i + 1];
			s->cString[i + 1] ^= s->cString[i];
			s->cString[i] ^= s->cString[i + 1];

			i++;
			continue;
		}

		/* Second next byte must not be ASCII */
		if (OF_UNLIKELY(s->cStringLength < i + 2 ||
		    !(s->cString[i + 2] & 0x80))) {
			madvise(s->cString, s->cStringLength, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Second next byte is the start byte */
		if (OF_LIKELY(s->cString[i + 2] & 0x40)) {
			s->cString[i] ^= s->cString[i + 2];
			s->cString[i + 2] ^= s->cString[i];
			s->cString[i] ^= s->cString[i + 2];

			i += 2;
			continue;
		}

		/* Third next byte must not be ASCII */
		if (OF_UNLIKELY(s->cStringLength < i + 3 ||
		    !(s->cString[i + 3] & 0x80))) {
			madvise(s->cString, s->cStringLength, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Third next byte is the start byte */
		if (OF_LIKELY(s->cString[i + 3] & 0x40)) {
			s->cString[i] ^= s->cString[i + 3];
			s->cString[i + 3] ^= s->cString[i];
			s->cString[i] ^= s->cString[i + 3];

			s->cString[i + 1] ^= s->cString[i + 2];
			s->cString[i + 2] ^= s->cString[i + 1];
			s->cString[i + 1] ^= s->cString[i + 2];

			i += 3;
			continue;
		}

		/* UTF-8 does not allow more than 4 bytes per character */
		madvise(s->cString, s->cStringLength, MADV_NORMAL);
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	madvise(s->cString, s->cStringLength, MADV_NORMAL);
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
	size_t newCStringLength;

	if (index > s->length)
		@throw [OFOutOfRangeException newWithClass: isa];

	if (s->isUTF8)
		index = of_string_index_to_position(s->cString, index,
		    s->cStringLength);

	newCStringLength = s->cStringLength + [string cStringLength];
	s->cString = [self resizeMemory: s->cString
				 toSize: newCStringLength + 1];

	memmove(s->cString + index + string->s->cStringLength,
	    s->cString + index, s->cStringLength - index);
	memcpy(s->cString + index, string->s->cString,
	    string->s->cStringLength);
	s->cString[newCStringLength] = '\0';

	s->cStringLength = newCStringLength;
	s->length += string->s->length;
}

- (void)deleteCharactersInRange: (of_range_t)range
{
	size_t start = range.start;
	size_t end = range.start + range.length;

	if (start > end)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (end > s->length)
		@throw [OFOutOfRangeException newWithClass: isa];

	s->length -= end - start;

	if (s->isUTF8) {
		start = of_string_index_to_position(s->cString, start,
		    s->cStringLength);
		end = of_string_index_to_position(s->cString, end,
		    s->cStringLength);
	}

	memmove(s->cString + start, s->cString + end, s->cStringLength - end);
	s->cStringLength -= end - start;
	s->cString[s->cStringLength] = 0;

	@try {
		s->cString = [self resizeMemory: s->cString
					 toSize: s->cStringLength + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
		[e release];
	}
}

- (void)replaceCharactersInRange: (of_range_t)range
		      withString: (OFString*)replacement
{
	size_t start = range.start;
	size_t end = range.start + range.length;
	size_t newCStringLength, newLength;

	if (start > end)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (end > s->length)
		@throw [OFOutOfRangeException newWithClass: isa];

	newLength = s->length - (end - start) + [replacement length];

	if (s->isUTF8) {
		start = of_string_index_to_position(s->cString, start,
		    s->cStringLength);
		end = of_string_index_to_position(s->cString, end,
		    s->cStringLength);
	}

	newCStringLength = s->cStringLength - (end - start) +
	    replacement->s->cStringLength;
	s->cString = [self resizeMemory: s->cString
				 toSize: newCStringLength + 1];

	memmove(s->cString + end, s->cString + start +
	    replacement->s->cStringLength, s->cStringLength - end);
	memcpy(s->cString + start, replacement->s->cString,
	    replacement->s->cStringLength);
	s->cString[newCStringLength] = '\0';

	s->cStringLength = newCStringLength;
	s->length = newLength;
}

- (void)replaceOccurrencesOfString: (OFString*)string
			withString: (OFString*)replacement
{
	const char *cString = [string cString];
	const char *replacementCString = [replacement cString];
	size_t cStringLength = string->s->cStringLength;
	size_t replacementCStringLength = replacement->s->cStringLength;
	size_t i, last, newCStringLength, newLength;
	char *newCString;

	if (cStringLength > s->cStringLength)
		return;

	newCString = NULL;
	newCStringLength = 0;
	newLength = s->length;

	for (i = 0, last = 0; i <= s->cStringLength - cStringLength; i++) {
		if (memcmp(s->cString + i, cString, cStringLength))
			continue;

		@try {
			newCString = [self
			    resizeMemory: newCString
				  toSize: newCStringLength + i - last +
					  replacementCStringLength + 1];
		} @catch (id e) {
			[self freeMemory: newCString];
			@throw e;
		}
		memcpy(newCString + newCStringLength, s->cString + last,
		    i - last);
		memcpy(newCString + newCStringLength + i - last,
		    replacementCString, replacementCStringLength);

		newCStringLength += i - last + replacementCStringLength;
		newLength = newLength - string->s->length +
		    replacement->s->length;

		i += cStringLength - 1;
		last = i + 1;
	}

	@try {
		newCString = [self
		    resizeMemory: newCString
			  toSize: newCStringLength +
				  s->cStringLength - last + 1];
	} @catch (id e) {
		[self freeMemory: newCString];
		@throw e;
	}
	memcpy(newCString + newCStringLength, s->cString + last,
	    s->cStringLength - last);
	newCStringLength += s->cStringLength - last;
	newCString[newCStringLength] = 0;

	[self freeMemory: s->cString];
	s->cString = newCString;
	s->cStringLength = newCStringLength;
	s->length = newLength;
}

- (void)deleteLeadingWhitespaces
{
	size_t i;

	for (i = 0; i < s->cStringLength; i++)
		if (s->cString[i] != ' '  && s->cString[i] != '\t' &&
		    s->cString[i] != '\n' && s->cString[i] != '\r')
			break;

	s->cStringLength -= i;
	s->length -= i;

	memmove(s->cString, s->cString + i, s->cStringLength);
	s->cString[s->cStringLength] = '\0';

	@try {
		s->cString = [self resizeMemory: s->cString
					 toSize: s->cStringLength + 1];
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
	for (p = s->cString + s->cStringLength - 1; p >= s->cString; p--) {
		if (*p != ' ' && *p != '\t' && *p != '\n' && *p != '\r')
			break;

		*p = '\0';
		d++;
	}

	s->cStringLength -= d;
	s->length -= d;

	@try {
		s->cString = [self resizeMemory: s->cString
					 toSize: s->cStringLength + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
		[e release];
	}
}

- (void)deleteEnclosingWhitespaces
{
	size_t d, i;
	char *p;

	d = 0;
	for (p = s->cString + s->cStringLength - 1; p >= s->cString; p--) {
		if (*p != ' ' && *p != '\t' && *p != '\n' && *p != '\r')
			break;

		*p = '\0';
		d++;
	}

	s->cStringLength -= d;
	s->length -= d;

	for (i = 0; i < s->cStringLength; i++)
		if (s->cString[i] != ' '  && s->cString[i] != '\t' &&
		    s->cString[i] != '\n' && s->cString[i] != '\r')
			break;

	s->cStringLength -= i;
	s->length -= i;

	memmove(s->cString, s->cString + i, s->cStringLength);
	s->cString[s->cStringLength] = '\0';

	@try {
		s->cString = [self resizeMemory: s->cString
					 toSize: s->cStringLength + 1];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't really care, as we only made it smaller */
		[e release];
	}
}

- copy
{
	return [[OFString alloc] initWithString: self];
}

- (void)makeImmutable
{
	isa = [OFString class];
}
@end
