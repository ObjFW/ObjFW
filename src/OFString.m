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

#import "OFString.h"
#import "OFConstString.h"
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

@implementation OFString
+ string
{
	return [[[OFString alloc] init] autorelease];
}

+ stringWithCString: (const char*)str
{
	return [[[OFString alloc] initWithCString: str] autorelease];
}

+ stringWithFormat: (const char*)fmt, ...
{
	id ret;
	va_list args;

	va_start(args, fmt);
	ret = [[[OFString alloc] initWithFormat: fmt
			       andArguments: args] autorelease];
	va_end(args);

	return ret;
}

+ stringWithFormat: (const char*)fmt
      andArguments: (va_list)args
{
	return [[[OFString alloc] initWithFormat: fmt
				andArguments: args] autorelease];
}

- init
{
	if ((self = [super init])) {
		length = 0;
		string = NULL;
		is_utf8 = NO;
	}

	return self;
}

- initWithCString: (const char*)str
{
	Class c;

	if ((self = [super init])) {
		if (str != NULL) {
			length = strlen(str);

			switch (check_utf8(str, length)) {
			case 1:
				is_utf8 = YES;
				break;
			case -1:
				c = [self class];
				[super free];
				@throw [OFInvalidEncodingException
				    newWithClass: c];
			}

			@try {
				string = [self getMemWithSize: length + 1];
			} @catch (OFException *e) {
				[self free];
				@throw e;
			}
			memcpy(string, str, length + 1);
		}
	}

	return self;
}

- initWithFormat: (const char*)fmt, ...
{
	id ret;
	va_list args;

	va_start(args, fmt);
	ret = [self initWithFormat: fmt
		      andArguments: args];
	va_end(args);

	return ret;
}

- initWithFormat: (const char*)fmt
    andArguments: (va_list)args
{
	int t;
	Class c;

	if ((self = [super init])) {
		if (fmt == NULL) {
			c = [self class];
			[super free];
			@throw [OFInvalidFormatException newWithClass: c];
		}

		if ((t = vasprintf(&string, fmt, args)) == -1) {
			c = [self class];
			[super free];
			@throw [OFInitializationFailedException
			    newWithClass: c];
		}
		length = t;

		switch (check_utf8(string, length)) {
		case 1:
			is_utf8 = YES;
			break;
		case -1:
			free(string);
			c = [self class];
			[super free];
			@throw [OFInvalidEncodingException newWithClass: c];
		}

		@try {
			[self addToMemoryPool: string];
		} @catch (OFException *e) {
			free(string);
			@throw e;
		}
	}

	return self;
}

- (const char*)cString
{
	return string;
}

- (size_t)length
{
	return length;
}

- (id)copy
{
	return [OFString stringWithCString: string];
}

- setTo: (const char*)str
{
	size_t len;

	if (string != NULL)
		free(string);

	len = strlen(str);

	switch (check_utf8(str, len)) {
	case 1:
		is_utf8 = YES;
		break;
	case -1:
		string = NULL;
		length = 0;
		is_utf8 = NO;

		@throw [OFInvalidEncodingException newWithClass: [self class]];
	}

	length = len;
	string = [self getMemWithSize: length + 1];
	memcpy(string, str, length + 1);

	return self;
}

- (BOOL)isEqual: (id)obj
{
	if (![obj isKindOf: [OFString class]] &&
	    ![obj isKindOf: [OFConstString class]])
		return NO;
	if (strcmp(string, [obj cString]))
		return NO;

	return YES;
}

- (int)compare: (id)obj
{
	if (![obj isKindOf: [OFString class]] &&
	    ![obj isKindOf: [OFConstString class]])
		@throw [OFInvalidArgumentException newWithClass: [self class]];

	return strcmp(string, [obj cString]);
}

- (uint32_t)hash
{
	uint32_t hash;
	size_t i;

	OF_HASH_INIT(hash);
	for (i = 0; i < length; i++)
		OF_HASH_ADD(hash, string[i]);
	OF_HASH_FINALIZE(hash);

	return hash;
}

- append: (OFString*)str
{
	return [self appendCString: [str cString]];
}

- appendCString: (const char*)str
{
	char   *newstr;
	size_t newlen, strlength;

	strlength = strlen(str);

	switch (check_utf8(str, strlength)) {
	case 1:
		is_utf8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithClass: [self class]];
	}

	newlen = length + strlength;
	newstr = [self resizeMem: string
			  toSize: newlen + 1];

	memcpy(newstr + length, str, strlength + 1);

	length = newlen;
	string = newstr;

	return self;
}

- appendWithFormatCString: (const char*)fmt, ...
{
	id ret;
	va_list args;

	va_start(args, fmt);
	ret = [self appendWithFormatCString: fmt
			       andArguments: args];
	va_end(args);

	return ret;
}

- appendWithFormatCString: (const char*)fmt
	     andArguments: (va_list)args
{
	char *t;

	if (fmt == NULL)
		@throw [OFInvalidFormatException newWithClass: [self class]];

	if ((vasprintf(&t, fmt, args)) == -1)
		/*
		 * This is only the most likely error to happen.
		 * Unfortunately, as errno isn't always thread-safe, there's
		 * no good way for us to find out what really happened.
		 */
		@throw [OFNoMemException newWithClass: [self class]];

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
			@throw [OFInvalidEncodingException
			    newWithClass: [self class]];
		}

		/* Next byte must not be ASCII */
		if (OF_UNLIKELY(length < i + 1 || !(string[i + 1] & 0x80))) {
			madvise(string, len, MADV_NORMAL);
			@throw [OFInvalidEncodingException
			    newWithClass: [self class]];
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
			@throw [OFInvalidEncodingException
			    newWithClass: [self class]];
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
			@throw [OFInvalidEncodingException
			    newWithClass: [self class]];
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
		@throw [OFInvalidEncodingException newWithClass: [self class]];
	}

	madvise(string, len, MADV_NORMAL);

	return self;
}

- upper
{
	char *p = string + length;

	if (is_utf8)
		@throw [OFInvalidEncodingException newWithClass: [self class]];

	while (--p >= string)
		*p = toupper((int)*p);

	return self;
}

- lower
{
	char *p = string + length;

	if (is_utf8)
		@throw [OFInvalidEncodingException newWithClass: [self class]];

	while (--p >= string)
		*p = tolower((int)*p);

	return self;
}
@end
