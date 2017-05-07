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

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#import "OFString.h"

#import "OFOutOfMemoryException.h"

int _OFString_XMLEscaping_reference;

@implementation OFString (XMLEscaping)
- (OFString *)stringByXMLEscaping
{
	void *pool = objc_autoreleasePoolPush();
	char *retCString;
	const char *string, *append;
	size_t length, retLength, appendLen;
	size_t j;
	OFString *ret;

	string = [self UTF8String];
	length = [self UTF8StringLength];

	j = 0;
	retLength = length;

	/*
	 * We can't use allocMemoryWithSize: here as it might be a @"" literal
	 */
	if ((retCString = malloc(retLength)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: retLength];

	for (size_t i = 0; i < length; i++) {
		switch (string[i]) {
		case '<':
			append = "&lt;";
			appendLen = 4;
			break;
		case '>':
			append = "&gt;";
			appendLen = 4;
			break;
		case '"':
			append = "&quot;";
			appendLen = 6;
			break;
		case '\'':
			append = "&apos;";
			appendLen = 6;
			break;
		case '&':
			append = "&amp;";
			appendLen = 5;
			break;
		case '\r':
			append = "&#xD;";
			appendLen = 5;
			break;
		default:
			append = NULL;
			appendLen = 0;
		}

		if (append != NULL) {
			char *newRetCString;

			if ((newRetCString = realloc(retCString,
			    retLength + appendLen)) == NULL) {
				free(retCString);
				@throw [OFOutOfMemoryException
				     exceptionWithRequestedSize: retLength +
								 appendLen];
			}
			retCString = newRetCString;
			retLength += appendLen - 1;

			memcpy(retCString + j, append, appendLen);
			j += appendLen;
		} else
			retCString[j++] = string[i];
	}
	assert(j == retLength);

	objc_autoreleasePoolPop(pool);

	@try {
		ret = [OFString stringWithUTF8String: retCString
					      length: retLength];
	} @finally {
		free(retCString);
	}
	return ret;
}
@end
