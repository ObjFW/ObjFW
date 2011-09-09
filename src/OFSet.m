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

#import "OFSet.h"
#import "OFSet_hashtable.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFNotImplementedException.h"

static struct {
	Class isa;
} placeholder;

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

- initWithObject: (id)firstObject
       arguments: (va_list)arguments
{
	return [[OFSet_hashtable alloc] initWithObject: firstObject
					     arguments: arguments];
}

- initWithSerialization: (OFXMLElement*)element
{
	return [[OFSet_hashtable alloc] initWithSerialization: element];
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
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
	[super dealloc];	/* Get rid of a stupid warning */
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
	if (isa == [OFSet class]) {
		Class c = isa;
		[self release];
		@throw [OFNotImplementedException newWithClass: c
						      selector: _cmd];
	}

	return [super init];
}

- initWithSet: (OFSet*)set
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithArray: (OFArray*)array
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithSerialization: (OFXMLElement*)element
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- (size_t)count
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (BOOL)containsObject: (id)object
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (OFEnumerator*)objectEnumerator
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (BOOL)isEqual: (id)object
{
	OFSet *otherSet;

	if (![object isKindOfClass: [OFSet class]])
		return NO;

	otherSet = object;

	if ([otherSet count] != [self count])
		return NO;

	return [otherSet isSubsetOfSet: self];
}

- (uint32_t)hash
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFEnumerator *enumerator = [self objectEnumerator];
	id object;
	uint32_t hash = 0;

	while ((object = [enumerator nextObject]) != nil)
		hash += [object hash];

	[pool release];

	return hash;
}

- (OFString*)description
{
	OFMutableString *ret;
	OFAutoreleasePool *pool, *pool2;
	OFEnumerator *enumerator;
	size_t i, count = [self count];
	id object;

	if (count == 0)
		return @"{()}";

	ret = [OFMutableString stringWithString: @"{(\n"];
	pool = [[OFAutoreleasePool alloc] init];
	enumerator = [self objectEnumerator];

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

	[ret makeImmutable];

	[pool release];

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

- (BOOL)isSubsetOfSet: (OFSet*)set
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFEnumerator *enumerator = [self objectEnumerator];
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
	OFEnumerator *enumerator = [self objectEnumerator];
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

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFAutoreleasePool *pool2;
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

	pool2 = [[OFAutoreleasePool alloc] init];
	while ((object = [enumerator nextObject]) != nil) {
		[element addChild: [object XMLElementBySerializing]];

		[pool2 releaseObjects];
	}

	[element retain];
	[pool release];
	[element autorelease];

	return element;
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_set_enumeration_block_t)block
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFEnumerator *enumerator = [self objectEnumerator];
	id object;
	BOOL stop = NO;

	while (!stop && (object = [enumerator nextObject]) != nil)
		block(object, &stop);

	[pool release];
}

- (OFSet*)filteredSetUsingBlock: (of_set_filter_block_t)block
{
	OFMutableSet *ret = [OFMutableSet set];

	[self enumerateObjectsUsingBlock: ^ (id object, BOOL *stop) {
		if (block(object))
			[ret addObject: object];
	}];

	[ret makeImmutable];

	return ret;
}
#endif
@end
