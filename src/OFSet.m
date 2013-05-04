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

#import "OFSet.h"
#import "OFSet_hashtable.h"
#import "OFString.h"
#import "OFXMLElement.h"

#import "autorelease.h"

static struct {
	Class isa;
} placeholder;

@interface OFSet_placeholder: OFSet
@end

@implementation OFSet_placeholder
- init
{
	return (id)[[OFSet_hashtable alloc] init];
}

- initWithSet: (OFSet*)set
{
	return (id)[[OFSet_hashtable alloc] initWithSet: set];
}

- initWithArray: (OFArray*)array
{
	return (id)[[OFSet_hashtable alloc] initWithArray: array];
}

- initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFSet_hashtable alloc] initWithObject: firstObject
					    arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithObjects: (id const*)objects
	    count: (size_t)count
{
	return (id)[[OFSet_hashtable alloc] initWithObjects: objects
						      count: count];
}

- initWithObject: (id)firstObject
       arguments: (va_list)arguments
{
	return (id)[[OFSet_hashtable alloc] initWithObject: firstObject
						 arguments: arguments];
}

- initWithSerialization: (OFXMLElement*)element
{
	return (id)[[OFSet_hashtable alloc] initWithSerialization: element];
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

@implementation OFSet
+ (void)initialize
{
	if (self == [OFSet class])
		placeholder.isa = [OFSet_placeholder class];
}

+ alloc
{
	if (self == [OFSet class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)set
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)setWithSet: (OFSet*)set
{
	return [[[self alloc] initWithSet: set] autorelease];
}

+ (instancetype)setWithArray: (OFArray*)array
{
	return [[[self alloc] initWithArray: array] autorelease];
}

+ (instancetype)setWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[[self alloc] initWithObject: firstObject
				  arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

+ (instancetype)setWithObjects: (id const*)objects
			 count: (size_t)count
{
	return [[[self alloc] initWithObjects: objects
					count: count] autorelease];
}

- init
{
	if (object_getClass(self) == [OFSet class]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			[self release];
			@throw e;
		}

		abort();
	}

	return [super init];
}

- initWithSet: (OFSet*)set
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithArray: (OFArray*)array
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithObjects: (id const*)objects
	    count: (size_t)count
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- (id)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [self initWithObject: firstObject
			 arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithObject: (id)firstObject
       arguments: (va_list)arguments
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithSerialization: (OFXMLElement*)element
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- (size_t)count
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (bool)containsObject: (id)object
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (OFEnumerator*)objectEnumerator
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (bool)isEqual: (id)object
{
	OFSet *otherSet;

	if (![object isKindOfClass: [OFSet class]])
		return false;

	otherSet = object;

	if ([otherSet count] != [self count])
		return false;

	return [otherSet isSubsetOfSet: self];
}

- (uint32_t)hash
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [self objectEnumerator];
	id object;
	uint32_t hash = 0;

	while ((object = [enumerator nextObject]) != nil)
		hash += [object hash];

	objc_autoreleasePoolPop(pool);

	return hash;
}

- (OFString*)description
{
	void *pool;
	OFMutableString *ret;
	OFEnumerator *enumerator;
	size_t i, count = [self count];
	id object;

	if (count == 0)
		return @"{()}";

	ret = [OFMutableString stringWithString: @"{(\n"];

	pool = objc_autoreleasePoolPush();
	enumerator = [self objectEnumerator];

	i = 0;
	while ((object = [enumerator nextObject]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();

		[ret appendString: [object description]];

		if (++i < count)
			[ret appendString: @",\n"];

		objc_autoreleasePoolPop(pool2);
	}
	[ret replaceOccurrencesOfString: @"\n"
			     withString: @"\n\t"];
	[ret appendString: @"\n)}"];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- copy
{
	return [self retain];
}

- mutableCopy
{
	return [[OFMutableSet alloc] initWithSet: self];
}

- (bool)isSubsetOfSet: (OFSet*)set
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator;
	id object;

	enumerator = [self objectEnumerator];
	while ((object = [enumerator nextObject]) != nil) {
		if (![set containsObject: object]) {
			objc_autoreleasePoolPop(pool);
			return false;
		}
	}

	objc_autoreleasePoolPop(pool);

	return true;
}

- (bool)intersectsSet: (OFSet*)set
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator;
	id object;

	enumerator = [self objectEnumerator];
	while ((object = [enumerator nextObject]) != nil) {
		if ([set containsObject: object]) {
			objc_autoreleasePoolPop(pool);
			return true;
		}
	}

	objc_autoreleasePoolPop(pool);

	return false;
}

- (OFXMLElement*)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;
	OFEnumerator *enumerator;
	id <OFSerialization> object;

	if ([self isKindOfClass: [OFMutableSet class]])
		element = [OFXMLElement elementWithName: @"OFMutableSet"
					      namespace: OF_SERIALIZATION_NS];
	else
		element = [OFXMLElement elementWithName: @"OFSet"
					      namespace: OF_SERIALIZATION_NS];

	enumerator = [self objectEnumerator];

	while ((object = [enumerator nextObject]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();

		[element addChild: [object XMLElementBySerializing]];

		objc_autoreleasePoolPop(pool2);
	}

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFSet*)setBySubtractingSet: (OFSet*)set
{
	OFMutableSet *new;

	new = [[self mutableCopy] autorelease];
	[new minusSet: set];

	[new makeImmutable];

	return new;
}

- (OFSet*)setByIntersectingWithSet: (OFSet*)set
{
	OFMutableSet *new;

	new = [[self mutableCopy] autorelease];
	[new intersectSet: set];

	[new makeImmutable];

	return new;
}

- (OFSet*)setByAddingSet: (OFSet*)set
{
	OFMutableSet *new;

	new = [[self mutableCopy] autorelease];
	[new unionSet: set];

	[new makeImmutable];

	return new;
}

- (OFArray*)allObjects
{
	void *pool = objc_autoreleasePoolPush();
	OFArray *ret = [[[self objectEnumerator] allObjects] retain];
	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (id)anyObject
{
	void *pool = objc_autoreleasePoolPush();
	id ret = [[[self objectEnumerator] nextObject] retain];
	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

#if defined(OF_HAVE_BLOCKS) && defined(OF_HAVE_FAST_ENUMERATION)
- (void)enumerateObjectsUsingBlock: (of_set_enumeration_block_t)block
{
	bool stop = false;

	for (id object in self) {
		block(object, &stop);

		if (stop)
			break;
	}
}
#endif

#ifdef OF_HAVE_BLOCKS
- (OFSet*)filteredSetUsingBlock: (of_set_filter_block_t)block
{
	OFMutableSet *ret = [OFMutableSet set];

	[self enumerateObjectsUsingBlock: ^ (id object, bool *stop) {
		if (block(object))
			[ret addObject: object];
	}];

	[ret makeImmutable];

	return ret;
}
#endif
@end
