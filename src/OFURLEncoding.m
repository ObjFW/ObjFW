/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#import "OFURLEncoding.h"
#import "OFExceptions.h"

/* Reference for static linking */
int _OFURLEncoding_reference;

@implementation OFString (OFURLEncoding)
- (OFString*)stringByURLEncoding
{
	const char *s;
	char *ret_c;
	size_t i;
	OFString *ret;

	s = string;

	/*
	 * Worst case: 3 times longer than before.
	 * Oh, and we can't use [self allocWithSize:] here as self might be a
	 * @"" literal.
	 */
	if ((ret_c = malloc((length * 3) + 1)) == NULL)
		@throw [OFOutOfMemoryException newWithClass: isa
						       size: (length * 3) + 1];

	for (i = 0; *s != '\0'; s++) {
		if (isalnum((int)*s) || *s == '-' || *s == '_' || *s == '.' ||
		    *s == '~')
			ret_c[i++] = *s;
		else {
			uint8_t high, low;

			high = *s >> 4;
			low = *s & 0x0F;

			ret_c[i++] = '%';
			ret_c[i++] = (high > 9 ? high - 10 + 'A' : high + '0');
			ret_c[i++] = (low  > 9 ? low  - 10 + 'A' : low  + '0');
		}
	}

	@try {
		ret = [OFString stringWithCString: ret_c
					   length: i];
	} @finally {
		free(ret_c);
	}

	return ret;
}

- (OFString*)stringByURLDecoding
{
	const char *s;
	char *ret_c, c;
	size_t i;
	int st;
	OFString *ret;

	s = string;

	if ((ret_c = malloc(length + 1)) == NULL)
		@throw [OFOutOfMemoryException newWithClass: isa
						       size: length + 1];

	for (st = 0, i = 0, c = 0; *s; s++) {
		switch (st) {
		case 0:
			if (*s == '%')
				st = 1;
			else if (*s == '+')
				ret_c[i++] = ' ';
			else
				ret_c[i++] = *s;
			break;
		case 1:
		case 2:
			if (*s >= '0' && *s <= '9')
				c += (*s - '0') << (st == 1 ? 4 : 0);
			else if (*s >= 'A' && *s <= 'F')
				c += (*s - 'A' + 10) << (st == 1 ? 4 : 0);
			else if (*s >= 'a' && *s <= 'f')
				c += (*s - 'a' + 10) << (st == 1 ? 4 : 0);
			else {
				free(ret_c);
				@throw [OFInvalidEncodingException
				    newWithClass: isa];
			}

			if (++st == 3) {
				ret_c[i++] = c;
				st = 0;
				c = 0;
			}

			break;
		}
	}
	ret_c[i] = '\0';

	if (st) {
		free(ret_c);
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	@try {
		ret = [OFString stringWithCString: ret_c];
	} @finally {
		free(ret_c);
	}
	return ret;
}
@end
