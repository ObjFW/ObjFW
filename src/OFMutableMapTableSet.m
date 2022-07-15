/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFMutableMapTableSet.h"
#import "OFMapTableSet.h"
#import "OFMapTable.h"

@implementation OFMutableMapTableSet
+ (void)initialize
{
	if (self == [OFMutableMapTableSet class])
		[self inheritMethodsFromClass: [OFMapTableSet class]];
}

- (void)addObject: (id)object
{
	[_mapTable setObject: (void *)1 forKey: object];
}

- (void)removeObject: (id)object
{
	[_mapTable removeObjectForKey: object];
}

- (void)removeAllObjects
{
	[_mapTable removeAllObjects];
}

- (void)makeImmutable
{
	object_setClass(self, [OFMapTableSet class]);
}
@end
