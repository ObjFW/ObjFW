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
	const char *string_ = string;
	char *retCString;
	size_t i;
	OFString *ret;

	/*
	 * Worst case: 3 times longer than before.
	 * Oh, and we can't use [self allocWithSize:] here as self might be a
	 * @"" literal.
	 */
	if ((retCString = malloc((length * 3) + 1)) == NULL)
		@throw [OFOutOfMemoryException newWithClass: isa
					      requestedSize: (length * 3) + 1];

	for (i = 0; *string_ != '\0'; string_++) {
		if (isalnum((int)*string_) || *string_ == '-' ||
		    *string_ == '_' || *string_ == '.' || *string_ == '~')
			retCString[i++] = *string_;
		else {
			uint8_t high, low;

			high = *string_ >> 4;
			low = *string_ & 0x0F;

			retCString[i++] = '%';
			retCString[i++] =
			    (high > 9 ? high - 10 + 'A' : high + '0');
			retCString[i++] =
			    (low  > 9 ? low  - 10 + 'A' : low  + '0');
		}
	}

	@try {
		ret = [OFString stringWithCString: retCString
					   length: i];
	} @finally {
		free(retCString);
	}

	return ret;
}

- (OFString*)stringByURLDecoding
{
	OFString *ret;
	const char *string_ = string;
	char *retCString;
	char byte = 0;
	int state = 0;
	size_t i;

	if ((retCString = malloc(length + 1)) == NULL)
		@throw [OFOutOfMemoryException newWithClass: isa
					      requestedSize: length + 1];

	for (i = 0; *string_; string_++) {
		switch (state) {
		case 0:
			if (*string_ == '%')
				state = 1;
			else if (*string_ == '+')
				retCString[i++] = ' ';
			else
				retCString[i++] = *string_;
			break;
		case 1:
		case 2:;
			uint8_t shift = (state == 1 ? 4  : 0);

			if (*string_ >= '0' && *string_ <= '9')
				byte += (*string_ - '0') << shift;
			else if (*string_ >= 'A' && *string_ <= 'F')
				byte += (*string_ - 'A' + 10) << shift;
			else if (*string_ >= 'a' && *string_ <= 'f')
				byte += (*string_ - 'a' + 10) << shift;
			else {
				free(retCString);
				@throw [OFInvalidEncodingException
				    newWithClass: isa];
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
		@throw [OFInvalidEncodingException newWithClass: isa];
	}

	@try {
		ret = [OFString stringWithCString: retCString];
	} @finally {
		free(retCString);
	}
	return ret;
}
@end
