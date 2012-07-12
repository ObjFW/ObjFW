/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#import "OFString+URLEncoding.h"

#import "OFInvalidEncodingException.h"
#import "OFOutOfMemoryException.h"

/* Reference for static linking */
int _OFString_URLEncoding_reference;

@implementation OFString (URLEncoding)
- (OFString*)stringByURLEncoding
{
	const char *string = [self UTF8String];
	char *retCString;
	size_t i;
	OFString *ret;

	/*
	 * Worst case: 3 times longer than before.
	 * Oh, and we can't use [self allocWithSize:] here as self might be a
	 * @"" literal.
	 */
	if ((retCString = malloc(([self UTF8StringLength] * 3) + 1)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithClass: [self class]
			 requestedSize: ([self UTF8StringLength] * 3) + 1];

	for (i = 0; *string != '\0'; string++) {
		if (isalnum((int)*string) || *string == '-' || *string == '_' ||
		    *string == '.' || *string == '~')
			retCString[i++] = *string;
		else {
			uint8_t high, low;

			high = *string >> 4;
			low = *string & 0x0F;

			retCString[i++] = '%';
			retCString[i++] =
			    (high > 9 ? high - 10 + 'A' : high + '0');
			retCString[i++] =
			    (low  > 9 ? low  - 10 + 'A' : low  + '0');
		}
	}

	@try {
		ret = [OFString stringWithUTF8String: retCString
					      length: i];
	} @finally {
		free(retCString);
	}

	return ret;
}

- (OFString*)stringByURLDecoding
{
	OFString *ret;
	const char *string = [self UTF8String];
	char *retCString;
	char byte = 0;
	int state = 0;
	size_t i;

	if ((retCString = malloc([self UTF8StringLength] + 1)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithClass: [self class]
			 requestedSize: [self UTF8StringLength] + 1];

	for (i = 0; *string; string++) {
		switch (state) {
		case 0:
			if (*string == '%')
				state = 1;
			else if (*string == '+')
				retCString[i++] = ' ';
			else
				retCString[i++] = *string;
			break;
		case 1:
		case 2:;
			uint8_t shift = (state == 1 ? 4  : 0);

			if (*string >= '0' && *string <= '9')
				byte += (*string - '0') << shift;
			else if (*string >= 'A' && *string <= 'F')
				byte += (*string - 'A' + 10) << shift;
			else if (*string >= 'a' && *string <= 'f')
				byte += (*string - 'a' + 10) << shift;
			else {
				free(retCString);
				@throw [OFInvalidEncodingException
				    exceptionWithClass: [self class]];
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

	if (state != 0) {
		free(retCString);
		@throw [OFInvalidEncodingException
		    exceptionWithClass: [self class]];
	}

	@try {
		ret = [OFString stringWithUTF8String: retCString
					      length: i];
	} @finally {
		free(retCString);
	}
	return ret;
}
@end
