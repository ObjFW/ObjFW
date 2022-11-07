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

#import "OFSubarray.h"

#import "OFOutOfRangeException.h"

@implementation OFSubarray
+ (instancetype)arrayWithArray: (OFArray *)array range: (OFRange)range
{
	return [[[self alloc] initWithArray: array range: range] autorelease];
}

- (instancetype)initWithArray: (OFArray *)array range: (OFRange)range
{
	self = [super init];

	@try {
		/* Should usually be retain, as it's useless with a copy */
		_array = [array copy];
		_range = range;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_array release];

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
