/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#import <stdlib.h>
#import <string.h>
#import <ctype.h>

#import "OFString.h"
#import "OFExceptions.h"
#import "OFMacros.h"

static OF_INLINE int
check_utf8(const char *str, size_t len)
{
	size_t i;
	BOOL utf8;

	utf8 = NO;

	for (i = 0; i < len; i++) {
		/* No sign of UTF-8 here */
		if (OF_LIKELY(~str[i] & 0x80))
			continue;

		utf8 = YES;

		/* We're missing a start byte here */
		if (OF_UNLIKELY(~str[i] & 0x40))
			return -1;

		/* We have at minimum a 2 byte character -> check next byte */
		if (OF_UNLIKELY(len < i + 1 || ~str[i + 1] & 0x80 ||
		    str[i + 1] & 0x40))
			return -1;

		/* Check if we have at minimum a 3 byte character */
		if (OF_LIKELY(~str[i] & 0x20)) {
			i++;
			continue;
		}

		/* We have at minimum a 3 byte char -> check second next byte */
		if (OF_UNLIKELY(len < i + 2 || ~str[i + 2] & 0x80 ||
		    str[i + 2] & 0x40))
			return -1;

		/* Check if we have a 4 byte character */
		if (OF_LIKELY(~str[i] & 0x10)) {
			i += 2;
			continue;
		}

		/* We have a 4 byte character -> check third next byte */
		if (OF_UNLIKELY(len < i + 3 || ~str[i + 3] & 0x80 ||
		    str[i + 3] & 0x40))
			return -1;

		/*
		 * Just in case, check if there's a 5th character, which is
		 * forbidden by UTF-8
		 */
		if (OF_UNLIKELY(str[i] & 0x08))
			return -1;

		i += 3;
	}

	return (utf8 ? 1 : 0);
}

@implementation OFString
+ new
{
	return [[self alloc] init];
}

+ newFromCString: (const char*)str
{
	return [[self alloc] initFromCString: str];
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

- initFromCString: (const char*)str
{
	if ((self = [super init])) {
		if (str != NULL) {
			length = strlen(str);

			switch (check_utf8(str, length)) {
			case 1:
				is_utf8 = YES;
				break;
			case -1:
				[super free];
				@throw [OFInvalidEncodingException
				    newWithObject: self];
			}

			string = [self getMemWithSize: length + 1];
			memcpy(string, str, length + 1);
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

- (OFString*)clone
{
	return [OFString newFromCString: string];
}

- (OFString*)setTo: (OFString*)str
{
	[self free];
	return (self = [str clone]);
}

- (int)compareTo: (OFString*)str
{
	return strcmp(string, [str cString]);
}

- append: (OFString*)str
{
	return [self appendCString: [str cString]];
}

- appendCString: (const char*)str
{
	char   *newstr;
	size_t newlen, strlength;

	if (string == NULL) 
		return [self setTo: [OFString newFromCString: str]];

	strlength = strlen(str);

	switch (check_utf8(str, strlength)) {
	case 1:
		is_utf8 = YES;
		break;
	case -1:
		@throw [OFInvalidEncodingException newWithObject: self];
	}

	newlen = length + strlength;
	newstr = [self resizeMem: string
			  toSize: newlen + 1];

	memcpy(newstr + length, str, strlength + 1);

	length = newlen;
	string = newstr;

	return self;
}

- reverse
{
	size_t i, j, len = length / 2;

	/* We reverse all bytes and restore UTF-8 later, if necessary */
	for (i = 0, j = length - 1; i < len; i++, j--) {
		string[i] ^= string[j];
		string[j] ^= string[i];
		string[i] ^= string[j];
	}

	if (!is_utf8)
		return self;

	for (i = 0; i < length; i++) {
		/* ASCII */
		if (OF_LIKELY(~string[i] & 0x80))
			continue;

		/* A start byte can't happen first as we reversed everything */
		if (OF_UNLIKELY(string[i] & 0x40))
			@throw [OFInvalidEncodingException newWithObject: self];

		/* Next byte must not be ASCII */
		if (OF_UNLIKELY(length < i + 1 || ~string[i + 1] & 0x80))
			@throw [OFInvalidEncodingException newWithObject: self];

		/* Next byte is the start byte */
		if (OF_LIKELY(string[i + 1] & 0x40)) {
			string[i] ^= string[i + 1];
			string[i + 1] ^= string[i];
			string[i] ^= string[i + 1];

			i++;
			continue;
		}

		/* Second next byte must not be ASCII */
		if (OF_UNLIKELY(length < i + 2 || ~string[i + 2] & 0x80))
			@throw [OFInvalidEncodingException newWithObject: self];

		/* Second next byte is the start byte */
		if (OF_LIKELY(string[i + 2] & 0x40)) {
			string[i] ^= string[i + 2];
			string[i + 2] ^= string[i];
			string[i] ^= string[i + 2];

			i += 2;
			continue;
		}

		/* Third next byte must not be ASCII */
		if (OF_UNLIKELY(length < i + 3 || ~string[i + 3] & 0x80))
			@throw [OFInvalidEncodingException newWithObject: self];

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
		@throw [OFInvalidEncodingException newWithObject: self];
	}

	return self;
}

- upper
{
	size_t i = length;

	if (is_utf8)
		@throw [OFInvalidEncodingException newWithObject: self];

	while (i--) 
		string[i] = toupper(string[i]);

	return self;
}

- lower
{
	size_t i = length;

	if (is_utf8)
		@throw [OFInvalidEncodingException newWithObject: self];

	while (i--) 
		string[i] = tolower(string[i]);

	return self;
}
@end
