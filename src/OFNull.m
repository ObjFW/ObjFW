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

#import "OFNull.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"

static OFNull *null = nil;

@implementation OFNull
+ null
{
	if (null != nil)
		return null;

	null = [[self alloc] init];

	return null;
}

- initWithSerialization: (OFXMLElement*)element
{
	OFAutoreleasePool *pool;

	[self release];

	pool = [[OFAutoreleasePool alloc] init];

	if (![[element name] isEqual: @"object"] ||
	    ![[element namespace] isEqual: OF_SERIALIZATION_NS] ||
	    ![[[element attributeForName: @"class"] stringValue]
	    isEqual: [self className]])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	[pool release];

	return [OFNull null];
}

- (OFString*)description
{
	return @"<null>";
}

- copy
{
	return self;
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: @"object"
				      namespace: OF_SERIALIZATION_NS];
	[element addAttributeWithName: @"class"
			  stringValue: [self className]];

	return element;
}

- autorelease
{
	return self;
}

- retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OF_RETAIN_COUNT_MAX;
}

- (void)dealloc
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
	[super dealloc];	/* Get rid of a stupid warning */
}
@end
