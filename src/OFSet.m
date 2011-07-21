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

#define OF_SET_M

#import "OFSet.h"
#import "OFDictionary.h"
#import "OFArray.h"
#import "OFNull.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

@implementation OFSet
+ set
{
	return [[[self alloc] init] autorelease];
}

+ setWithSet: (OFSet*)set
{
	return [[[self alloc] initWithSet: set] autorelease];
}

+ setWithArray: (OFArray*)array
{
	return [[[self alloc] initWithArray: array] autorelease];
}

+ setWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[[self alloc] initWithObject: firstObject
				  arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

- init
{
	self = [super init];

	@try {
		dictionary = [[OFMutableDictionary alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithSet: (OFSet*)set
{
	self = [super init];

	@try {
		dictionary = [[OFMutableDictionary alloc]
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
	self = [self init];

	@try {
		id *cArray = [array cArray];
		size_t i, count = [array count];
		OFNull *null = [OFNull null];

		for (i = 0; i < count; i++)
			[dictionary _setObject: null
					forKey: cArray[i]
				       copyKey: NO];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (id)initWithObjects:(id)firstObject, ...
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
	self = [self init];

	@try {
		OFNull *null = [OFNull null];
		id object;

		[dictionary _setObject: null
				forKey: firstObject
			       copyKey: NO];

		while ((object = va_arg(arguments, id)) != nil)
			[dictionary _setObject: null
					forKey: object
				       copyKey: NO];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[dictionary release];

	[super dealloc];
}

- (BOOL)isEqual: (id)object
{
	OFSet *otherSet;

	if (![object isKindOfClass: [OFSet class]])
		return NO;

	otherSet = object;

	return [otherSet->dictionary isEqual: dictionary];
}

- (uint32_t)hash
{
	return [dictionary hash];
}

- (OFString*)description
{
	OFMutableString *ret;
	OFAutoreleasePool *pool, *pool2;
	OFEnumerator *enumerator;
	size_t i, count = [dictionary count];
	id object;

	if (count == 0)
		return @"{()}";

	ret = [OFMutableString stringWithString: @"{(\n"];
	pool = [[OFAutoreleasePool alloc] init];
	enumerator = [dictionary keyEnumerator];

	i = 0;
	pool2 = [[OFAutoreleasePool alloc] init];

	while ((object = [enumerator nextObject]) != nil) {
		[ret appendString: [object description]];

		if (++i < count)
			[ret appendString: @",\n"];

		[pool2 releaseObjects];
	}
	[ret replaceOccurrencesOfString: @"\n"
			     withString: @"\n\t"];
	[ret appendString: @"\n)}"];

	[pool release];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	ret->isa = [OFString class];
	return ret;
}

- copy
{
	return [[OFSet alloc] initWithSet: self];
}

- mutableCopy
{
	return [[OFMutableSet alloc] initWithSet: self];
}

- (size_t)count
{
	return [dictionary count];
}

- (BOOL)containsObject: (id)object
{
	return ([dictionary objectForKey: object] != nil);
}

- (BOOL)isSubsetOfSet: (OFSet*)set
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFEnumerator *enumerator = [dictionary keyEnumerator];
	id object;

	while ((object = [enumerator nextObject]) != nil) {
		if (![set containsObject: object]) {
			[pool release];
			return NO;
		}
	}

	[pool release];

	return YES;
}

- (BOOL)intersectsSet: (OFSet*)set
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFEnumerator *enumerator = [dictionary keyEnumerator];
	id object;

	while ((object = [enumerator nextObject]) != nil) {
		if ([set containsObject: object]) {
			[pool release];
			return YES;
		}
	}

	[pool release];

	return NO;
}

- (OFEnumerator*)objectEnumerator
{
	return [dictionary keyEnumerator];
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count
{
	OFAutoreleasePool *pool = state->extra.pointers[0];
	OFEnumerator *enumerator = state->extra.pointers[1];
	int i;

	state->itemsPtr = objects;
	state->mutationsPtr = (unsigned long*)self;

	if (state->state == -1)
		return 0;

	if (state->state == 0) {
		pool = [[OFAutoreleasePool alloc] init];
		enumerator = [dictionary keyEnumerator];

		state->extra.pointers[0] = pool;
		state->extra.pointers[1] = enumerator;

		state->state = 1;
	}

	for (i = 0; i < count; i++) {
		id object = [enumerator nextObject];

		if (object == nil) {
			[pool release];
			state->state = -1;
			return i;
		}

		objects[i] = object;
	}

	return count;
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_set_enumeration_block_t)block
{
	[dictionary enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    BOOL *stop) {
		block(key, stop);
	}];
}

- (OFSet*)filteredSetUsingBlock: (of_set_filter_block_t)block
{
	OFMutableSet *ret = [OFMutableSet set];

	[dictionary enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    BOOL *stop) {
		if (block(key))
			[ret addObject: key];
	}];

	/*
	 * Class swizzle the set to be immutable. We declared the return type
	 * to be OFSet*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	ret->isa = [OFSet class];
	return ret;
}
#endif
@end
