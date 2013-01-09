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

#include <assert.h>

#import "OFMutableSet.h"
#import "OFMutableSet_hashtable.h"

#import "autorelease.h"

static struct {
	Class isa;
} placeholder;

@interface OFMutableSet_placeholder: OFMutableSet
@end

@implementation OFMutableSet_placeholder
- init
{
	return (id)[[OFMutableSet_hashtable alloc] init];
}

- initWithSet: (OFSet*)set
{
	return (id)[[OFMutableSet_hashtable alloc] initWithSet: set];
}

- initWithArray: (OFArray*)array
{
	return (id)[[OFMutableSet_hashtable alloc] initWithArray: array];
}

- initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFMutableSet_hashtable alloc] initWithObject: firstObject
						   arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithObjects: (id const*)objects
	    count: (size_t)count
{
	return (id)[[OFMutableSet_hashtable alloc] initWithObjects: objects
							     count: count];
}

- initWithObject: (id)firstObject
       arguments: (va_list)arguments
{
	return (id)[[OFMutableSet_hashtable alloc] initWithObject: firstObject
							arguments: arguments];
}

- initWithSerialization: (OFXMLElement*)element
{
	return (id)[[OFMutableSet_hashtable alloc]
	    initWithSerialization: element];
}

- retain
{
	return self;
}

- autorelease
{
	return self;
}

- (void)release
{
}

- (void)dealloc
{
	[self doesNotRecognizeSelector: _cmd];
	abort();

	/* Get rid of a stupid warning */
	[super dealloc];
}
@end

@implementation OFMutableSet
+ (void)initialize
{
	if (self == [OFMutableSet class])
		placeholder.isa = [OFMutableSet_placeholder class];
}

+ alloc
{
	if (self == [OFMutableSet class])
		return (id)&placeholder;

	return [super alloc];
}

- init
{
	if (object_getClass(self) == [OFMutableSet class]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		} @catch (id e) {
			[self release];
			@throw e;
		}
	}

	return [super init];
}

- (void)addObject: (id)object
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (void)removeObject: (id)object
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (void)minusSet: (OFSet*)set
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [set objectEnumerator];
	id object;

	while ((object = [enumerator nextObject]) != nil)
		[self removeObject: object];

	objc_autoreleasePoolPop(pool);
}

- (void)intersectSet: (OFSet*)set
{
	void *pool = objc_autoreleasePoolPush();
	size_t count = [self count];
	id *cArray;

	cArray = [self allocMemoryWithSize: sizeof(id)
				     count: count];

	@try {
		OFEnumerator *enumerator;
		id object;
		size_t i;

		i = 0;
		enumerator = [self objectEnumerator];
		while ((object = [enumerator nextObject]) != nil) {
			assert(i < count);
			cArray[i++] = object;
		}

		for (i = 0; i < count; i++)
			if (![set containsObject: cArray[i]])
			      [self removeObject: cArray[i]];
	} @finally {
		[self freeMemory: cArray];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)unionSet: (OFSet*)set
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator;
	id object;

	enumerator = [set objectEnumerator];
	while ((object = [enumerator nextObject]) != nil)
		[self addObject: object];

	objc_autoreleasePoolPop(pool);
}

- (void)makeImmutable
{
}
@end
