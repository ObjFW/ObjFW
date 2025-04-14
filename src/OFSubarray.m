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

#import "OFSubarray.h"

#import "OFOutOfRangeException.h"

@implementation OFSubarray
- (instancetype)initWithArray: (OFArray *)array range: (OFRange)range
{
	self = [super init];

	@try {
		/* Should usually be retain, as it's useless with a copy */
		_array = [array copy];
		_range = range;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_array);

	[super dealloc];
}

- (size_t)count
{
	return _range.length;
}

- (id)objectAtIndex: (size_t)idx
{
	if (idx >= _range.length)
		@throw [OFOutOfRangeException exception];

	return [_array objectAtIndex: idx + _range.location];
}

- (void)getObjects: (id *)buffer inRange: (OFRange)range
{
	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _range.length)
		@throw [OFOutOfRangeException exception];

	range.location += _range.location;

	[_array getObjects: buffer inRange: range];
}

- (size_t)indexOfObject: (id)object
{
	size_t idx = [_array indexOfObject: object];

	if (idx < _range.location)
		return OFNotFound;

	idx -= _range.location;

	if (idx >= _range.length)
		return OFNotFound;

	return idx;
}

- (size_t)indexOfObjectIdenticalTo: (id)object
{
	size_t idx = [_array indexOfObjectIdenticalTo: object];

	if (idx < _range.location)
		return OFNotFound;

	idx -= _range.location;

	if (idx >= _range.length)
		return OFNotFound;

	return idx;
}

- (OFArray *)objectsInRange: (OFRange)range
{
	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _range.length)
		@throw [OFOutOfRangeException exception];

	range.location += _range.location;

	return [_array objectsInRange: range];
}
@end
