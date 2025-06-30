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

#import "OFIndexSet.h"
#import "OFIndexSet+Private.h"
#import "OFData.h"

#import "OFInvalidArgumentException.h"

@implementation OFIndexSet
@synthesize count = _count, of_ranges = _ranges;

+ (instancetype)indexSet
{
	return objc_autoreleaseReturnValue([[self alloc] init]);
}

+ (instancetype)indexSetWithIndexSet: (OFIndexSet *)indexSet
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithIndexSet: indexSet]);
}

+ (instancetype)indexSetWithIndex: (size_t)index
{
	return objc_autoreleaseReturnValue([[self alloc] initWithIndex: index]);
}

+ (instancetype)indexSetWithIndexesInRange: (OFRange)range
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithIndexesInRange: range]);
}

- (instancetype)init
{
	return [super init];
}

- (instancetype)initWithIndexSet: (OFIndexSet *)indexSet
{
	self = [super init];

	@try {
		_ranges = [indexSet->_ranges mutableCopy];
		_count = indexSet->_count;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithIndex: (size_t)index
{
	return [self initWithIndexesInRange: OFMakeRange(index, 1)];
}

- (instancetype)initWithIndexesInRange: (OFRange)range
{
	self = [super init];

	@try {
		if (range.location == OFNotFound)
			@throw [OFInvalidArgumentException exception];

		_ranges = [[OFMutableData alloc]
		    initWithItemSize: sizeof(OFRange)];
		[_ranges addItem: &range];
		_count = range.length;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_ranges);

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFIndexSet *other = object;

	if (![object isKindOfClass: [OFIndexSet class]])
		return false;

	return [other->_ranges isEqual: _ranges];
}

- (unsigned long)hash
{
	return _ranges.hash;
}

- (id)copy
{
	return objc_retain(self);
}

- (id)mutableCopy
{
	return [[OFMutableIndexSet alloc] initWithIndexSet: self];
}

- (bool)containsIndex: (size_t)index
{
	const OFRange *ranges = _ranges.items;
	size_t count = _ranges.count;

	for (size_t i = 0; i < count; i++) {
		if (OFLocationInRange(index, ranges[i]))
			return true;

		if (OFEndOfRange(ranges[i]) >= index)
			return false;
	}

	return false;
}

- (bool)containsIndexesInRange: (OFRange)range
{
	const OFRange *ranges = _ranges.items;
	size_t count = _ranges.count;

	for (size_t i = 0; i < count; i++) {
		if (range.location >= ranges[i].location &&
		    OFEndOfRange(range) <= OFEndOfRange(ranges[i]))
			return true;

		if (OFEndOfRange(ranges[i]) >= range.location)
			return false;
	}

	return false;
}
@end
