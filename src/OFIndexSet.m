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
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

static size_t
positionForIndex(const OFRange *ranges, size_t count, size_t location)
{
	size_t min = 0, max = count - 1, middle = 0;

	while (min <= max) {
		middle = min + (max - min) / 2;

		if (OFLocationInRange(location, ranges[middle]))
			return middle;

		if (location >= OFEndOfRange(ranges[middle]))
			min = middle + 1;
		else if (location < ranges[middle].location && middle > 0)
			max = middle - 1;
		else
			return middle;
	}

	return middle;
}

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

+ (instancetype)indexSetWithIndex: (size_t)idx
{
	return objc_autoreleaseReturnValue([[self alloc] initWithIndex: idx]);
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

- (instancetype)initWithIndex: (size_t)idx
{
	return [self initWithIndexesInRange: OFMakeRange(idx, 1)];
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

- (bool)containsIndex: (size_t)idx
{
	const OFRange *ranges = _ranges.items;
	size_t count = _ranges.count, position;

	if (count == 0)
		return false;

	position = positionForIndex(ranges, count, idx);

	return OFLocationInRange(idx, ranges[position]);
}

- (bool)containsIndexesInRange: (OFRange)range
{
	const OFRange *ranges = _ranges.items;
	size_t count = _ranges.count, position;

	if (count == 0)
		return false;

	position = positionForIndex(ranges, count, range.location);

	return (range.location >= ranges[position].location &&
	    OFEndOfRange(range) <= OFEndOfRange(ranges[position]));
}

- (size_t)firstIndex
{
	if (_ranges.count == 0)
		return OFNotFound;

	return ((OFRange *)_ranges.items)[0].location;
}

- (size_t)lastIndex
{
	if (_ranges.count == 0)
		return OFNotFound;

	return OFEndOfRange(((OFRange *)_ranges.items)[_ranges.count - 1]) - 1;
}

- (size_t)indexGreaterThanIndex: (size_t)idx
{
	const OFRange *ranges = _ranges.items;
	size_t count = _ranges.count, position;

	if (count == 0)
		return OFNotFound;

	position = positionForIndex(ranges, count, idx + 1);

	if (OFLocationInRange(idx + 1, ranges[position]))
		return idx + 1;

	for (; position < count; position++)
		if (ranges[position].location > idx)
			return ranges[position].location;

	return OFNotFound;
}

- (size_t)indexGreaterThanOrEqualToIndex: (size_t)idx
{
	const OFRange *ranges = _ranges.items;
	size_t count = _ranges.count, position;

	if (count == 0)
		return OFNotFound;

	position = positionForIndex(ranges, count, idx);

	if (OFLocationInRange(idx, ranges[position]))
		return idx;

	for (; position < count; position++)
		if (ranges[position].location >= idx)
			return ranges[position].location;

	return OFNotFound;
}

- (size_t)indexLessThanIndex: (size_t)idx
{
	const OFRange *ranges = _ranges.items;
	size_t count = _ranges.count, position;

	if (idx == 0 || count == 0)
		return OFNotFound;

	position = positionForIndex(ranges, count, idx - 1);
	if (position > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if (OFLocationInRange(idx - 1, ranges[position]))
		return idx - 1;

	for (; (ssize_t)position >= 0; position--)
		if (OFEndOfRange(ranges[position]) - 1 < idx)
			return OFEndOfRange(ranges[position]) - 1;

	return OFNotFound;
}

- (size_t)indexLessThanOrEqualToIndex: (size_t)idx
{
	const OFRange *ranges = _ranges.items;
	size_t count = _ranges.count, position;

	if (count == 0)
		return OFNotFound;

	position = positionForIndex(ranges, count, idx);
	if (position > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if (OFLocationInRange(idx, ranges[position]))
		return idx;

	for (; (ssize_t)position >= 0; position--)
		if (OFEndOfRange(ranges[position]) - 1 <= idx)
			return OFEndOfRange(ranges[position]) - 1;

	return OFNotFound;
}

- (size_t)getIndexes: (size_t *)indexes
	    maxCount: (size_t)maxCount
	inIndexRange: (OFRange *)rangePtr
{
	const OFRange *ranges = _ranges.items;
	size_t count = _ranges.count, written = 0, rangeStart, rangeEnd;
	size_t position;

	if (count == 0)
		return 0;

	if (rangePtr != NULL) {
		rangeStart = rangePtr->location;
		rangeEnd = OFEndOfRange(*rangePtr);
	} else {
		rangeStart = ranges[0].location;
		rangeEnd = OFEndOfRange(ranges[count - 1]);
	}

	position = positionForIndex(ranges, count, rangeStart);

	for (; position < count && written < maxCount; position++) {
		size_t start = ranges[position].location;
		size_t end = OFEndOfRange(ranges[position]);

		if (start > rangeEnd)
			break;

		if (start < rangeStart) {
			start = rangeStart;
			if (!OFLocationInRange(start, ranges[position]))
				continue;
		}

		for (size_t i = start; i < end && i < rangeEnd &&
		    written < maxCount; i++)
			indexes[written++] = i;
	}

	return written;
}

- (size_t)countOfIndexesInRange: (OFRange)range
{
	const OFRange *ranges = _ranges.items;
	size_t count = _ranges.count, indexes = 0, position, rangeEnd;

	if (count == 0)
		return 0;

	position = positionForIndex(ranges, count, range.location);
	rangeEnd = OFEndOfRange(range);

	for (; position < count; position++) {
		size_t start = ranges[position].location;
		size_t end = OFEndOfRange(ranges[position]);

		if (start > rangeEnd)
			break;

		if (start < range.location) {
			start = range.location;
			if (!OFLocationInRange(start, ranges[position]))
				continue;
		}

		for (size_t i = start; i < end && i < rangeEnd; i++)
			indexes++;
	}

	return indexes;
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	const OFRange *ranges = _ranges.items;
	size_t count = _ranges.count;
	OFMutableString *indexes = [OFMutableString string];
	OFString *ret;

	for (size_t i = 0; i < count; i++) {
		if (indexes.length > 0)
			[indexes appendString: @", "];

		if (ranges[i].length == 1)
			[indexes appendFormat: @"%zu", ranges[i].location];
		else
			[indexes appendFormat:
			    @"%zu-%zu",
			    ranges[i].location, OFEndOfRange(ranges[i]) - 1];
	}

	ret = [[OFString alloc] initWithFormat: @"<%@: %@>",
						self.class, indexes];

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}
@end
