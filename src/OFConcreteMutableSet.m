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

#import "OFConcreteMutableSet.h"
#import "OFConcreteSet.h"
#import "OFMapTable.h"

@implementation OFConcreteMutableSet
+ (void)initialize
{
	if (self == [OFConcreteMutableSet class])
		[self inheritMethodsFromClass: [OFConcreteSet class]];
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
	object_setClass(self, [OFConcreteSet class]);
}
@end
