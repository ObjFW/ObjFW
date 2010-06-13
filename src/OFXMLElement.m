/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <assert.h>
#include <string.h>

#import "OFXMLElement.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFXMLAttribute.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

@implementation OFXMLElement
+ elementWithName: (OFString*)name_
{
	return [[[self alloc] initWithName: name_] autorelease];
}

+ elementWithName: (OFString*)name
      stringValue: (OFString*)stringval
{
	return [[[self alloc] initWithName: name
			       stringValue: stringval] autorelease];
}

+ elementWithName: (OFString*)name
	namespace: (OFString*)ns
{
	return [[[self alloc] initWithName: name
				 namespace: ns] autorelease];
}

+ elementWithName: (OFString*)name
	namespace: (OFString*)ns
      stringValue: (OFString*)stringval
{
	return [[[self alloc] initWithName: name
				 namespace: ns
			       stringValue: stringval] autorelease];
}

+ elementWithText: (OFString*)text
{
	return [[[self alloc] initWithText: text] autorelease];
}

+ elementWithComment: (OFString*)comment
{
	return [[[self alloc] initWithComment: comment] autorelease];
}

- init
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithName: (OFString*)name_
{
	return [self initWithName: name_
			namespace: nil
		      stringValue: nil];
}

- initWithName: (OFString*)name_
   stringValue: (OFString*)stringval
{
	return [self initWithName: name_
			namespace: nil
		      stringValue: stringval];
}

- initWithName: (OFString*)name_
     namespace: (OFString*)ns
{
	return [self initWithName: name_
			namespace: ns
		      stringValue: nil];
}

- initWithName: (OFString*)name_
     namespace: (OFString*)ns
   stringValue: (OFString*)stringval
{
	self = [super init];

	name = [name_ copy];
	namespace = [ns copy];

	if (stringval != nil) {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];;
		[self addChild: [OFXMLElement elementWithText: stringval]];
		[pool release];
	}

	namespaces = [[OFMutableDictionary alloc] initWithKeysAndObjects:
	    @"http://www.w3.org/XML/1998/namespace", @"xml",
	    @"http://www.w3.org/2000/xmlns/", @"xmlns", nil];

	return self;
}

- initWithText: (OFString*)text_
{
	self = [super init];

	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		text = [[text_ stringByXMLEscaping] retain];
		[pool release];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	return self;
}

