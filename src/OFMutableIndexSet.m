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

#import "OFMutableIndexSet.h"
#import "OFData.h"

@implementation OFMutableIndexSet
- (instancetype)init
{
	self = [super init];

	@try {
		_ranges = [[OFMutableData alloc] init];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (id)copy
{
	return [[OFIndexSet alloc] initWithIndexSet: self];
}

- (void)addIndex: (size_t)index
{
	[self addIndexesInRange: OFMakeRange(index, 1)];
}

- (void)addIndexesInRange: (OFRange)range
{
	OFRange *ranges = _ranges.mutableItems;
	size_t count = _ranges.count;
	bool found = false;

	for (size_t i = 0; i < count; i++) {
		OFRange unionRange = OFUnionRange(range, ranges[i]);

		if (unionRange.location == OFNotFound)
			continue;

		found = true;

		_count -= ranges[i].length;
		ranges[i] = unionRange;

		/* Check if we can merge with the previous one. */
		if (i > 0) {
			unionRange = OFUnionRange(unionRange, ranges[i - 1]);

			if (unionRange.location == OFNotFound)
				continue;

			_count -= ranges[i - 1].length;
			ranges[i - 1] = unionRange;

			[_ranges removeItemAtIndex: i];
			ranges = _ranges.mutableItems;
			count--;

			i--;
		}

		_count += unionRange.length;
	}

	if (!found) {
		for (size_t i = 0; i < count; i++) {
			if (OFEndOfRange(range) < ranges[i].location) {
				[_ranges insertItem: &range atIndex: i];
				_count += range.length;
				return;
			}
		}

		[_ranges addItem: &range];
		_count += range.length;
	}
}

- (void)addIndexes: (OFIndexSet *)indexes
{
	const OFRange *ranges = indexes->_ranges.items;
	size_t count = indexes->_ranges.count;

	for (size_t i = 0; i < count; i++)
		[self addIndexesInRange: ranges[i]];
}
@end
