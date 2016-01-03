/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
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
#import "OFDataArray.h"

#import "OFInvalidArgumentException.h"

@interface OFNull ()
- (OFString*)OF_JSONRepresentationWithOptions: (int)options
					depth: (size_t)depth;
@end

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
	return [self OF_JSONRepresentationWithOptions: 0
						depth: 0];
}

- (OFString*)JSONRepresentationWithOptions: (int)options
{
	return [self OF_JSONRepresentationWithOptions: options
						depth: 0];
}

- (OFString*)OF_JSONRepresentationWithOptions: (int)options
					depth: (size_t)depth
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
	OF_UNRECOGNIZED_SELECTOR

	/* Get rid of a stupid warning */
	[super dealloc];
}
@end
