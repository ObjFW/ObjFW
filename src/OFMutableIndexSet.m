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

- (void)addIndex: (size_t)index
{
	[self addIndexesInRange: OFMakeRange(index, 1)];
}

- (void)addIndexesInRange: (OFRange)range
{
	OFRange *ranges = _ranges.mutableItems;
	size_t count = _ranges.count;

	for (size_t i = 0; i < count; i++) {
		/*
		 * Try merging the new range with both the current and next
		 * range. If we can merge with both, we just filled a gap and
		 * can replace all 3 with one big range.  Otherwise, try
		 * merging with the current first and then try merging with the
		 * next. Failing all merges, insert the new range.
		 */
		OFRange mergedCurrent = OFMergeRanges(range, ranges[i]);
		OFRange mergedNext;

		if (i + 1 < count) {
			OFRange merged3;

			mergedNext = OFMergeRanges(range, ranges[i + 1]);
			merged3 = OFMergeRanges(mergedCurrent, mergedNext);

			if (merged3.location != OFNotFound) {
				_count -= ranges[i].length;
				_count -= ranges[i + 1].length;
				_count += merged3.length;
				ranges[i] = merged3;

				[_ranges removeItemAtIndex: i + 1];

				return;
			}
		}

		if (mergedCurrent.location != OFNotFound) {
			_count += mergedCurrent.length - ranges[i].length;
			ranges[i] = mergedCurrent;
			return;
		}

		if (i + 1 < count && mergedNext.location != OFNotFound) {
			_count += mergedNext.length - ranges[i + 1].length;
			ranges[i + 1] = mergedNext;
			return;
		}

		if (range.location < OFEndOfRange(ranges[i])) {
			[_ranges insertItem: &range atIndex: i];
			_count += range.length;
			return;
		}
	}

	[_ranges addItem: &range];
	_count += range.length;
}
@end
