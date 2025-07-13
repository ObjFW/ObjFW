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

#import "ObjFW.h"
#import "ObjFWTest.h"

#import "OFIndexSet+Private.h"

@interface OFMutableIndexSetTests: OTTestCase
@end

@implementation OFMutableIndexSetTests
- (void)testAddIndex
{
	OFMutableIndexSet *indexSet = [OFMutableIndexSet
	    indexSetWithIndexesInRange: OFMakeRange(2, 3)];
	const OFRange *ranges;

	[indexSet addIndex: 5];
	OTAssertTrue([indexSet containsIndex: 5]);
	OTAssertFalse([indexSet containsIndex: 6]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(2, 4)]);
	OTAssertFalse([indexSet containsIndexesInRange: OFMakeRange(2, 5)]);
	OTAssertEqual(indexSet.count, 4);
	OTAssertEqual(indexSet.of_ranges.count, 1);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(2, 4)));

	[indexSet addIndex: 6];
	OTAssertTrue([indexSet containsIndex: 6]);
	OTAssertFalse([indexSet containsIndex: 7]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(2, 5)]);
	OTAssertFalse([indexSet containsIndexesInRange: OFMakeRange(2, 6)]);
	OTAssertEqual(indexSet.count, 5);
	OTAssertEqual(indexSet.of_ranges.count, 1);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(2, 5)));

	[indexSet addIndex: 8];
	OTAssertTrue([indexSet containsIndex: 8]);
	OTAssertFalse([indexSet containsIndex: 7]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(2, 5)]);
	OTAssertFalse([indexSet containsIndexesInRange: OFMakeRange(2, 6)]);
	OTAssertEqual(indexSet.count, 6);
	OTAssertEqual(indexSet.of_ranges.count, 2);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(2, 5)));
	OTAssert(OFEqualRanges(ranges[1], OFMakeRange(8, 1)));
}

- (void)testAddIndexesInRange
{
	OFMutableIndexSet *indexSet = [OFMutableIndexSet
	    indexSetWithIndexesInRange: OFMakeRange(3, 3)];
	const OFRange *ranges;

	[indexSet addIndexesInRange: OFMakeRange(6, 2)];
	OTAssertTrue([indexSet containsIndex: 6]);
	OTAssertTrue([indexSet containsIndex: 7]);
	OTAssertFalse([indexSet containsIndex: 8]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(3, 5)]);
	OTAssertFalse([indexSet containsIndexesInRange: OFMakeRange(3, 6)]);
	OTAssertEqual(indexSet.count, 5);
	OTAssertEqual(indexSet.of_ranges.count, 1);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(3, 5)));

	[indexSet addIndexesInRange: OFMakeRange(7, 3)];
	OTAssertTrue([indexSet containsIndex: 8]);
	OTAssertTrue([indexSet containsIndex: 9]);
	OTAssertFalse([indexSet containsIndex: 10]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(3, 7)]);
	OTAssertFalse([indexSet containsIndexesInRange: OFMakeRange(3, 8)]);
	OTAssertEqual(indexSet.count, 7);
	OTAssertEqual(indexSet.of_ranges.count, 1);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(3, 7)));

	[indexSet addIndexesInRange: OFMakeRange(2, 1)];
	OTAssertTrue([indexSet containsIndex: 2]);
	OTAssertFalse([indexSet containsIndex: 1]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(2, 8)]);
	OTAssertFalse([indexSet containsIndexesInRange: OFMakeRange(3, 8)]);
	OTAssertEqual(indexSet.count, 8);
	OTAssertEqual(indexSet.of_ranges.count, 1);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(2, 8)));

	[indexSet addIndexesInRange: OFMakeRange(11, 2)];
	OTAssertTrue([indexSet containsIndex: 11]);
	OTAssertTrue([indexSet containsIndex: 12]);
	OTAssertFalse([indexSet containsIndex: 10]);
	OTAssertFalse([indexSet containsIndex: 13]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(11, 2)]);
	OTAssertFalse([indexSet containsIndexesInRange: OFMakeRange(12, 2)]);
	OTAssertFalse([indexSet containsIndexesInRange: OFMakeRange(10, 3)]);
	OTAssertEqual(indexSet.count, 10);
	OTAssertEqual(indexSet.of_ranges.count, 2);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(2, 8)));
	OTAssert(OFEqualRanges(ranges[1], OFMakeRange(11, 2)));

	[indexSet addIndexesInRange: OFMakeRange(0, 1)];
	OTAssertTrue([indexSet containsIndex: 0]);
	OTAssertFalse([indexSet containsIndex: 1]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(0, 1)]);
	OTAssertEqual(indexSet.count, 11);
	OTAssertEqual(indexSet.of_ranges.count, 3);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(0, 1)));
	OTAssert(OFEqualRanges(ranges[1], OFMakeRange(2, 8)));
	OTAssert(OFEqualRanges(ranges[2], OFMakeRange(11, 2)));

	[indexSet addIndexesInRange: OFMakeRange(1, 1)];
	OTAssertTrue([indexSet containsIndex: 1]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(0, 10)]);
	OTAssertEqual(indexSet.count, 12);
	OTAssertEqual(indexSet.of_ranges.count, 2);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(0, 10)));
	OTAssert(OFEqualRanges(ranges[1], OFMakeRange(11, 2)));

	[indexSet addIndexesInRange: OFMakeRange(10, 10)];
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(0, 20)]);
	OTAssertEqual(indexSet.count, 20);
	OTAssertEqual(indexSet.of_ranges.count, 1);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(0, 20)));

	indexSet = [OFMutableIndexSet indexSetWithIndex: 0];
	[indexSet addIndex: 2];
	[indexSet addIndex: 4];
	OTAssertEqual(indexSet.count, 3);
	OTAssertEqual(indexSet.of_ranges.count, 3);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(0, 1)));
	OTAssert(OFEqualRanges(ranges[1], OFMakeRange(2, 1)));
	OTAssert(OFEqualRanges(ranges[2], OFMakeRange(4, 1)));
	[indexSet addIndexesInRange: OFMakeRange(0, 4)];
	OTAssertEqual(indexSet.count, 5);
	OTAssertEqual(indexSet.of_ranges.count, 1);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(0, 5)));
}

