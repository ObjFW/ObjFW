/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#import "OFCountedSet.h"
#import "OFCountedSet_hashtable.h"
#import "OFNumber.h"
#import "OFString.h"
#import "OFXMLElement.h"

static struct {
	Class isa;
} placeholder;

@interface OFCountedSet_placeholder: OFCountedSet
@end

@implementation OFCountedSet_placeholder
- init
{
	return (id)[[OFCountedSet_hashtable alloc] init];
}

- initWithSet: (OFSet*)set
{
	return (id)[[OFCountedSet_hashtable alloc] initWithSet: set];
}

- initWithArray: (OFArray*)array
{
	return (id)[[OFCountedSet_hashtable alloc] initWithArray: array];
}

- initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFCountedSet_hashtable alloc] initWithObject: firstObject
						   arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithObjects: (id const*)objects
	    count: (size_t)count
{
	return (id)[[OFCountedSet_hashtable alloc] initWithObjects: objects
							     count: count];
}

- initWithObject: (id)firstObject
       arguments: (va_list)arguments
{
	return (id)[[OFCountedSet_hashtable alloc] initWithObject: firstObject
							arguments: arguments];
}

- initWithSerialization: (OFXMLElement*)element
{
	return (id)[[OFCountedSet_hashtable alloc]
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
	OF_UNRECOGNIZED_SELECTOR

	/* Get rid of a stupid warning */
	[super dealloc];
}
@end

@implementation OFCountedSet
+ (void)initialize
{
	if (self == [OFCountedSet class])
		placeholder.isa = [OFCountedSet_placeholder class];
}

+ alloc
{
	if (self == [OFCountedSet class])
		return (id)&placeholder;

	return [super alloc];
}

- init
{
	if (object_getClass(self) == [OFCountedSet class]) {
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

- (size_t)countForObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFString*)description
{
	OFMutableString *ret;
	void *pool;
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

		[ret appendString: object];
		[ret appendFormat: @": %zu", [self countForObject: object]];

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
	return [[OFCountedSet alloc] initWithSet: self];
}

- mutableCopy
{
	return [[OFCountedSet alloc] initWithSet: self];
}

- (OFXMLElement*)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;
	OFEnumerator *enumerator;
	id <OFSerialization> object;

	element = [OFXMLElement elementWithName: @"OFCountedSet"
				      namespace: OF_SERIALIZATION_NS];

	enumerator = [self objectEnumerator];

	while ((object = [enumerator nextObject]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();

		OFXMLElement *objectElement;
		OFString *count;

		count =
		    [OFString stringWithFormat: @"%zu",
						[self countForObject: object]];

		objectElement = [OFXMLElement
		    elementWithName: @"object"
			  namespace: OF_SERIALIZATION_NS];
		[objectElement addAttributeWithName: @"count"
					stringValue: count];
		[objectElement addChild: [object XMLElementBySerializing]];
		[element addChild: objectElement];

		objc_autoreleasePoolPop(pool2);
	}

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsAndCountUsingBlock:
    (of_counted_set_enumeration_block_t)block
{
	[self enumerateObjectsUsingBlock: ^ (id object, bool *stop) {
		block(object, [self countForObject: object], stop);
	}];
}
#endif

- (void)minusSet: (OFSet*)set
{
	void *pool = objc_autoreleasePoolPush();

	if ([set isKindOfClass: [OFCountedSet class]]) {
		OFCountedSet *countedSet = (OFCountedSet*)set;
		OFEnumerator *enumerator = [countedSet objectEnumerator];
		id object;

		while ((object = [enumerator nextObject]) != nil) {
			size_t i, count = [countedSet countForObject: object];

			for (i = 0; i < count; i++)
				[self removeObject: object];
		}
	} else {
		OFEnumerator *enumerator = [set objectEnumerator];
		id object;

		while ((object = [enumerator nextObject]) != nil)
			[self removeObject: object];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)unionSet: (OFSet*)set
{
	void *pool = objc_autoreleasePoolPush();

	if ([set isKindOfClass: [OFCountedSet class]]) {
		OFCountedSet *countedSet = (OFCountedSet*)set;
		OFEnumerator *enumerator = [countedSet objectEnumerator];
		id object;

		while ((object = [enumerator nextObject]) != nil) {
			size_t i, count = [countedSet countForObject: object];

			for (i = 0; i < count; i++)
				[self addObject: object];
		}
	} else {
		OFEnumerator *enumerator = [set objectEnumerator];
		id object;

		while ((object = [enumerator nextObject]) != nil)
			[self addObject: object];
	}

	objc_autoreleasePoolPop(pool);
}
@end
