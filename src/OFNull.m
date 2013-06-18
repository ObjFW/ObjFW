/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include <stdlib.h>

#import "OFNull.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFDataArray.h"

#import "OFInvalidArgumentException.h"

#import "autorelease.h"

static OFNull *null = nil;

@implementation OFNull
+ (void)initialize
{
	null = [[self alloc] init];
}

+ (OFNull*)null
{
	return null;
}

- initWithSerialization: (OFXMLElement*)element
{
	void *pool;

	[self release];

	pool = objc_autoreleasePoolPush();

	if (![[element name] isEqual: [self className]] ||
	    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
		@throw [OFInvalidArgumentException exception];

	objc_autoreleasePoolPop(pool);

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
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFString*)JSONRepresentation
{
	return @"null";
}

- (OFDataArray*)messagePackRepresentation
{
	OFDataArray *data = [OFDataArray dataArrayWithItemSize: 1
						      capacity: 1];
	uint8_t type = 0xC0;

	[data addItem: &type];

	return data;
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
	[self doesNotRecognizeSelector: _cmd];
	abort();

	/* Get rid of a stupid warning */
	[super dealloc];
}
@end
