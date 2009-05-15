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

#import "config.h"

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

#ifdef HAVE_SYS_MMAN_H
#include <sys/mman.h>
#else
#define madvise(addr, len, advise)
#endif

#import "OFMutableString.h"
#import "OFExceptions.h"
#import "OFMacros.h"

#ifndef HAVE_ASPRINTF
#import "asprintf.h"
#endif

static OF_INLINE int
check_utf8(const char *str, size_t len)
{
	size_t i;
	BOOL utf8;

	utf8 = NO;

	madvise((void*)str, len, MADV_SEQUENTIAL);

	for (i = 0; i < len; i++) {
		/* No sign of UTF-8 here */
		if (OF_LIKELY(!(str[i] & 0x80)))
			continue;

		utf8 = YES;

		/* We're missing a start byte here */
		if (OF_UNLIKELY(!(str[i] & 0x40))) {
			madvise((void*)str, len, MADV_NORMAL);
			return -1;
		}

		/* We have at minimum a 2 byte character -> check next byte */
		if (OF_UNLIKELY(len < i + 1 || (str[i + 1] & 0xC0) != 0x80)) {
			madvise((void*)str, len, MADV_NORMAL);
			return -1;
		}

		/* Check if we have at minimum a 3 byte character */
		if (OF_LIKELY(!(str[i] & 0x20))) {
			i++;
			continue;
		}

		/* We have at minimum a 3 byte char -> check second next byte */
		if (OF_UNLIKELY(len < i + 2 || (str[i + 2] & 0xC0) != 0x80)) {
			madvise((void*)str, len, MADV_NORMAL);
			return -1;
		}

		/* Check if we have a 4 byte character */
		if (OF_LIKELY(!(str[i] & 0x10))) {
			i += 2;
			continue;
		}

		/* We have a 4 byte character -> check third next byte */
		if (OF_UNLIKELY(len < i + 3 || (str[i + 3] & 0xC0) != 0x80)) {
			madvise((void*)str, len, MADV_NORMAL);
			return -1;
		}

		/*
		 * Just in case, check if there's a 5th character, which is
		 * forbidden by UTF-8
		 */
		if (OF_UNLIKELY(str[i] & 0x08)) {
			madvise((void*)str, len, MADV_NORMAL);
			return -1;
		}

		i += 3;
	}

	madvise((void*)str, len, MADV_NORMAL);

	return (utf8 ? 1 : 0);
}

@implementation OFMutableString
- init
{
	[super init];

	is_utf8 = NO;

	return self;
}

- initWithCString: (const char*)str
{
	Class c;

	self = [super init];

	if (str != NULL) {
		length = strlen(str);

		switch (check_utf8(str, length)) {
			case 1:
				is_utf8 = YES;
				break;
			case -1:
				c = isa;
				[super dealloc];
				@throw [OFInvalidEncodingException
					newWithClass: c];
		}

		@try {
			string = [self allocWithSize: length + 1];
		} @catch (OFException *e) {
			/*
			 * We can't use [super dealloc] on OS X here.
			 * Compiler bug? Anyway, [self dealloc] will do here as
			 * we don't reimplement dealloc.
			 */
			[self dealloc];
			@throw e;
		}
		memcpy(string, str, length + 1);
	}

	return self;
}

- initWithFormat: (OFString*)fmt, ...
{
	id ret;
	va_list args;

	va_start(args, fmt);
	ret = [self initWithFormat: fmt
		      andArguments: args];
	va_end(args);

	return ret;
}

- initWithFormat: (OFString*)fmt
    andArguments: (va_list)args
{
	int t;
	Class c;

	self = [super init];

	if (fmt == NULL) {
		c = isa;
		[super dealloc];
		@throw [OFInvalidFormatException newWithClass: c];
	}

	if ((t = vasprintf(&string, [fmt cString], args)) == -1) {
		c = isa;
		[super dealloc];
		@throw [OFInitializationFailedException newWithClass: c];
	}
	length = t;

	switch (check_utf8(string, length)) {
		case 1:
			is_utf8 = YES;
			break;
		case -1:
			free(string);
			c = isa;
			[super dealloc];
			@throw [OFInvalidEncodingException newWithClass: c];
	}

	@try {
		[self addToMemoryPool: string];
	} @catch (OFException *e) {
		free(string);
		@throw e;
	}

	return self;
}

- setTo: (const char*)str
{
	size_t len;

	if (string != NULL)
		[self freeMem: string];

	len = strlen(str);

	switch (check_utf8(str, len)) {
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
	string = [self allocWithSize: length + 1];
	memcpy(string, str, length + 1);

	return self;
}

- append: (OFString*)str
{
	return [self appendCString: [str cString]];
}

- appendCString: (const char*)str
{
	size_t strlength;

	strlength = strlen(str);

	switch (check_utf8(str, strlength)) {
	case 1:
		is_utf8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	string = [self resizeMem: string
			  toSize: length + strlength + 1];
	memcpy(string + length, str, strlength + 1);
	length += strlength;

	return self;
}

- appendWithFormat: (OFString*)fmt, ...
{
	id ret;
	va_list args;

	va_start(args, fmt);
	ret = [self appendWithFormat: fmt
			andArguments: args];
	va_end(args);

	return ret;
}

- appendWithFormat: (OFString*)fmt
      andArguments: (va_list)args
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
		@throw [OFNoMemException newWithClass: isa];

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
@end