- (void)testRemoveIndexesInRange
{
	OFMutableIndexSet *indexSet;
	const OFRange *ranges;

	indexSet =
	    [OFMutableIndexSet indexSetWithIndexesInRange: OFMakeRange(2, 4)];
	[indexSet addIndexesInRange: OFMakeRange(7, 3)];
	[indexSet removeIndexesInRange: OFMakeRange(1, 5)];
	OTAssertEqual(indexSet.count, 3);
	OTAssertEqual(indexSet.of_ranges.count, 1);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(7, 3)));

	indexSet =
	    [OFMutableIndexSet indexSetWithIndexesInRange: OFMakeRange(2, 4)];
	[indexSet addIndexesInRange: OFMakeRange(8, 3)];
	[indexSet removeIndexesInRange: OFMakeRange(2, 5)];
	OTAssertEqual(indexSet.count, 3);
	OTAssertEqual(indexSet.of_ranges.count, 1);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(8, 3)));

	indexSet =
	    [OFMutableIndexSet indexSetWithIndexesInRange: OFMakeRange(2, 4)];
	[indexSet addIndexesInRange: OFMakeRange(7, 3)];
	[indexSet removeIndexesInRange: OFMakeRange(0, 11)];
	OTAssertEqual(indexSet.count, 0);
	OTAssertEqual(indexSet.of_ranges.count, 0);

	indexSet =
	    [OFMutableIndexSet indexSetWithIndexesInRange: OFMakeRange(2, 4)];
	[indexSet addIndexesInRange: OFMakeRange(7, 3)];
	[indexSet removeIndexesInRange: OFMakeRange(2, 1)];
	OTAssertEqual(indexSet.count, 6);
	OTAssertEqual(indexSet.of_ranges.count, 2);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(3, 3)));
	OTAssert(OFEqualRanges(ranges[1], OFMakeRange(7, 3)));

	indexSet =
	    [OFMutableIndexSet indexSetWithIndexesInRange: OFMakeRange(2, 4)];
	[indexSet addIndexesInRange: OFMakeRange(7, 3)];
	[indexSet removeIndexesInRange: OFMakeRange(4, 2)];
	OTAssertEqual(indexSet.count, 5);
	OTAssertEqual(indexSet.of_ranges.count, 2);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(2, 2)));
	OTAssert(OFEqualRanges(ranges[1], OFMakeRange(7, 3)));

	indexSet =
	    [OFMutableIndexSet indexSetWithIndexesInRange: OFMakeRange(2, 4)];
	[indexSet addIndexesInRange: OFMakeRange(7, 3)];
	[indexSet removeIndexesInRange: OFMakeRange(3, 2)];
	OTAssertEqual(indexSet.count, 5);
	OTAssertEqual(indexSet.of_ranges.count, 3);
	ranges = indexSet.of_ranges.items;
	OTAssert(OFEqualRanges(ranges[0], OFMakeRange(2, 1)));
	OTAssert(OFEqualRanges(ranges[1], OFMakeRange(5, 1)));
	OTAssert(OFEqualRanges(ranges[2], OFMakeRange(7, 3)));
}

- (void)removeAllIndexes
{
	OFMutableIndexSet *indexSet =
	    [OFMutableIndexSet indexSetWithIndexesInRange: OFMakeRange(2, 4)];
	[indexSet addIndexesInRange: OFMakeRange(7, 3)];

	[indexSet removeAllIndexes];
	OTAssertEqual(indexSet.count, 0);
	OTAssertEqual(indexSet.of_ranges.count, 0);
}
@end
