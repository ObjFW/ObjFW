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
transform_string(OFString *cache, OFObject <OFXMLUnescapingDelegate> *handler)
{
	/* TODO: Support for xml:space */

	[cache removeLeadingAndTrailingWhitespaces];
	return [cache stringByXMLUnescapingWithHandler: handler];
}

static OF_INLINE OFString*
parse_numeric_entity(const char *entity, size_t length)
{
	uint32_t c;
	size_t i;
	char buf[5];

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
	buf[i] = 0;

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
		previous = [[OFMutableArray alloc] init];
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
	[attr_prefix release];
	[previous release];

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

				if ([cache cStringLength] > 0) {
					OFString *str;

					pool = [[OFAutoreleasePool alloc] init];
					str = transform_string(cache, self);
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
			} else if(buf[i] == '!') {
				last = i + 1;
				state = OF_XMLPARSER_IN_COMMENT_1;
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
				cache_len = [cache cStringLength];

				if ((tmp = memchr(cache_c, ':',
				    cache_len)) != NULL) {
					name = [[OFString alloc]
					    initWithCString: tmp + 1
						     length: cache_len - (tmp -
							     cache_c) - 1];
					prefix = [[OFString alloc]
					    initWithCString: cache_c
						     length: tmp - cache_c];
				} else {
					name = [cache copy];
					prefix = nil;
				}

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
					else
						[previous addObject:
						    [[cache copy] autorelease]];

					[pool release];

					[name release];
					[prefix release];
					[ns release];

					state = (buf[i] == '/'
					    ? OF_XMLPARSER_EXPECT_CLOSE
					    : OF_XMLPARSER_OUTSIDE_TAG);
				} else
					state = OF_XMLPARSER_IN_TAG;

				[cache setToCString: ""];
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
				cache_len = [cache cStringLength];

				if ((tmp = memchr(cache_c, ':',
				    cache_len)) != NULL) {
					name = [[OFString alloc]
					    initWithCString: tmp + 1
						     length: cache_len - (tmp -
							     cache_c) - 1];
					prefix = [[OFString alloc]
					    initWithCString: cache_c
						     length: tmp - cache_c];
				} else {
					name = [cache copy];
					prefix = nil;
				}

				if (![[previous lastObject] isEqual: cache])
					@throw [OFMalformedXMLException
					    newWithClass: isa];
				[previous removeNObjects: 1];

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
				else if (prefix != nil) {
					OFString *str = [OFString
					    stringWithFormat: @"%s:%s",
							      [prefix cString],
							      [name cString]];
					[previous addObject: str];
				} else
					[previous addObject: name];

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
				const char *cache_c, *tmp;
				size_t cache_len;

				len = i - last;
				if (len > 0)
					[cache appendCString: buf + last
						  withLength: len];

				cache_c = [cache cString];
				cache_len = [cache cStringLength];

				if ((tmp = memchr(cache_c, ':',
				    cache_len)) != NULL ) {
					attr_name = [[OFString alloc]
					    initWithCString: tmp + 1
						     length: cache_len - (tmp -
							     cache_c) - 1];
					attr_prefix = [[OFString alloc]
					    initWithCString: cache_c
						     length: tmp - cache_c];
				} else {
					attr_name = [cache copy];
					attr_prefix = nil;
				}

				[cache setToCString: ""];

				last = i + 1;
				state = OF_XMLPARSER_EXPECT_DELIM;
			}
			break;

		/* Expecting delimiter */
		case OF_XMLPARSER_EXPECT_DELIM:
			if (buf[i] != '\'' && buf[i] != '"')
				@throw [OFMalformedXMLException
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
					attrs = [[OFMutableArray alloc] init];

				pool = [[OFAutoreleasePool alloc] init];
				attr_val = [cache
				    stringByXMLUnescapingWithHandler: self];
				[attrs addObject: [OFXMLAttribute
				    attributeWithName: attr_name
					       prefix: attr_prefix
					    namespace: nil
					  stringValue: attr_val]];
				[pool release];

				[cache setToCString: ""];
				[attr_name release];
				[attr_prefix release];
				attr_name = nil;
				attr_prefix = nil;

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
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			break;

		/* Expecting closing '>' or space */
		case OF_XMLPARSER_EXPECT_SPACE_OR_CLOSE:
			if (buf[i] == '>') {
				last = i + 1;
				state = OF_XMLPARSER_OUTSIDE_TAG;
			} else if (buf[i] != ' ')
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			break;

		/* Comment */
		case OF_XMLPARSER_IN_COMMENT_1:
		case OF_XMLPARSER_IN_COMMENT_2:
			if (buf[i] != '-')
				@throw [OFMalformedXMLException
				    newWithClass: isa];
			last = i + 1;
			state++;
			break;
		case OF_XMLPARSER_IN_COMMENT_3:
			if (buf[i] == '-')
				state = OF_XMLPARSER_IN_COMMENT_4;
			break;
		case OF_XMLPARSER_IN_COMMENT_4:
			if (buf[i] == '-') {
				size_t cache_len;

				[cache appendCString: buf + last
					  withLength: i - last];
				cache_len = [cache cStringLength];

				pool = [[OFAutoreleasePool alloc] init];
				[cache removeCharactersFromIndex: cache_len - 1
							 toIndex: cache_len];
				[cache removeLeadingAndTrailingWhitespaces];
				[delegate xmlParser: self
				       foundComment: cache];
				[pool release];

				[cache setToCString: ""];

				last = i + 1;
				state = OF_XMLPARSER_EXPECT_CLOSE;
			} else
				state = OF_XMLPARSER_IN_COMMENT_3;

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

@implementation OFObject (OFXMLParserDelegate)
-     (void)xmlParser: (OFXMLParser*)parser
  didStartTagWithName: (OFString*)name
	       prefix: (OFString*)prefix
	    namespace: (OFString*)ns
	   attributes: (OFArray*)attrs
{
}

-   (void)xmlParser: (OFXMLParser*)parser
  didEndTagWithName: (OFString*)name
	     prefix: (OFString*)prefix
	  namespace: (OFString*)ns
{
}

- (void)xmlParser: (OFXMLParser*)parser
      foundString: (OFString*)string
{
}

- (void)xmlParser: (OFXMLParser*)parser
     foundComment: (OFString*)comment
{
}

-    (OFString*)xmlParser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity
{
	return nil;
}
@end
