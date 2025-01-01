/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#include <stdlib.h>

#import "OFEnumerator.h"
#import "OFArray.h"

@implementation OFEnumerator
- (instancetype)init
{
	if ([self isMemberOfClass: [OFEnumerator class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		} @catch (id e) {
			[self release];
			@throw e;
		}
	}

	return [super init];
}

- (id)nextObject
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFArray *)allObjects
{
	OFMutableArray *ret = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	id object;

	while ((object = [self nextObject]) != nil)
		[ret addObject: object];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (int)countByEnumeratingWithState: (OFFastEnumerationState *)state
			   objects: (id *)objects
			     count: (int)count
{
	static unsigned long dummyMutations;
	int i;

	state->itemsPtr = objects;
	state->mutationsPtr = &dummyMutations;

	for (i = 0; i < count; i++) {
		id object = [self nextObject];

		if (object == nil)
			return i;

		objects[i] = object;
	}

	return i;
}
@end
