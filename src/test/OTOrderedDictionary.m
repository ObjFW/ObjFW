/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
			[mutableKeys addObject: keys[i]];
			[mutableObjects addObject: objects[i]];
		}

		[mutableKeys makeImmutable];
		[mutableObjects makeImmutable];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_keys);
	objc_release(_objects);

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
