/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#include <string.h>

#import "OFString+XMLUnescaping.h"
#import "OFString+Private.h"

#import "OFInvalidFormatException.h"
#import "OFUnknownXMLEntityException.h"

int _OFString_XMLUnescaping_reference;

static OF_INLINE OFString *
parseNumericEntity(const char *entity, size_t length)
{
	OFUnichar c;
	size_t i;
	char buffer[5];

	if (length == 1 || *entity != '#')
		return nil;

	c = 0;
	entity++;
	length--;

	if (entity[0] == 'x') {
		if (length == 1)
			return nil;

		entity++;
		length--;

		for (i = 0; i < length; i++) {
			if (entity[i] >= '0' && entity[i] <= '9')
				c = (c << 4) | (entity[i] - '0');
			else if (entity[i] >= 'A' && entity[i] <= 'F')
				c = (c << 4) | (entity[i] - 'A' + 10);
			else if (entity[i] >= 'a' && entity[i] <= 'f')
				c = (c << 4) | (entity[i] - 'a' + 10);
			else
				return nil;
		}
	} else {
		for (i = 0; i < length; i++) {
			if (entity[i] >= '0' && entity[i] <= '9')
				c = (c * 10) + (entity[i] - '0');
			else
				return nil;
		}
	}

	if ((i = _OFUTF8StringEncode(c, buffer)) == 0)
		return nil;
	buffer[i] = 0;

	return [OFString stringWithUTF8String: buffer length: i];
}

static OFString *
parseEntities(OFString *self, id (*lookup)(void *, OFString *, OFString *),
    void *context)
{
	OFMutableString *ret;
	void *pool;
	const char *string;
	size_t i, last, length;
	bool inEntity;

	ret = [OFMutableString string];

	pool = objc_autoreleasePoolPush();

	string = self.UTF8String;
	length = self.UTF8StringLength;

	last = 0;
	inEntity = false;

	for (i = 0; i < length; i++) {
		if (!inEntity && string[i] == '&') {
			[ret appendUTF8String: string + last length: i - last];
			last = i + 1;
			inEntity = true;
		} else if (inEntity && string[i] == ';') {
			const char *entity = string + last;
			size_t entityLength = i - last;

			if (entityLength == 2 && memcmp(entity, "lt", 2) == 0)
				[ret appendCString: "<"
					  encoding: OFStringEncodingASCII
					    length: 1];
			else if (entityLength == 2 &&
			    memcmp(entity, "gt", 2) == 0)
				[ret appendCString: ">"
					  encoding: OFStringEncodingASCII
					    length: 1];
			else if (entityLength == 4 &&
			    memcmp(entity, "quot", 4) == 0)
				[ret appendCString: "\""
					  encoding: OFStringEncodingASCII
					    length: 1];
			else if (entityLength == 4 &&
			    memcmp(entity, "apos", 4) == 0)
				[ret appendCString: "'"
					  encoding: OFStringEncodingASCII
					    length: 1];
			else if (entityLength == 3 &&
			    memcmp(entity, "amp", 3) == 0)
				[ret appendCString: "&"
					  encoding: OFStringEncodingASCII
					    length: 1];
			else if (entity[0] == '#') {
				void *pool2;
				OFString *tmp;

				pool2 = objc_autoreleasePoolPush();
				tmp = parseNumericEntity(entity,
				    entityLength);

				if (tmp == nil)
					@throw [OFInvalidFormatException
					    exception];

				[ret appendString: tmp];

				objc_autoreleasePoolPop(pool2);
			} else {
				void *pool2;
				OFString *name, *tmp;

				pool2 = objc_autoreleasePoolPush();

				name = [OFString
				    stringWithUTF8String: entity
						  length: entityLength];
				tmp = lookup(context, self, name);

				if (tmp == nil)
					@throw [OFUnknownXMLEntityException
					    exceptionWithEntityName: name];

				[ret appendString: tmp];

				objc_autoreleasePoolPop(pool2);
			}

			last = i + 1;
			inEntity = false;
		}
	}

	if (inEntity)
		@throw [OFInvalidFormatException exception];

	[ret appendUTF8String: string + last length: i - last];
	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

static id
lookupUsingDelegate(void *context, OFString *self, OFString *entity)
{
	id <OFStringXMLUnescapingDelegate> delegate = context;

	if (delegate == nil)
		return nil;

	return [delegate string: self containsUnknownEntityNamed: entity];
}

#ifdef OF_HAVE_BLOCKS
static id
lookupUsingBlock(void *context, OFString *self, OFString *entity)
{
	OFStringXMLUnescapingBlock block = context;

	if (block == NULL)
		return nil;

	return block(self, entity);
}
#endif

@implementation OFString (XMLUnescaping)
- (OFString *)stringByXMLUnescaping
{
	return [self stringByXMLUnescapingWithDelegate: nil];
}

- (OFString *)stringByXMLUnescapingWithDelegate:
    (id <OFStringXMLUnescapingDelegate>)delegate
{
	return parseEntities(self, lookupUsingDelegate, delegate);
}

#ifdef OF_HAVE_BLOCKS
- (OFString *)stringByXMLUnescapingWithBlock: (OFStringXMLUnescapingBlock)block
{
	return parseEntities(self, lookupUsingBlock, block);
}
#endif
@end
