/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OTOrderedDictionary.h"

@implementation OTOrderedDictionary
- (instancetype)initWithObjects: (id const *)objects
			forKeys: (id const *)keys
			  count: (size_t)count
{
	self = [super init];

	@try {
		OFMutableArray *mutableKeys, *mutableObjects;

		mutableKeys = [[OFMutableArray alloc] initWithCapacity: count];
		_keys = mutableKeys;

		mutableObjects = [[OFMutableArray alloc]
		    initWithCapacity: count];
		_objects = mutableObjects;

		for (size_t i = 0; i < count; i++) {
			OFLog(@"key=%@, value=%@", keys[i], objects[i]);
			[mutableKeys addObject: keys[i]];
			[mutableObjects addObject: objects[i]];
		}

		[mutableKeys makeImmutable];
		[mutableObjects makeImmutable];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_keys release];
	[_objects release];

	[super dealloc];
}

- (id)objectForKey: (id)key
{
	size_t i = 0;

	for (id iter in _keys) {
		if ([iter isEqual: key])
			return [_objects objectAtIndex: i];

		i++;
	}

	return nil;
}

- (size_t)count
{
	return _keys.count;
}

- (OFEnumerator *)keyEnumerator
{
	return [_keys objectEnumerator];
}

- (OFEnumerator *)objectEnumerator
{
	return [_objects objectEnumerator];
}
@end
