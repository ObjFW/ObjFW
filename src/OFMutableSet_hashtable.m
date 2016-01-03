/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFSet_hashtable.h"
#import "OFMutableSet_hashtable.h"
#import "OFMapTable.h"

@implementation OFMutableSet_hashtable
+ (void)initialize
{
	if (self == [OFMutableSet_hashtable class])
		[self inheritMethodsFromClass: [OFSet_hashtable class]];
}

- (void)addObject: (id)object
{
	[_mapTable setValue: (void*)1
		     forKey: object];
}

- (void)removeObject: (id)object
{
	[_mapTable removeValueForKey: object];
}

- (void)makeImmutable
{
	object_setClass(self, [OFSet_hashtable class]);
}
@end
