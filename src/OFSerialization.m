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

#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
# import <objc/runtime.h>
#endif

#import "OFSerialization.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"

#if defined(OF_OBJFW_RUNTIME) || defined(OF_OLD_GNU_RUNTIME)
# define objc_lookUpClass objc_lookup_class
#endif

@implementation OFSerialization
+ (OFString*)stringBySerializingObject: (id <OFSerialization>)object
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *element = [object XMLElementBySerializing];
	OFXMLElement *root;
	OFString *ret;

	root = [OFXMLElement elementWithName: @"serialization"
				   namespace: OF_SERIALIZATION_NS];
	[root addChild: element];

	ret = [@"<?xml version='1.0' encoding='UTF-8'?>\n"
	    stringByAppendingString: [root XMLString]];
	[ret retain];

	@try {
		[pool release];
	} @catch (id e) {
		[ret release];
	}

	return [ret autorelease];
}

+ (id)objectByDeserializingString: (OFString*)string
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *root = [OFXMLElement elementWithXMLString: string];
	OFArray *elements;
	id object;

	elements = [root elementsForName: @"object"
			       namespace: OF_SERIALIZATION_NS];

	if ([elements count] != 1)
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	object = [[self objectByDeserializingXMLElement: [elements firstObject]]
	    retain];

	@try {
		[pool release];
	} @catch (id e) {
		[object release];
		@throw e;
	}

	return [object autorelease];
}

+ (id)objectByDeserializingXMLElement: (OFXMLElement*)element
{
	OFAutoreleasePool *pool;
	OFString *className;
	Class class;
	id object;

	if (element == nil)
		return nil;

	pool = [[OFAutoreleasePool alloc] init];
	className = [[element attributeForName: @"class"] stringValue];
	if (className == nil)
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	class = objc_lookUpClass([className cString]);
	if (class == Nil)
		@throw [OFNotImplementedException newWithClass: Nil];

	if (![class instancesRespondToSelector:
	    @selector(initWithSerialization:)])
		@throw [OFNotImplementedException
		    newWithClass: class
			selector: @selector(initWithSerialization:)];

	object = [[class alloc] initWithSerialization: element];

	@try {
		[pool release];
	} @catch (id e) {
		[object release];
		@throw e;
	}

	return [object autorelease];
}

- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}
@end
