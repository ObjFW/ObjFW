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

#define OF_COUNTED_SET_M

#import "OFCountedSet.h"
#import "OFMutableDictionary_hashtable.h"
#import "OFNumber.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

@implementation OFCountedSet
- initWithSet: (OFSet*)set
{
	self = [super init];

	@try {
		[dictionary release];
		dictionary = nil;
		dictionary = [[OFMutableDictionary_hashtable alloc]
			_initWithDictionary: set->dictionary
				   copyKeys: NO];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithArray: (OFArray*)array
{
	self = [super init];

	@try {
		id *cArray = [array cArray];
		size_t i, count = [array count];

		for (i = 0; i < count; i++)
			[self addObject: cArray[i]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObject: (id)firstObject
       arguments: (va_list)arguments
{
	self = [super init];

	@try {
		id object;

		[self addObject: firstObject];

		while ((object = va_arg(arguments, id)) != nil)
			[self addObject: object];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (OFString*)description
{
	OFMutableString *ret;
	OFAutoreleasePool *pool, *pool2;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	size_t i, count = [dictionary count];
	id key, object;

	if (count == 0)
		return @"{()}";

	ret = [OFMutableString stringWithString: @"{(\n"];
	pool = [[OFAutoreleasePool alloc] init];
	keyEnumerator = [dictionary keyEnumerator];
	objectEnumerator = [dictionary objectEnumerator];

	i = 0;
	pool2 = [[OFAutoreleasePool alloc] init];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		[ret appendString: [key description]];
		[ret appendString: @": "];
		[ret appendString: [object description]];

		if (++i < count)
			[ret appendString: @",\n"];

		[pool2 releaseObjects];
	}
	[ret replaceOccurrencesOfString: @"\n"
			     withString: @"\n\t"];
	[ret appendString: @"\n)}"];

	[ret makeImmutable];

	[pool release];

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

- (size_t)countForObject: (id)object
{
	return [[dictionary objectForKey: object] sizeValue];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsAndCountUsingBlock:
    (of_counted_set_enumeration_block_t)block
{
	[dictionary enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    BOOL *stop) {
		block(key, [object sizeValue], stop);
	}];
}
#endif

- (void)addObject: (id)object
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFNumber *count;

	count = [[dictionary objectForKey: object] numberByIncreasing];

	if (count == nil)
		count = [OFNumber numberWithSize: 1];

	[dictionary _setObject: count
			forKey: object
		       copyKey: NO];

	mutations++;

	[pool release];
}

- (void)removeObject: (id)object
{
	OFNumber *count = [dictionary objectForKey: object];
	OFAutoreleasePool *pool;

	if (count == nil)
		return;

	pool = [[OFAutoreleasePool alloc] init];
	count = [count numberByDecreasing];

	if ([count sizeValue] > 0)
		[dictionary _setObject: count
				forKey: object
			       copyKey: NO];
	else
		[dictionary removeObjectForKey: object];

	mutations++;

	[pool release];
}

- (void)minusSet: (OFSet*)set
{
	OFCountedSet *countedSet;
	OFAutoreleasePool *pool;
	OFEnumerator *enumerator;
	id object;

	if (![set isKindOfClass: [OFCountedSet class]]) {
		[super minusSet: set];
		return;
	}

	countedSet = (OFCountedSet*)set;

	pool = [[OFAutoreleasePool alloc] init];
	enumerator = [countedSet objectEnumerator];

	while ((object = [enumerator nextObject]) != nil) {
		size_t i, count = [countedSet countForObject: object];

		for (i = 0; i < count; i++)
			[self removeObject: object];
	}

	[pool release];
}

- (void)unionSet: (OFSet*)set
{
	OFCountedSet *countedSet;
	OFAutoreleasePool *pool;
	OFEnumerator *enumerator;
	id object;

	if (![set isKindOfClass: [OFCountedSet class]]) {
		[super unionSet: set];
		return;
	}

	countedSet = (OFCountedSet*)set;

	pool = [[OFAutoreleasePool alloc] init];
	enumerator = [countedSet objectEnumerator];

	while ((object = [enumerator nextObject]) != nil) {
		size_t i, count = [countedSet countForObject: object];

		for (i = 0; i < count; i++)
			[self addObject: object];
	}

	[pool release];
}

- (void)makeImmutable
{
}
@end
