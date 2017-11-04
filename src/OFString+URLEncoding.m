/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#include <stdlib.h>
#include <string.h>

#import "OFString+URLEncoding.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"

/* Reference for static linking */
int _OFString_URLEncoding_reference;

@implementation OFString (URLEncoding)
- (OFString *)stringByURLEncoding
{
	return [self stringByURLEncodingWithAllowedCharacters:
	    "-._~!$&'()*+,;="];
}

- (OFString *)stringByURLEncodingWithAllowedCharacters: (const char *)allowed
{
	void *pool = objc_autoreleasePoolPush();
	const char *string = [self UTF8String];
	size_t length = [self UTF8StringLength];
	char *retCString, *retCString2;
	size_t i = 0;

	/*
	 * Worst case: 3 times longer than before.
	 * Oh, and we can't use [self allocWithSize:] here as self might be a
	 * @"" literal.
	 */
	if ((retCString = malloc(length * 3 + 1)) == NULL)
		@throw [OFOutOfMemoryException exceptionWithRequestedSize:
		    length * 3 + 1];

	while (length--) {
		unsigned char c = *string++;

		if (of_ascii_isalnum(c) || strchr(allowed, c) != NULL)
			retCString[i++] = c;
		else {
			unsigned char high, low;

			high = c >> 4;
			low = c & 0x0F;

			retCString[i++] = '%';
			retCString[i++] =
			    (high > 9 ? high - 10 + 'A' : high + '0');
			retCString[i++] =
			    (low  > 9 ? low  - 10 + 'A' : low  + '0');
		}
	}
	retCString[i] = '\0';

	objc_autoreleasePoolPop(pool);

	/* We don't care if it fails, as we only made it smaller. */
	if ((retCString2 = realloc(retCString, i + 1)) == NULL)
		retCString2 = retCString;

	return [OFString stringWithUTF8StringNoCopy: retCString2
					     length: i
				       freeWhenDone: true];
}

- (OFString *)stringByURLDecoding
{
	void *pool = objc_autoreleasePoolPush();
	const char *string = [self UTF8String];
	size_t length = [self UTF8StringLength];
	char *retCString, *retCString2;
	char byte = 0;
	int state = 0;
	size_t i = 0;

	if ((retCString = malloc(length + 1)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: length + 1];

	while (length--) {
		char c = *string++;

		switch (state) {
		case 0:
			if (c == '%')
				state = 1;
			else
				retCString[i++] = c;
			break;
		case 1:
		case 2:;
			uint8_t shift = (state == 1 ? 4 : 0);

			if (c >= '0' && c <= '9')
				byte += (c - '0') << shift;
			else if (c >= 'A' && c <= 'F')
				byte += (c - 'A' + 10) << shift;
			else if (c >= 'a' && c <= 'f')
				byte += (c - 'a' + 10) << shift;
			else {
				free(retCString);
				@throw [OFInvalidFormatException exception];
			}

			if (++state == 3) {
				retCString[i++] = byte;
				state = 0;
				byte = 0;
			}

			break;
		}
	}
	retCString[i] = '\0';

	objc_autoreleasePoolPop(pool);

	if (state != 0) {
		free(retCString);
		@throw [OFInvalidFormatException exception];
	}

	/* We don't care if it fails, as we only made it smaller. */
	if ((retCString2 = realloc(retCString, i + 1)) == NULL)
		retCString2 = retCString;

	return [OFString stringWithUTF8StringNoCopy: retCString2
					     length: i
				       freeWhenDone: true];
}
@end
