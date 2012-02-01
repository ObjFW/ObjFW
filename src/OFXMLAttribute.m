/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFXMLAttribute.h"
#import "OFString.h"
#import "OFDictionary.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidArgumentException.h"

#import "macros.h"

@implementation OFXMLAttribute
+ attributeWithName: (OFString*)name
	  namespace: (OFString*)ns
	stringValue: (OFString*)value
{
	return [[[self alloc] initWithName: name
				 namespace: ns
			       stringValue: value] autorelease];
}

- initWithName: (OFString*)name_
     namespace: (OFString*)ns_
   stringValue: (OFString*)value
{
	self = [super init];

	@try {
		name = [name_ copy];
		ns = [ns_ copy];
		stringValue = [value copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	self = [super init];

	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		name = [[[element attributeForName: @"name"] stringValue]
		    copy];
		ns = [[[element attributeForName: @"namespace"] stringValue]
		    copy];
		stringValue = [[[element attributeForName: @"stringValue"]
		    stringValue] copy];

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[name release];
	[ns release];
	[stringValue release];

	[super dealloc];
}

- (OFString*)name
{
	OF_GETTER(name, YES)
}

- (OFString*)namespace
{
	OF_GETTER(ns, YES)
}

- (OFString*)stringValue
{
	OF_GETTER(stringValue, YES)
}

- (BOOL)isEqual: (id)object
{
	OFXMLAttribute *otherAttribute;

	if (![object isKindOfClass: [OFXMLAttribute class]])
		return NO;

	otherAttribute = object;

	if (![otherAttribute->name isEqual: name])
		return NO;
	if (otherAttribute->ns != ns && ![otherAttribute->ns isEqual: ns])
		return NO;
	if (![otherAttribute->stringValue isEqual: stringValue])
		return NO;

	return YES;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [name hash]);
	OF_HASH_ADD_HASH(hash, [ns hash]);
	OF_HASH_ADD_HASH(hash, [stringValue hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS];

	[element addAttributeWithName: @"name"
			  stringValue: name];

	if (ns != nil)
		[element addAttributeWithName: @"namespace"
				  stringValue: ns];

	[element addAttributeWithName: @"stringValue"
			  stringValue: stringValue];

	[element retain];
	[pool release];
	[element autorelease];

	return element;
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"<OFXMLAttribute, name=%@, "
					   @"namespace=%@, stringValue=%@>",
					   name, ns, stringValue];
}
@end
