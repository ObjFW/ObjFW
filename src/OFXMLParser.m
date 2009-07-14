/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>

#import "OFXMLParser.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "OFMacros.h"

int _OFXMLParser_reference;

static OF_INLINE OFString*
parse_numeric_entity(char *entity, size_t length)
{
	uint32_t c;
	size_t i;
	char buf[4];

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
				c = (c * 0x10) + (entity[i] - '0');
			else if (entity[i] >= 'A' && entity[i] <= 'F')
				c = (c * 0x10) + (entity[i] - 'A' + 10);
			else if (entity[i] >= 'a' && entity[i] <= 'f')
				c = (c * 0x10) + (entity[i] - 'A' + 10);
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

	if ((i = of_string_unicode_to_utf8(c, buf)) == 0)
		return nil;

	return [OFString stringWithCString: buf
				 andLength: i];
}

@implementation OFXMLParser
+ xmlParser
{
	return [[[self alloc] init] autorelease];
}

- (id)delegate
{
	return [[delegate retain] autorelease];
}

- setDelegate: (OFObject <OFXMLParserDelegate>*)delegate_
{
	[delegate release];
	delegate = [delegate_ retain];

	return self;
}
@end

@implementation OFString (OFXMLUnescaping)
- stringByXMLUnescaping
{
	return [self stringByXMLUnescapingWithHandler: nil];
}

- stringByXMLUnescapingWithHandler: (OFObject <OFXMLUnescapingDelegate>*)h
{
	size_t i, last;
	BOOL in_entity;
	OFString *ret;

	last = 0;
	in_entity = NO;
	ret = [OFMutableString string];

	for (i = 0; i < length; i++) {
		if (!in_entity && string[i] == '&') {
			[ret appendCStringWithoutUTF8Checking: string + last
						    andLength: i - last];

			last = i + 1;
			in_entity = YES;
		} else if (in_entity && string[i] == ';') {
			char *entity = string + last;
			size_t len = i - last;

			if (len == 2 && !memcmp(entity, "lt", 2))
				[ret appendString: @"<"];
			else if (len == 2 && !memcmp(entity, "gt", 2))
				[ret appendString: @">"];
			else if (len == 4 && !memcmp(entity, "quot", 4))
				[ret appendString: @"\""];
			else if (len == 4 && !memcmp(entity, "apos", 4))
				[ret appendString: @"'"];
			else if (len == 3 && !memcmp(entity, "amp", 3))
				[ret appendString: @"&"];
			else if (entity[0] == '#') {
				OFAutoreleasePool *pool;
				OFString *tmp;

				pool = [[OFAutoreleasePool alloc] init];
				tmp = parse_numeric_entity(entity, len);

				if (tmp == nil)
					@throw [OFInvalidEncodingException
					    newWithClass: isa];

				[ret appendString: tmp];
				[pool release];
			} else if (h != nil) {
				OFAutoreleasePool *pool;
				OFString *n, *tmp;

				pool = [[OFAutoreleasePool alloc] init];

				n = [OFString stringWithCString: entity
						      andLength: len];
				tmp = [h foundUnknownEntityNamed: n];

				if (tmp == nil)
					@throw [OFInvalidEncodingException
					    newWithClass: isa];

				[ret appendString: tmp];
				[pool release];
			} else
				@throw [OFInvalidEncodingException
				    newWithClass: isa];

			last = i + 1;
			in_entity = NO;
		}
	}

	if (in_entity)
		@throw [OFInvalidEncodingException newWithClass: isa];

	[ret appendCStringWithoutUTF8Checking: string + last
				    andLength: i - last];

	return ret;
}
@end
