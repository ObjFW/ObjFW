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

#define OF_MUTABLE_SET_HASHTABLE_M

#import "OFSet_hashtable.h"
#import "OFMutableSet_hashtable.h"
#import "OFMutableDictionary_hashtable.h"
#import "OFNumber.h"
#import "OFAutoreleasePool.h"

@implementation OFMutableSet_hashtable
+ (void)initialize
{
	if (self == [OFMutableSet_hashtable class])
		[self inheritMethodsFromClass: [OFSet_hashtable class]];
}

- (void)addObject: (id)object
{
	[dictionary _setObject: [OFNumber numberWithSize: 1]
			forKey: object
		       copyKey: NO];

	mutations++;
}

- (void)removeObject: (id)object
{
	[dictionary removeObjectForKey: object];

	mutations++;
}

- (void)makeImmutable
{
	isa = [OFSet_hashtable class];
}
@end