- initWithComment: (OFString*)comment_
{
	self = [super init];

	@try {
		comment = [[OFMutableString alloc] initWithString: @"<!--"];
		[comment appendString: comment_];
		[comment appendString: @"-->"];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	return self;
}

- (OFString*)_stringWithParentNamespaces: (OFDictionary*)parent_namespaces
		  parentDefaultNamespace: (OFString*)parent_default_ns
{
	OFAutoreleasePool *pool, *pool2;
	char *str_c;
	size_t len, i, j, attrs_count;
	OFString *prefix = nil;
	OFXMLAttribute **attrs_carray;
	OFString *ret, *tmp;
	OFMutableDictionary *all_namespaces;
	OFString *def_ns;

	if (text != nil)
		return [[text retain] autorelease];

	if (comment != nil)
		return [[comment retain] autorelease];

	pool = [[OFAutoreleasePool alloc] init];
	def_ns = (defaultNamespace != nil
	    ? defaultNamespace : parent_default_ns);

	if (parent_namespaces != nil) {
		OFEnumerator *key_enum = [namespaces keyEnumerator];
		OFEnumerator *obj_enum = [namespaces objectEnumerator];
		id key, obj;

		all_namespaces = [[parent_namespaces mutableCopy] autorelease];

		while ((key = [key_enum nextObject]) != nil &&
		    (obj = [obj_enum nextObject]) != nil)
			[all_namespaces setObject: obj
					   forKey: key];
	} else
		all_namespaces = namespaces;

	i = 0;
	len = [name cStringLength] + 3;
	str_c = [self allocMemoryWithSize: len];

	/* Start of tag */
	str_c[i++] = '<';

	if ((namespace == nil && def_ns != nil) ||
	    (namespace != nil && def_ns == nil) ||
	    (namespace != nil && ![namespace isEqual: def_ns])) {
		if ((prefix = [all_namespaces objectForKey:
		    (namespace != nil ? namespace : @"")]) == nil)
			@throw [OFUnboundNamespaceException
			    newWithClass: isa
			       namespace: namespace];

		len += [prefix cStringLength] + 1;
		@try {
			str_c = [self resizeMemory: str_c
					    toSize: len];
		} @catch (OFException *e) {
			[self freeMemory: str_c];
			@throw e;
		}

		memcpy(str_c + i, [prefix cString],
		    [prefix cStringLength]);
		i += [prefix cStringLength];
		str_c[i++] = ':';
	}

	memcpy(str_c + i, [name cString], [name cStringLength]);
	i += [name cStringLength];

	/* Attributes */
	attrs_carray = [attributes cArray];
	attrs_count = [attributes count];

	pool2 = [[OFAutoreleasePool alloc] init];
	for (j = 0; j < attrs_count; j++) {
		OFString *attr_name = [attrs_carray[j] name];
		OFString *attr_prefix = nil;
		tmp = [[attrs_carray[j] stringValue] stringByXMLEscaping];

		if (([attrs_carray[j] namespace] == nil && namespace != nil) ||
		    ([attrs_carray[j] namespace] != nil && namespace == nil) ||
		    ([attrs_carray[j] namespace] != nil &&
		    ![[attrs_carray[j] namespace] isEqual: namespace]))
			if ((attr_prefix = [all_namespaces
			    objectForKey: [attrs_carray[j] namespace]]) == nil)
				@throw [OFUnboundNamespaceException
				    newWithClass: isa
				       namespace: [attrs_carray[j] namespace]];

		len += [attr_name cStringLength] +
		    (attr_prefix != nil ? [attr_prefix cStringLength] + 1 : 0) +
		    [tmp cStringLength] + 4;

		@try {
			str_c = [self resizeMemory: str_c
					    toSize: len];
		} @catch (OFException *e) {
			[self freeMemory: str_c];
			@throw e;
		}

		str_c[i++] = ' ';
		if (attr_prefix != nil) {
			memcpy(str_c + i, [attr_prefix cString],
			    [attr_prefix cStringLength]);
			i += [attr_prefix cStringLength];
			str_c[i++] = ':';
		}
		memcpy(str_c + i, [attr_name cString],
				[attr_name cStringLength]);
		i += [attr_name cStringLength];
		str_c[i++] = '=';
		str_c[i++] = '\'';
		memcpy(str_c + i, [tmp cString], [tmp cStringLength]);
		i += [tmp cStringLength];
		str_c[i++] = '\'';

		[pool2 releaseObjects];
	}

	/* Childen */
	if (children != nil) {
		OFXMLElement **children_carray = [children cArray];
		size_t children_count = [children count];
		IMP append;

		tmp = [OFMutableString string];
		append = [tmp methodForSelector:
		    @selector(appendCStringWithoutUTF8Checking:)];

		for (j = 0; j < children_count; j++)
			append(tmp, @selector(
			    appendCStringWithoutUTF8Checking:),
			    [[children_carray[j]
			    _stringWithParentNamespaces: all_namespaces
			    parentDefaultNamespace: defaultNamespace] cString]);

		len += [tmp cStringLength] + [name cStringLength] + 2;
		@try {
			str_c = [self resizeMemory: str_c
					    toSize: len];
		} @catch (OFException *e) {
			[self freeMemory: str_c];
			@throw e;
		}

		str_c[i++] = '>';
		memcpy(str_c + i, [tmp cString], [tmp cStringLength]);
		i += [tmp cStringLength];
		str_c[i++] = '<';
		str_c[i++] = '/';
		if (prefix != nil) {
			len += [prefix cStringLength] + 1;
			@try {
				str_c = [self resizeMemory: str_c
						    toSize: len];
			} @catch (OFException *e) {
				[self freeMemory: str_c];
				@throw e;
			}

			memcpy(str_c + i, [prefix cString],
			    [prefix cStringLength]);
			i += [prefix cStringLength];
			str_c[i++] = ':';
		}
		memcpy(str_c + i, [name cString], [name cStringLength]);
		i += [name cStringLength];
	} else
		str_c[i++] = '/';

	str_c[i++] = '>';
	assert(i == len);

	[pool release];

	@try {
		ret = [OFString stringWithCString: str_c
					   length: len];
	} @finally {
		[self freeMemory: str_c];
	}
	return ret;
}

- (OFString*)string
{
	return [self _stringWithParentNamespaces: nil
			  parentDefaultNamespace: nil];
}

- (void)addAttribute: (OFXMLAttribute*)attr
{
	if (name == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (attributes == nil)
		attributes = [[OFMutableArray alloc] init];

	/* FIXME: Prevent having it twice! */

	[attributes addObject: attr];
}

- (void)addAttributeWithName: (OFString*)name_
		 stringValue: (OFString*)value
{
	OFAutoreleasePool *pool;

	if (name == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	pool = [[OFAutoreleasePool alloc] init];
	[self addAttribute: [OFXMLAttribute attributeWithName: name_
						    namespace: nil
						  stringValue: value]];
	[pool release];
}

- (void)addAttributeWithName: (OFString*)name_
		   namespace: (OFString*)ns
		 stringValue: (OFString*)value
{
	OFAutoreleasePool *pool;

	if (name == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	pool = [[OFAutoreleasePool alloc] init];
	[self addAttribute: [OFXMLAttribute attributeWithName: name_
						    namespace: ns
						  stringValue: value]];
	[pool release];
}

/* TODO: Replace attribute */
/* TODO: Remove attribute */

- (void)setPrefix: (OFString*)prefix
     forNamespace: (OFString*)ns
{
	if (name == nil || prefix == nil || [prefix isEqual: @""])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];
	if (ns == nil)
		ns = @"";

	[namespaces setObject: prefix
		       forKey: ns];
}

- (OFString*)defaultNamespace
{
	if (name == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	return [[defaultNamespace retain] autorelease];
}

- (void)setDefaultNamespace: (OFString*)ns
{
	if (name == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	OFString *old = defaultNamespace;
	defaultNamespace = [ns copy];
	[old release];
}

- (void)addChild: (OFXMLElement*)child
{
	if (name == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (children == nil)
		children = [[OFMutableArray alloc] init];

	[children addObject: child];
}

- (void)dealloc
{
	[name release];
	[namespace release];
	[attributes release];
	[namespaces release];
	[children release];
	[text release];
	[comment release];

	[super dealloc];
}
@end
