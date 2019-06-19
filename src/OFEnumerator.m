/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id *)objects
			     count: (int)count
{
	int i;

	state->itemsPtr = objects;
	state->mutationsPtr = (unsigned long *)self;

	for (i = 0; i < count; i++) {
		id object = [self nextObject];

		if (object == nil)
			return i;

		objects[i] = object;
	}

	return i;
}
@end
