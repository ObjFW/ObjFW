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

#import "OFCountedSet.h"
#import "OFCountedSet_hashtable.h"
#import "OFNumber.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFNotImplementedException.h"

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
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
	[super dealloc];	/* Get rid of a stupid warning */
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
	if (isa == [OFCountedSet class]) {
		Class c = isa;
		[self release];
		@throw [OFNotImplementedException exceptionWithClass: c
							    selector: _cmd];
	}

	return [super init];
}

- (size_t)countForObject: (id)object
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
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
		[ret appendString: object];
		[ret appendFormat: @": %zu", [self countForObject: object]];

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

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFAutoreleasePool *pool2;
	OFXMLElement *element;
	OFEnumerator *enumerator;
	id <OFSerialization> object;

	element = [OFXMLElement elementWithName: @"OFCountedSet"
				      namespace: OF_SERIALIZATION_NS];

	enumerator = [self objectEnumerator];

	pool2 = [[OFAutoreleasePool alloc] init];
	while ((object = [enumerator nextObject]) != nil) {
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

		[pool2 releaseObjects];
	}

	[element retain];
	[pool release];
	[element autorelease];

	return element;
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsAndCountUsingBlock:
    (of_counted_set_enumeration_block_t)block
{
	[self enumerateObjectsUsingBlock: ^ (id object, BOOL *stop) {
		block(object, [self countForObject: object], stop);
	}];
}
#endif

- (void)minusSet: (OFSet*)set
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

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

	[pool release];
}

- (void)unionSet: (OFSet*)set
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

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

	[pool release];
}
@end
