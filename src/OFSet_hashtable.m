/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#define OF_SET_HASHTABLE_M

#import "OFSet_hashtable.h"
#import "OFMutableSet_hashtable.h"
#import "OFCountedSet_hashtable.h"
#import "OFMutableDictionary_hashtable.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFNumber.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidArgumentException.h"

@implementation OFSet_hashtable
- init
{
	self = [super init];

	@try {
		dictionary = [[OFMutableDictionary_hashtable alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithSet: (OFSet*)set
{
	self = [self init];

	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		OFNumber *one = [OFNumber numberWithSize: 1];
		OFEnumerator *enumerator = [set objectEnumerator];
		id object;

		/*
		 * We can't just copy the dictionary as the specified set might
		 * be a counted set, but we're just a normal set.
		 */
		while ((object = [enumerator nextObject]) != nil)
			[dictionary _setObject: one
					forKey: object
				       copyKey: NO];

		[pool release];
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
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		OFNumber *one = [OFNumber numberWithSize: 1];
		id *objects = [array objects];
		size_t i, count = [array count];

		for (i = 0; i < count; i++)
			[dictionary _setObject: one
					forKey: objects[i]
				       copyKey: NO];

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObjects: (id const*)objects
	    count: (size_t)count
{
	self = [self init];

	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		OFNumber *one = [OFNumber numberWithSize: 1];
		size_t i;

		for (i = 0; i < count; i++)
			[dictionary _setObject: one
					forKey: objects[i]
				       copyKey: NO];

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObject: (id)firstObject
       arguments: (va_list)arguments
{
	self = [self init];

	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		OFNumber *one = [OFNumber numberWithSize: 1];
		id object;

		[dictionary _setObject: one
				forKey: firstObject
			       copyKey: NO];

		while ((object = va_arg(arguments, id)) != nil)
			[dictionary _setObject: one
					forKey: object
				       copyKey: NO];

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	self = [self init];

	@try {
		OFAutoreleasePool *pool, *pool2;
		OFNumber *one;
		OFEnumerator *enumerator;
		OFXMLElement *child;

		pool = [[OFAutoreleasePool alloc] init];

		if ((![[element name] isEqual: @"OFSet"] &&
		    ![[element name] isEqual: @"OFMutableSet"]) ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		one = [OFNumber numberWithSize: 1];

		enumerator = [[element elementsForNamespace:
		    OF_SERIALIZATION_NS] objectEnumerator];
		pool2 = [[OFAutoreleasePool alloc] init];

		while ((child = [enumerator nextObject]) != nil) {
			[dictionary _setObject: one
					forKey: [child objectByDeserializing]
				       copyKey: NO];

			[pool2 releaseObjects];
		}

		[pool release];
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

- (size_t)count
{
	return [dictionary count];
}

- (BOOL)containsObject: (id)object
{
	return ([dictionary objectForKey: object] != nil);
}

- (BOOL)isEqual: (id)object
{
	OFSet_hashtable *otherSet;

	if (![object isKindOfClass: [OFSet_hashtable class]] &&
	    ![object isKindOfClass: [OFMutableSet_hashtable class]] &&
	    ![object isKindOfClass: [OFCountedSet_hashtable class]])
		return [super isEqual: object];

	otherSet = object;

	return [otherSet->dictionary isEqual: dictionary];
}

- (OFEnumerator*)objectEnumerator
{
	return [dictionary keyEnumerator];
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count
{
	return [dictionary countByEnumeratingWithState: state
					       objects: objects
						 count: count];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_set_enumeration_block_t)block
{
	[dictionary enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    BOOL *stop) {
		block(key, stop);
	}];
}
#endif
@end
