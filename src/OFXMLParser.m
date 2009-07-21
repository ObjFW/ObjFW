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
parse_numeric_entity(const char *entity, size_t length)
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
				c = (c << 4) + (entity[i] - '0');
			else if (entity[i] >= 'A' && entity[i] <= 'F')
				c = (c << 4) + (entity[i] - 'A' + 10);
			else if (entity[i] >= 'a' && entity[i] <= 'f')
				c = (c << 4) + (entity[i] - 'A' + 10);
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
				    length: i];
}

@implementation OFXMLParser
+ xmlParser
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	@try {
		cache = [[OFMutableString alloc] init];
	} @catch (OFException *e) {
		/* We can't use [super dealloc] on OS X here. Compiler bug? */
		[self dealloc];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[delegate release];

	[cache release];
	[name release];
	[prefix release];
	[ns release];
	[attrs release];
	[attr_name release];

	[super dealloc];
}

- (id)delegate
{
	return [[delegate retain] autorelease];
}

- setDelegate: (OFObject <OFXMLParserDelegate>*)delegate_
{
	[delegate_ retain];
	[delegate release];
	delegate = delegate_;

	return self;
}

- parseBuffer: (const char*)buf
     withSize: (size_t)size
{
	OFAutoreleasePool *pool;
	size_t i, last, len;

	last = 0;

	for (i = 0; i < size; i++) {
		switch (state) {
		/* Not in a tag */
		case OF_XMLPARSER_OUTSIDE_TAG:
			if (buf[i] == '<') {
				len = i - last;

				if (len > 0)
					[cache appendCString: buf + last
						  withLength: len];

				if ([cache length] > 0) {
					OFString *str;

					pool = [[OFAutoreleasePool alloc] init];
					str = [cache
					    stringByXMLUnescapingWithHandler:
					    self];

					[delegate xmlParser: self
						foundString: str];

					[pool release];
				}

				[cache setToCString: ""];

				last = i + 1;
				state = OF_XMLPARSER_TAG_OPENED;
			}
			break;

		/* Tag was just opened */
		case OF_XMLPARSER_TAG_OPENED:
			if (buf[i] == '/') {
				last = i + 1;
				state = OF_XMLPARSER_IN_CLOSE_TAG_NAME;
			} else {
				state = OF_XMLPARSER_IN_TAG_NAME;
				i--;
			}
			break;

		/* Inside a tag, no name yet */
		case OF_XMLPARSER_IN_TAG_NAME:
			if (buf[i] == ' ' || buf[i] == '>' || buf[i] == '/') {
				const char *cache_c, *tmp;
				size_t cache_len;

				len = i - last;
				if (len > 0)
					[cache appendCString: buf + last
						  withLength: len];
				cache_c = [cache cString];
				cache_len = [cache length];

				if ((tmp = memchr(cache_c, ':',
				    cache_len)) != NULL) {
					prefix = [[OFString alloc]
					    initWithCString: cache_c
						     length: tmp - cache_c];
					name = [[OFString alloc]
					    initWithCString: tmp + 1
						     length: cache_len - (tmp -
							     cache_c) - 1];
				} else {
					prefix = nil;
					name = [[OFString alloc]
					    initWithCString: cache_c
						     length: cache_len];
				}

				[cache setToCString: ""];

				if (buf[i] == '>' || buf[i] == '/') {
					pool = [[OFAutoreleasePool alloc] init];

					[delegate xmlParser: self
					didStartTagWithName: name
						     prefix: prefix
						  namespace: ns
						 attributes: nil];

					if (buf[i] == '/')
						[delegate xmlParser: self
						  didEndTagWithName: name
							     prefix: prefix
							  namespace: ns];

					[pool release];

					[name release];
					[prefix release];
					[ns release];

					state = (buf[i] == '/'
					    ? OF_XMLPARSER_EXPECT_CLOSE
					    : OF_XMLPARSER_OUTSIDE_TAG);
				} else
					state = OF_XMLPARSER_IN_TAG;

				last = i + 1;
			}
			break;

		/* Inside a close tag, no name yet */
		case OF_XMLPARSER_IN_CLOSE_TAG_NAME:
			if (buf[i] == ' ' || buf[i] == '>') {
				const char *cache_c, *tmp;
				size_t cache_len;

				len = i - last;
				if (len > 0)
					[cache appendCString: buf + last
						  withLength: len];
				cache_c = [cache cString];
				cache_len = [cache length];

				if ((tmp = memchr(cache_c, ':',
				    cache_len)) != NULL) {
					prefix = [[OFString alloc]
					    initWithCString: cache_c
						     length: tmp - cache_c];
					name = [[OFString alloc]
					    initWithCString: tmp + 1
						     length: cache_len - (tmp -
							     cache_c) - 1];
				} else {
					prefix = nil;
					name = [[OFString alloc]
					    initWithCString: cache_c
						     length: cache_len];
				}

				[cache setToCString: ""];

				pool = [[OFAutoreleasePool alloc] init];

				[delegate xmlParser: self
				  didEndTagWithName: name
					     prefix: prefix
					  namespace: ns];

				[pool release];

				[name release];
				[prefix release];
				[ns release];

				last = i + 1;
				state = (buf[i] == ' '
				    ? OF_XMLPARSER_EXPECT_SPACE_OR_CLOSE
				    : OF_XMLPARSER_OUTSIDE_TAG);
			}
			break;

		/* Inside a tag, name found */
		case OF_XMLPARSER_IN_TAG:
			if (buf[i] == '>' || buf[i] == '/') {
				pool = [[OFAutoreleasePool alloc] init];

				[delegate xmlParser: self
				didStartTagWithName: name
					     prefix: prefix
					  namespace: ns
					 attributes: attrs];

				if (buf[i] == '/')
					[delegate xmlParser: self
					  didEndTagWithName: name
						     prefix: prefix
						  namespace: ns];

				[pool release];

				[name release];
				[prefix release];
				[ns release];
				[attrs release];

				attrs = nil;

				last = i + 1;
				state = (buf[i] == '/'
				    ? OF_XMLPARSER_EXPECT_CLOSE
				    : OF_XMLPARSER_OUTSIDE_TAG);
			} else if (buf[i] != ' ') {
				last = i;
				state = OF_XMLPARSER_IN_ATTR_NAME;
				i--;
			}
			break;

		/* Looking for attribute name */
		case OF_XMLPARSER_IN_ATTR_NAME:
			if (buf[i] == '=') {
				len = i - last;
				if (len > 0)
					[cache appendCString: buf + last
						  withLength: len];

				attr_name = [cache copy];
				[cache setToCString: ""];

				last = i + 1;
				state = OF_XMLPARSER_EXPECT_DELIM;
			}
			break;

		/* Expecting delimiter */
		case OF_XMLPARSER_EXPECT_DELIM:
			if (buf[i] != '\'' && buf[i] != '"')
				@throw [OFInvalidEncodingException
				    newWithClass: isa];

			delim = buf[i];
			last = i + 1;
			state = OF_XMLPARSER_IN_ATTR_VALUE;
			break;

		/* Looking for attribute value */
		case OF_XMLPARSER_IN_ATTR_VALUE:
			if (buf[i] == delim) {
				OFString *attr_val;

				len = i - last;
				if (len > 0)
					[cache appendCString: buf + last
						  withLength: len];

				if (attrs == nil)
					attrs =
					    [[OFMutableDictionary alloc] init];

				pool = [[OFAutoreleasePool alloc] init];
				attr_val = [cache
				    stringByXMLUnescapingWithHandler: self];
				[attrs setObject: attr_val
					  forKey: attr_name];
				[pool release];

				[cache setToCString: ""];
				[attr_name release];

				last = i + 1;
				state = OF_XMLPARSER_IN_TAG;
			}
			break;

		/* Expecting closing '>' */
		case OF_XMLPARSER_EXPECT_CLOSE:
			if (buf[i] == '>') {
				last = i + 1;
				state = OF_XMLPARSER_OUTSIDE_TAG;
			} else
				@throw [OFInvalidEncodingException
				    newWithClass: isa];
			break;

		/* Expecting closing '>' or space */
		case OF_XMLPARSER_EXPECT_SPACE_OR_CLOSE:
			if (buf[i] == '>') {
				last = i + 1;
				state = OF_XMLPARSER_OUTSIDE_TAG;
			} else if (buf[i] != ' ')
				@throw [OFInvalidEncodingException
				    newWithClass: isa];
			break;
		}
	}

	len = size - last;
	/* In OF_XMLPARSER_IN_TAG, there can be only spaces */
	if (len > 0 && state != OF_XMLPARSER_IN_TAG)
		[cache appendCString: buf + last
			  withLength: len];

	return self;
}

- (OFString*)foundUnknownEntityNamed: (OFString*)entity
{
	return [delegate xmlParser: self
	   foundUnknownEntityNamed: entity];
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
						    length: i - last];

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
							 length: len];
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
				       length: i - last];

	return ret;
}
@end
