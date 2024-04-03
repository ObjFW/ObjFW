/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

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

	string = self.UTF8String;
	length = self.UTF8StringLength;

	j = 0;
	retLength = length;
	retCString = OFAllocMemory(retLength, 1);

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
			@try {
				retCString = OFResizeMemory(retCString, 1,
				    retLength + appendLen);
			} @catch (id e) {
				OFFreeMemory(retCString);
				@throw e;
			}
			retLength += appendLen - 1;

			memcpy(retCString + j, append, appendLen);
			j += appendLen;
		} else
			retCString[j++] = string[i];
	}
	OFAssert(j == retLength);

	objc_autoreleasePoolPop(pool);

	@try {
		ret = [OFString stringWithUTF8String: retCString
					      length: retLength];
	} @finally {
		OFFreeMemory(retCString);
	}
	return ret;
}
@end
