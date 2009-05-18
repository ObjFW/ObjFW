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
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
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

@implementation OFMutableString
- setToCString: (const char*)str
{
	size_t len;

	if (string != NULL)
		[self freeMem: string];

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

	switch (of_string_check_utf8(str, strlength)) {
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
