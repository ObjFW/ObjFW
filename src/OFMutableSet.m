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

#define OF_MUTABLE_SET_M

#import "OFMutableSet.h"
#import "OFDictionary.h"
#import "OFNull.h"
#import "OFAutoreleasePool.h"

@implementation OFMutableSet
- (void)addObject: (id)object
{
	[dictionary _setObject: [OFNull null]
			forKey: object
		       copyKey: NO];

	mutations++;
}

- (void)removeObject: (id)object
{
	[dictionary removeObjectForKey: object];

	mutations++;
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count
{
	int ret = [super countByEnumeratingWithState: state
					     objects: objects
					       count: count];

	state->mutationsPtr = &mutations;

	return ret;
}
@end
