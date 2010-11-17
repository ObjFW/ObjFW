/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#define _GNU_SOURCE
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
#import "OFExceptions.h"
#import "macros.h"

#import "asprintf.h"
#import "unicode.h"

@implementation OFMutableString
- (void)_applyTable: (const of_unichar_t* const[])table
	   withSize: (size_t)table_size
{
	of_unichar_t c;
	of_unichar_t *ustr;
	size_t ulen, nlen, clen;
	size_t i, j, d;
	char *nstr;

	if (!isUTF8) {
		assert(table_size >= 1);

		uint8_t *p = (uint8_t*)string + length;
		uint8_t t;

		while (--p >= (uint8_t*)string)
			if ((t = table[0][*p]) != 0)
				*p = t;

		return;
	}

	ulen = [self length];
	ustr = [self allocMemoryForNItems: [self length]
				 withSize: ulen];

	i = 0;
	j = 0;
	nlen = 0;

	while (i < length) {
		clen = of_string_utf8_to_unicode(string + i, length - i, &c);

		if (clen == 0 || c > 0x10FFFF) {
			[self freeMemory: ustr];
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		if (c >> 8 < table_size) {
			of_unichar_t tc = table[c >> 8][c & 0xFF];

			if (tc)
				c = tc;
		}
		ustr[j++] = c;

		if (c < 0x80)
			nlen++;
		else if (c < 0x800)
			nlen += 2;
		else if (c < 0x10000)
			nlen += 3;
		else if (c < 0x110000)
			nlen += 4;
		else {
			[self freeMemory: ustr];
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		i += clen;
	}

	@try {
		nstr = [self allocMemoryWithSize: nlen + 1];
	} @catch (id e) {
		[self freeMemory: ustr];
		@throw e;
	}

	j = 0;

	for (i = 0; i < ulen; i++) {
		if ((d = of_string_unicode_to_utf8(ustr[i], nstr + j)) == 0) {
			[self freeMemory: ustr];
			[self freeMemory: nstr];
			@throw [OFInvalidEncodingException newWithClass: isa];
		}
		j += d;
	}

	assert(j == nlen);
	nstr[j] = 0;
	[self freeMemory: ustr];

	[self freeMemory: string];
	string = nstr;
	length = nlen;
}

- (void)setToCString: (const char*)str
{
	size_t len;

	[self freeMemory: string];

	len = strlen(str);

	switch (of_string_check_utf8(str, len)) {
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

	length = len;
	string = [self allocMemoryWithSize: length + 1];
	memcpy(string, str, length + 1);
}

- (void)appendCString: (const char*)str
{
	size_t strlength;

	strlength = strlen(str);

	switch (of_string_check_utf8(str, strlength)) {
	case 1:
		isUTF8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	string = [self resizeMemory: string
			     toSize: length + strlength + 1];
	memcpy(string + length, str, strlength + 1);
	length += strlength;
}

- (void)appendCString: (const char*)str
	   withLength: (size_t)len
{
	if (len > strlen(str))
		@throw [OFOutOfRangeException newWithClass: isa];

	switch (of_string_check_utf8(str, len)) {
	case 1:
		isUTF8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	string = [self resizeMemory: string
			     toSize: length + len + 1];
	memcpy(string + length, str, len);
	length += len;
	string[length] = 0;
}

- (void)appendCStringWithoutUTF8Checking: (const char*)str
{
	size_t strlength;

	strlength = strlen(str);
	string = [self resizeMemory: string
			     toSize: length + strlength + 1];
	memcpy(string + length, str, strlength + 1);
	length += strlength;
}

- (void)appendCStringWithoutUTF8Checking: (const char*)str
				  length: (size_t)len
{
	string = [self resizeMemory: string
			     toSize: length + len + 1];
	memcpy(string + length, str, len);
	length += len;
	string[length] = 0;
}

- (void)appendString: (OFString*)str
{
	[self appendCString: [str cString]];
}

- (void)appendFormat: (OFString*)fmt, ...
{
	va_list args;

	va_start(args, fmt);
	[self appendFormat: fmt
	     withArguments: args];
	va_end(args);
}

- (void)appendFormat: (OFString*)fmt
       withArguments: (va_list)args
{
	char *t;

	if (fmt == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if ((vasprintf(&t, [fmt cString], args)) == -1) {
		/*
		 * This is only the most likely error to happen. Unfortunately,
		 * there is no good way to check what really happened.
		 */
		@throw [OFOutOfMemoryException newWithClass: isa];
	}

	@try {
		[self appendCString: t];
	} @finally {
		free(t);
	}
}

- (void)prependString: (OFString*)str
{
	return [self insertString: str
			  atIndex: 0];
}

- (void)reverse
{
	size_t i, j, len = length / 2;

	madvise(string, len, MADV_SEQUENTIAL);

	/* We reverse all bytes and restore UTF-8 later, if necessary */
	for (i = 0, j = length - 1; i < len; i++, j--) {
		string[i] ^= string[j];
		string[j] ^= string[i];
		string[i] ^= string[j];
	}

	if (!isUTF8) {
		madvise(string, len, MADV_NORMAL);
		return;
	}

	for (i = 0; i < length; i++) {
		/* ASCII */
		if (OF_LIKELY(!(string[i] & 0x80)))
			continue;

		/* A start byte can't happen first as we reversed everything */
		if (OF_UNLIKELY(string[i] & 0x40)) {
			madvise(string, len, MADV_NORMAL);
			@throw [OFInvalidEncodingException newWithClass: isa];
		}

		/* Next byte must not be ASCII */
		if (OF_UNLIKELY(length < i + 1 || !(string[i + 1] & 0x80))) {
			madvise(string, len, MADV_NORMAL);
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
			madvise(string, len, MADV_NORMAL);
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
			madvise(string, len, MADV_NORMAL);
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
		madvise(string, len, MADV_NORMAL);
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	madvise(string, len, MADV_NORMAL);
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

- (void)insertString: (OFString*)str
	     atIndex: (size_t)idx
{
	size_t nlen;

	if (isUTF8)
		idx = of_string_index_to_position(string, idx, length);

	if (idx > length)
		@throw [OFOutOfRangeException newWithClass: isa];

	nlen = length + [str cStringLength];
	string = [self resizeMemory: string
			     toSize: nlen + 1];

	memmove(string + idx + [str cStringLength], string + idx, length - idx);
	memcpy(string + idx, [str cString], [str cStringLength]);
	string[nlen] = '\0';

	length = nlen;
}

- (void)removeCharactersFromIndex: (size_t)start
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
		[e dealloc];
	}
}

- (void)removeCharactersInRange: (of_range_t)range
{
	[self removeCharactersFromIndex: range.start
				toIndex: range.start + range.length];
}

- (void)replaceCharactersFromIndex: (size_t)start
			   toIndex: (size_t)end
			withString: (OFString*)repl
{
	size_t nlen;

	if (isUTF8) {
		start = of_string_index_to_position(string, start, length);
		end = of_string_index_to_position(string, end, length);
	}

	if (start > end)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (end > length)
		@throw [OFOutOfRangeException newWithClass: isa];

	nlen = length - (end - start) + [repl cStringLength];
	string = [self resizeMemory: string
			     toSize: nlen + 1];

	memmove(string + end, string + start + [repl cStringLength],
	    length - end);
	memcpy(string + start, [repl cString], [repl cStringLength]);
	string[nlen] = '\0';

	length = nlen;
}

- (void)replaceCharactersInRange: (of_range_t)range
		      withString: (OFString*)repl
{
	[self replaceCharactersFromIndex: range.start
				 toIndex: range.start + range.length
			      withString: repl];
}

- (void)replaceOccurrencesOfString: (OFString*)str
			withString: (OFString*)repl
{
	const char *str_c = [str cString];
	const char *repl_c = [repl cString];
	size_t str_len = [str cStringLength];
	size_t repl_len = [repl cStringLength];
	size_t i, last, tmp_len;
	char *tmp;

	if (str_len > length)
		return;

	tmp = NULL;
	tmp_len = 0;

	for (i = 0, last = 0; i <= length - str_len; i++) {
		if (memcmp(string + i, str_c, str_len))
			continue;

		@try {
			tmp = [self resizeMemory: tmp
					  toSize: tmp_len + i - last +
						  repl_len + 1];
		} @catch (id e) {
			[self freeMemory: tmp];
			@throw e;
		}
		memcpy(tmp + tmp_len, string + last, i - last);
		memcpy(tmp + tmp_len + i - last, repl_c, repl_len);
		tmp_len += i - last + repl_len;
		i += str_len - 1;
		last = i + 1;
	}

	@try {
		tmp = [self resizeMemory: tmp
				  toSize: tmp_len + length - last + 1];
	} @catch (id e) {
		[self freeMemory: tmp];
		@throw e;
	}
	memcpy(tmp + tmp_len, string + last, length - last);
	tmp_len += length - last;
	tmp[tmp_len] = 0;

	[self freeMemory: string];
	string = tmp;
	length = tmp_len;
}

- (void)removeLeadingWhitespaces
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
		[e dealloc];
	}
}

- (void)removeTrailingWhitespaces
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
		[e dealloc];
	}
}

- (void)removeLeadingAndTrailingWhitespaces
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
		[e dealloc];
	}
}

- copy
{
	return [[OFString alloc] initWithString: self];
}
@end
