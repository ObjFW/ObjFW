/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

		if (![[element name] isEqual: @"object"] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS] ||
		    ![[[element attributeForName: @"class"] stringValue]
		    isEqual: [isa className]])
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		name = [[[element
		    elementForName: @"name"
			 namespace: OF_SERIALIZATION_NS] stringValue] retain];
		ns = [[[element
		    elementForName: @"namespace"
			 namespace: OF_SERIALIZATION_NS] stringValue] retain];
		stringValue = [[[element
		    elementForName: @"stringValue"
			 namespace: OF_SERIALIZATION_NS] stringValue] retain];

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
	return [[name copy] autorelease];
}

- (OFString*)namespace
{
	return [[ns copy] autorelease];
}

- (OFString*)stringValue
{
	return [[stringValue copy] autorelease];
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

	OF_HASH_ADD_INT32(hash, [name hash]);
	OF_HASH_ADD_INT32(hash, [ns hash]);
	OF_HASH_ADD_INT32(hash, [stringValue hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool;
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: @"object"
				      namespace: OF_SERIALIZATION_NS];

	pool = [[OFAutoreleasePool alloc] init];

	[element addAttributeWithName: @"class"
			  stringValue: [self className]];

	[element addChild:
	    [OFXMLElement elementWithName: @"name"
				namespace: OF_SERIALIZATION_NS
			      stringValue: name]];
	if (ns != nil)
		[element addChild:
		    [OFXMLElement elementWithName: @"namespace"
					namespace: OF_SERIALIZATION_NS
				      stringValue: ns]];
	[element addChild:
	    [OFXMLElement elementWithName: @"stringValue"
				namespace: OF_SERIALIZATION_NS
			      stringValue: stringValue]];

	[pool release];

	return element;
}
@end
