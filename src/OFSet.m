/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#include <stdlib.h>

#import "OFSet.h"
#import "OFSet_hashtable.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFXMLElement.h"
#import "OFNull.h"

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

- initWithSet: (OFSet *)set
{
	return (id)[[OFSet_hashtable alloc] initWithSet: set];
}

- initWithArray: (OFArray *)array
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

- initWithObjects: (id const *)objects
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

- initWithSerialization: (OFXMLElement *)element
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
	OF_DEALLOC_UNSUPPORTED
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

+ (instancetype)setWithSet: (OFSet *)set
{
	return [[[self alloc] initWithSet: set] autorelease];
}

+ (instancetype)setWithArray: (OFArray *)array
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

+ (instancetype)setWithObjects: (id const *)objects
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

- initWithSet: (OFSet *)set
{
	OF_INVALID_INIT_METHOD
}

- initWithArray: (OFArray *)array
{
	OF_INVALID_INIT_METHOD
}

- initWithObjects: (id const *)objects
	    count: (size_t)count
{
	OF_INVALID_INIT_METHOD
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
	OF_INVALID_INIT_METHOD
}

- initWithSerialization: (OFXMLElement *)element
{
	OF_INVALID_INIT_METHOD
}

- (size_t)count
{
	OF_UNRECOGNIZED_SELECTOR
}

- (id)valueForKey: (OFString *)key
{
	id ret;

	if ([key hasPrefix: @"@"]) {
		void *pool = objc_autoreleasePoolPush();

		key = [key substringWithRange: of_range(1, [key length] - 1)];
		ret = [[super valueForKey: key] retain];

		objc_autoreleasePoolPop(pool);

		return [ret autorelease];
	}

	ret = [OFMutableSet setWithCapacity: [self count]];

	for (id object in self) {
		id value = [object valueForKey: key];

		if (value != nil)
			[ret addObject: value];
	}

	[ret makeImmutable];

	return ret;
}

- (void)setValue: (id)value
	  forKey: (OFString *)key
{
	if ([key hasPrefix: @"@"]) {
		void *pool = objc_autoreleasePoolPush();

		key = [key substringWithRange: of_range(1, [key length] - 1)];
		[super setValue: value
			 forKey: key];

		objc_autoreleasePoolPop(pool);
		return;
	}

	for (id object in self)
		[object setValue: value
			  forKey: key];
}

- (bool)containsObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFEnumerator *)objectEnumerator
{
	OF_UNRECOGNIZED_SELECTOR
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id *)objects
			     count: (int)count
{
	OF_UNRECOGNIZED_SELECTOR
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
	uint32_t hash = 0;

	for (id object in self)
		hash += [object hash];

	objc_autoreleasePoolPop(pool);

	return hash;
}

- (OFString *)description
{
	void *pool;
	OFMutableString *ret;
	size_t i, count = [self count];

	if (count == 0)
		return @"{()}";

	ret = [OFMutableString stringWithString: @"{(\n"];

	pool = objc_autoreleasePoolPush();

	i = 0;
	for (id object in self) {
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

- (bool)isSubsetOfSet: (OFSet *)set
{
	for (id object in self)
		if (![set containsObject: object])
			return false;

	return true;
}

- (bool)intersectsSet: (OFSet *)set
{
	for (id object in self)
		if ([set containsObject: object])
			return true;

	return false;
}

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	if ([self isKindOfClass: [OFMutableSet class]])
		element = [OFXMLElement elementWithName: @"OFMutableSet"
					      namespace: OF_SERIALIZATION_NS];
	else
		element = [OFXMLElement elementWithName: @"OFSet"
					      namespace: OF_SERIALIZATION_NS];

	for (id <OFSerialization> object in self) {
		void *pool2 = objc_autoreleasePoolPush();

		[element addChild: [object XMLElementBySerializing]];

		objc_autoreleasePoolPop(pool2);
	}

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFSet *)setBySubtractingSet: (OFSet *)set
{
	OFMutableSet *new;

	new = [[self mutableCopy] autorelease];
	[new minusSet: set];

	[new makeImmutable];

	return new;
}

- (OFSet *)setByIntersectingWithSet: (OFSet *)set
{
	OFMutableSet *new;

	new = [[self mutableCopy] autorelease];
	[new intersectSet: set];

	[new makeImmutable];

	return new;
}

- (OFSet *)setByAddingSet: (OFSet *)set
{
	OFMutableSet *new;

	new = [[self mutableCopy] autorelease];
	[new unionSet: set];

	[new makeImmutable];

	return new;
}

- (OFArray *)allObjects
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

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_set_enumeration_block_t)block
{
	bool stop = false;

	for (id object in self) {
		block(object, &stop);

		if (stop)
			break;
	}
}

- (OFSet *)filteredSetUsingBlock: (of_set_filter_block_t)block
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
