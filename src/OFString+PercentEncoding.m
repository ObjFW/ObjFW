/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFString+PercentEncoding.h"
#import "OFCharacterSet.h"

#import "OFInvalidFormatException.h"
#import "OFInvalidEncodingException.h"
#import "OFOutOfMemoryException.h"

/* Reference for static linking */
int _OFString_PercentEncoding_reference;

@implementation OFString (PercentEncoding)
- (OFString *)stringByAddingPercentEncodingWithAllowedCharacters:
    (OFCharacterSet *)allowedCharacters
{
	OFMutableString *ret = [OFMutableString string];
	void *pool = objc_autoreleasePoolPush();
	const OFUnichar *characters = self.characters;
	size_t length = self.length;
	bool (*characterIsMember)(id, SEL, OFUnichar) =
	    (bool (*)(id, SEL, OFUnichar))[allowedCharacters
	    methodForSelector: @selector(characterIsMember:)];

	for (size_t i = 0; i < length; i++) {
		OFUnichar c = characters[i];

		if (characterIsMember(allowedCharacters,
		    @selector(characterIsMember:), c))
			[ret appendCharacters: &c length: 1];
		else {
			char buffer[4];
			size_t bufferLen;

			if ((bufferLen = OFUTF8StringEncode(c, buffer)) == 0)
				@throw [OFInvalidEncodingException exception];

			for (size_t j = 0; j < bufferLen; j++) {
				unsigned char byte = buffer[j];
				unsigned char high = byte >> 4;
				unsigned char low = byte & 0x0F;
				char escaped[3];

				escaped[0] = '%';
				escaped[1] =
				    (high > 9 ? high - 10 + 'A' : high + '0');
				escaped[2] =
				    (low  > 9 ? low  - 10 + 'A' : low  + '0');

				[ret appendUTF8String: escaped length: 3];
			}
		}
	}

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFString *)stringByRemovingPercentEncoding
{
	void *pool = objc_autoreleasePoolPush();
	const char *string = self.UTF8String;
	size_t length = self.UTF8StringLength;
	char *retCString;
	char byte = 0;
	int state = 0;
	size_t i = 0;
	OFString *ret;

	retCString = OFAllocMemory(length + 1, 1);

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
				OFFreeMemory(retCString);
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
		OFFreeMemory(retCString);
		@throw [OFInvalidFormatException exception];
	}

	@try {
		retCString = OFResizeMemory(retCString, 1, i + 1);
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care if it fails, as we only made it smaller. */
	}

	@try {
		ret = [OFString stringWithUTF8StringNoCopy: retCString
						    length: i
					      freeWhenDone: true];
	} @catch (id e) {
		OFFreeMemory(retCString);
		@throw e;
	}

	return ret;
}
@end
