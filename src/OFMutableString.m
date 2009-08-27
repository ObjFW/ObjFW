/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#define _GNU_SOURCE
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#ifdef HAVE_MADVISE
#include <sys/mman.h>
#else
#define madvise(addr, len, advise)
#endif

#import "OFMutableString.h"
#import "OFExceptions.h"
#import "OFMacros.h"

#import "asprintf.h"

@implementation OFMutableString
- setToCString: (const char*)str
{
	size_t len;

	if (string != NULL)
		[self freeMemory: string];

	len = strlen(str);

	switch (of_string_check_utf8(str, len)) {
	case 1:
		is_utf8 = YES;
		break;
	case -1:
		string = NULL;
		length = 0;
		is_utf8 = NO;

		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	length = len;
	string = [self allocMemoryWithSize: length + 1];
	memcpy(string, str, length + 1);

	return self;
}

- appendCString: (const char*)str
{
	size_t strlength;

	strlength = strlen(str);

	switch (of_string_check_utf8(str, strlength)) {
	case 1:
		is_utf8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	string = [self resizeMemory: string
			     toSize: length + strlength + 1];
	memcpy(string + length, str, strlength + 1);
	length += strlength;

	return self;
}

- appendCString: (const char*)str
     withLength: (size_t)len
{
	if (len > strlen(str))
		@throw [OFOutOfRangeException newWithClass: isa];

	switch (of_string_check_utf8(str, len)) {
	case 1:
		is_utf8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	string = [self resizeMemory: string
			     toSize: length + len + 1];
	memcpy(string + length, str, len);
	length += len;
	string[length] = 0;

	return self;
}

- appendCStringWithoutUTF8Checking: (const char*)str
{
	size_t strlength;

	strlength = strlen(str);
	string = [self resizeMemory: string
			     toSize: length + strlength + 1];
	memcpy(string + length, str, strlength + 1);
	length += strlength;

	return self;
}

- appendCStringWithoutUTF8Checking: (const char*)str
			    length: (size_t)len
{
	if (len > strlen(str))
		@throw [OFOutOfRangeException newWithClass: isa];

	string = [self resizeMemory: string
			     toSize: length + len + 1];
	memcpy(string + length, str, len);
	length += len;
	string[length] = 0;

	return self;
}

- appendString: (OFString*)str
{
	return [self appendCStringWithoutUTF8Checking: [str cString]];
}

- appendWithFormat: (OFString*)fmt, ...
{
	id ret;
	va_list args;

	va_start(args, fmt);
	ret = [self appendWithFormat: fmt
			   arguments: args];
	va_end(args);

	return ret;
}

- appendWithFormat: (OFString*)fmt
	 arguments: (va_list)args
{
	char *t;

	if (fmt == NULL)
		@throw [OFInvalidFormatException newWithClass: isa];

	if ((vasprintf(&t, [fmt cString], args)) == -1)
		/*
		 * This is only the most likely error to happen.
		 * Unfortunately, as errno isn't always thread-safe, there's
		 * no good way for us to find out what really happened.
		 */
		@throw [OFOutOfMemoryException newWithClass: isa];

	@try {
		[self appendCString: t];
	} @finally {
		free(t);
	}

	return self;
}

- reverse
{
	size_t i, j, len = length / 2;

	madvise(string, len, MADV_SEQUENTIAL);

	/* We reverse all bytes and restore UTF-8 later, if necessary */
	for (i = 0, j = length - 1; i < len; i++, j--) {
		string[i] ^= string[j];
		string[j] ^= string[i];
		string[i] ^= string[j];
	}

	if (!is_utf8) {
		madvise(string, len, MADV_NORMAL);
		return self;
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

	return self;
}

- upper
{
	char *p = string + length;

	if (is_utf8)
		@throw [OFInvalidEncodingException newWithClass: isa];

	while (--p >= string)
		*p = toupper((int)*p);

	return self;
}

- lower
{
	char *p = string + length;

	if (is_utf8)
		@throw [OFInvalidEncodingException newWithClass: isa];

	while (--p >= string)
		*p = tolower((int)*p);

	return self;
}

- removeCharactersFromIndex: (size_t)start
		    toIndex: (size_t)end
{
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

	return self;
}

- replaceOccurrencesOfString: (OFString*)str
		  withString: (OFString*)repl
{
	const char *str_c = [str cString];
	const char *repl_c = [repl cString];
	size_t str_len = [str length];
	size_t repl_len = [repl length];
	size_t i, last, tmp_len;
	char *tmp;

	if (str_len > length)
		return self;

	tmp = NULL;
	tmp_len = 0;

	for (i = 0, last = 0; i <= length - str_len; i++) {
		if (memcmp(string + i, str_c, str_len))
			continue;

		@try {
			tmp = [self resizeMemory: tmp
					  toSize: tmp_len + i - last +
						  repl_len + 1];
		} @catch (OFException *e) {
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
	} @catch (OFException *e) {
		[self freeMemory: tmp];
		@throw e;
	}
	memcpy(tmp + tmp_len, string + last, length - last);
	tmp_len += length - last;
	tmp[tmp_len] = 0;

	[self freeMemory: string];
	string = tmp;
	length = tmp_len;

	return self;
}

- removeLeadingWhitespaces
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

	return self;
}

- removeTrailingWhitespaces
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

	return self;
}

- removeLeadingAndTrailingWhitespaces
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

	return self;
}

- (id)copy
{
	return [[OFString alloc] initWithString: self];
}
@end
