/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#include <string.h>

#import "OFString.h"

#import "OFInvalidFormatException.h"
#import "OFUnknownXMLEntityException.h"

int _OFString_XMLUnescaping_reference;

static OF_INLINE OFString*
parseNumericEntity(const char *entity, size_t length)
{
	of_unichar_t c;
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

	if ((i = of_string_utf8_encode(c, buffer)) == 0)
		return nil;
	buffer[i] = 0;

	return [OFString stringWithUTF8String: buffer
				       length: i];
}

static OFString*
parseEntities(OFString *self, id (*lookup)(void*, OFString*, OFString*),
    void *context)
{
	OFMutableString *ret;
	void *pool;
	const char *string;
	size_t i, last, length;
	bool inEntity;

	ret = [OFMutableString string];

	pool = objc_autoreleasePoolPush();

	string = [self UTF8String];
	length = [self UTF8StringLength];

	last = 0;
	inEntity = false;

	for (i = 0; i < length; i++) {
		if (!inEntity && string[i] == '&') {
			[ret appendUTF8String: string + last
				       length: i - last];

			last = i + 1;
			inEntity = true;
		} else if (inEntity && string[i] == ';') {
			const char *entity = string + last;
			size_t entityLength = i - last;

			if (entityLength == 2 && memcmp(entity, "lt", 2) == 0)
				[ret appendCString: "<"
					  encoding: OF_STRING_ENCODING_ASCII
					    length: 1];
			else if (entityLength == 2 &&
			    memcmp(entity, "gt", 2) == 0)
				[ret appendCString: ">"
					  encoding: OF_STRING_ENCODING_ASCII
					    length: 1];
			else if (entityLength == 4 &&
			    memcmp(entity, "quot", 4) == 0)
				[ret appendCString: "\""
					  encoding: OF_STRING_ENCODING_ASCII
					    length: 1];
			else if (entityLength == 4 &&
			    memcmp(entity, "apos", 4) == 0)
				[ret appendCString: "'"
					  encoding: OF_STRING_ENCODING_ASCII
					    length: 1];
			else if (entityLength == 3 &&
			    memcmp(entity, "amp", 3) == 0)
				[ret appendCString: "&"
					  encoding: OF_STRING_ENCODING_ASCII
					    length: 1];
			else if (entity[0] == '#') {
				void *pool;
				OFString *tmp;

				pool = objc_autoreleasePoolPush();
				tmp = parseNumericEntity(entity,
				    entityLength);

				if (tmp == nil)
					@throw [OFInvalidFormatException
					    exception];

				[ret appendString: tmp];
				objc_autoreleasePoolPop(pool);
			} else {
				void *pool;
				OFString *name, *tmp;

				pool = objc_autoreleasePoolPush();

				name = [OFString
				    stringWithUTF8String: entity
						  length: entityLength];
				tmp = lookup(context, self, name);

				if (tmp == nil)
					@throw [OFUnknownXMLEntityException
					    exceptionWithEntityName: name];

				[ret appendString: tmp];
				objc_autoreleasePoolPop(pool);
			}

			last = i + 1;
			inEntity = false;
		}
	}

	if (inEntity)
		@throw [OFInvalidFormatException exception];

	[ret appendUTF8String: string + last
		       length: i - last];

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

	return [delegate        string: self
	    containsUnknownEntityNamed: entity];
}

#ifdef OF_HAVE_BLOCKS
static id
lookupUsingBlock(void *context, OFString *self, OFString *entity)
{
	of_string_xml_unescaping_block_t block = context;

	if (block == NULL)
		return nil;

	return block(self, entity);
}
#endif

@implementation OFString (XMLUnescaping)
- (OFString*)stringByXMLUnescaping
{
	return [self stringByXMLUnescapingWithDelegate: nil];
}

- (OFString*)stringByXMLUnescapingWithDelegate:
    (id <OFStringXMLUnescapingDelegate>)delegate
{
	return parseEntities(self, lookupUsingDelegate, delegate);
}

#ifdef OF_HAVE_BLOCKS
- (OFString*)stringByXMLUnescapingWithBlock:
    (of_string_xml_unescaping_block_t)block
{
	return parseEntities(self, lookupUsingBlock, block);
}
#endif
@end
