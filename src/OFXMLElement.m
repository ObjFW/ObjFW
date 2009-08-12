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

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

int _OFXMLElement_reference;

@implementation OFXMLAttribute
+ attributeWithName: (OFString*)name_
	     prefix: (OFString*)prefix_
	  namespace: (OFString*)ns_
	stringValue: (OFString*)value_
{
	return [[[self alloc] initWithName: name_
				    prefix: prefix_
				 namespace: ns_
			       stringValue: value_] autorelease];
}

- initWithName: (OFString*)name_
	prefix: (OFString*)prefix_
     namespace: (OFString*)ns_
   stringValue: (OFString*)value_
{
	self = [super init];

	name = [name_ copy];
	prefix = [prefix_ copy];
	ns = [ns_ copy];
	value = [value_ copy];

	return self;
}

- (void)dealloc
{
	[name release];
	[prefix release];
	[ns release];
	[value release];

	[super dealloc];
}

- (OFString*)name
{
	return [[name copy] autorelease];
}

- (OFString*)prefix
{
	return [[prefix copy] autorelease];
}

- (OFString*)namespace
{
	return [[ns copy] autorelease];
}

- (OFString*)stringValue
{
	return [[value copy] autorelease];
}
@end

@implementation OFXMLElement
+ elementWithName: (OFString*)name_
{
	return [[[self alloc] initWithName: name_] autorelease];
}

+ elementWithName: (OFString*)name_
      stringValue: (OFString*)stringval_
{
	return [[[self alloc] initWithName: name_
			       stringValue: stringval_] autorelease];
}

- init
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithName: (OFString*)name_
{
	self = [super init];

	name = [name_ retain];

	return self;
}

- initWithName: (OFString*)name_
   stringValue: (OFString*)stringval_
{
	self = [super init];

	name = [name_ retain];
	stringval = [stringval_ retain];

	return self;
}

- (OFString*)string
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	char *str_c;
	size_t len, i, j, attrs_count;
	OFXMLAttribute **attrs_data;
	OFString *ret, *tmp;

	len = [name length] + 4;
	str_c = [self allocMemoryWithSize: len];

	/* Start of tag */
	*str_c = '<';
	memcpy(str_c + 1, [name cString], [name length]);
	i = [name length] + 1;

	/* Attributes */
	attrs_data = [attrs data];
	attrs_count = [attrs count];

	for (j = 0; j < attrs_count; j++) {
		/* FIXME: Add namespace support */
		OFString *attr_name = [attrs_data[j] name];
		tmp = [[attrs_data[j] stringValue] stringByXMLEscaping];

		len += [attr_name length] + [tmp length] + 4;
		@try {
			str_c = [self resizeMemory: str_c
					    toSize: len];
		} @catch (OFException *e) {
			[self freeMemory: str_c];
			@throw e;
		}

		str_c[i++] = ' ';
		memcpy(str_c + i, [attr_name cString],
				[attr_name length]);
		i += [attr_name length];
		str_c[i++] = '=';
		str_c[i++] = '\'';
		memcpy(str_c + i, [tmp cString], [tmp length]);
		i += [tmp length];
		str_c[i++] = '\'';

		[pool releaseObjects];
	}

	/* Childen */
	if (stringval != nil || children != nil) {
		if (stringval != nil)
			tmp = [stringval stringByXMLEscaping];
		else if (children != nil) {
			OFXMLElement **data = [children data];
			size_t count = [children count];
			IMP append;

			tmp = [OFMutableString string];
			append = [tmp methodForSelector:
			    @selector(appendCStringWithoutUTF8Checking:)];

			for (j = 0; j < count; j++)
				append(tmp, @selector(
				    appendCStringWithoutUTF8Checking:),
				    [[data[j] string] cString]);
		}

		len += [tmp length] + [name length] + 2;
		@try {
			str_c = [self resizeMemory: str_c
					    toSize: len];
		} @catch (OFException *e) {
			[self freeMemory: str_c];
			@throw e;
		}

		str_c[i++] = '>';
		memcpy(str_c + i, [tmp cString], [tmp length]);
		i += [tmp length];
		str_c[i++] = '<';
		str_c[i++] = '/';
		memcpy(str_c + i, [name cString], [name length]);
		i += [name length];
	} else
		str_c[i++] = '/';

	str_c[i++] = '>';
	str_c[i++] = '\0';
	assert(i == len);

	[pool release];

	@try {
		ret = [OFString stringWithCString: str_c];
	} @finally {
		[self freeMemory: str_c];
	}

	return ret;
}

- addAttribute: (OFXMLAttribute*)attr
{
	if (attrs == nil)
		attrs = [[OFMutableArray alloc] init];

	/* FIXME: Prevent having it twice! */

	[attrs addObject: attr];

	return self;
}

- addAttributeWithName: (OFString*)name_
	   stringValue: (OFString*)value
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	[self addAttribute: [OFXMLAttribute attributeWithName: name_
						       prefix: nil
						    namespace: nil
						  stringValue: value]];
	[pool release];

	return self;
}

/* TODO: Replace attribute */
/* TODO: Remove attribute */

- addChild: (OFXMLElement*)child
{
	if (stringval != nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (children == nil)
		children = [[OFMutableArray alloc] init];

	[children addObject: child];

	return self;
}

- (void)dealloc
{
	[name release];
	[attrs release];
	[stringval release];
	[children release];

	[super dealloc];
}
@end

@implementation OFString (OFXMLEscaping)
- stringByXMLEscaping
{
	char *str_c, *append, *tmp;
	size_t len, append_len;
	size_t i, j;
	OFString *ret;

	j = 0;
	len = length + 1;

	/*
	 * We can't use allocMemoryWithSize: here as it might be a @"" literal
	 */
	if ((str_c = malloc(len + 1)) == NULL)
		@throw [OFOutOfMemoryException newWithClass: isa
						       size: len];

	for (i = 0; i < length; i++) {
		switch (string[i]) {
			case '<':
				append = "&lt;";
				append_len = 4;
				break;
			case '>':
				append = "&gt;";
				append_len = 4;
				break;
			case '"':
				append = "&quot;";
				append_len = 6;
				break;
			case '\'':
				append = "&apos;";
				append_len = 6;
				break;
			case '&':
				append = "&amp;";
				append_len = 5;
				break;
			default:
				append = NULL;
				append_len = 0;
		}

		if (append != NULL) {
			if ((tmp = realloc(str_c, len + append_len)) == NULL) {
				free(str_c);
				@throw [OFOutOfMemoryException
				    newWithClass: isa
					    size: len + append_len];
			}
			str_c = tmp;
			len += append_len - 1;

			memcpy(str_c + j, append, append_len);
			j += append_len;
		} else
			str_c[j++] = string[i];
	}

	str_c[j++] = '\0';
	assert(j == len);

	@try {
		ret = [OFString stringWithCString: str_c];
	} @finally {
		free(str_c);
	}

	return ret;
}
@end
