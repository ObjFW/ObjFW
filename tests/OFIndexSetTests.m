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

@interface OFIndexSetTests: OTTestCase
{
	OFIndexSet *_indexSet;
}
@end

@implementation OFIndexSetTests
- (void)setUp
{
	OFMutableIndexSet *indexSet;

	[super setUp];

	indexSet = [OFMutableIndexSet indexSet];
	[indexSet addIndexesInRange: OFMakeRange(1, 2)];
	[indexSet addIndexesInRange: OFMakeRange(4, 3)];
	[indexSet addIndexesInRange: OFMakeRange(9, 2)];

	_indexSet = [indexSet copy];
}

- (void)dealloc
{
	objc_release(_indexSet);

	[super dealloc];
}

- (void)testContainsIndex
{
	OTAssertFalse([_indexSet containsIndex: 0]);
	OTAssertTrue([_indexSet containsIndex: 1]);
	OTAssertTrue([_indexSet containsIndex: 2]);
	OTAssertFalse([_indexSet containsIndex: 3]);
	OTAssertTrue([_indexSet containsIndex: 4]);
	OTAssertTrue([_indexSet containsIndex: 5]);
	OTAssertTrue([_indexSet containsIndex: 6]);
	OTAssertFalse([_indexSet containsIndex: 7]);
	OTAssertFalse([_indexSet containsIndex: 8]);
	OTAssertTrue([_indexSet containsIndex: 9]);
	OTAssertTrue([_indexSet containsIndex: 10]);
	OTAssertFalse([_indexSet containsIndex: 11]);
}

- (void)testContainsIndexesInRange
{
	OFIndexSet *indexSet;

	indexSet = [OFIndexSet indexSetWithIndexesInRange: OFMakeRange(1, 3)];
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(1, 1)]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(1, 2)]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(1, 3)]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(2, 1)]);
	OTAssertTrue([indexSet containsIndexesInRange: OFMakeRange(3, 1)]);
	OTAssertFalse([indexSet containsIndexesInRange: OFMakeRange(4, 1)]);
	OTAssertFalse([indexSet containsIndexesInRange: OFMakeRange(1, 4)]);
	OTAssertFalse([indexSet containsIndexesInRange: OFMakeRange(0, 3)]);
}

- (void)testCount
{
	OFIndexSet *indexSet;

	indexSet = [OFIndexSet indexSetWithIndexesInRange: OFMakeRange(1, 3)];
	OTAssertEqual(indexSet.count, 3);
	indexSet = [OFIndexSet indexSetWithIndexesInRange: OFMakeRange(0, 1)];
	OTAssertEqual(indexSet.count, 1);
}

- (void)testFirstIndex
{
	OTAssertEqual(_indexSet.firstIndex, 1);
}

- (void)testLastIndex
{
	OTAssertEqual(_indexSet.lastIndex, 10);
}

- (void)testIndexGreaterThanIndex
{
	OTAssertEqual([_indexSet indexGreaterThanIndex: 0], 1);
	OTAssertEqual([_indexSet indexGreaterThanIndex: 1], 2);
	OTAssertEqual([_indexSet indexGreaterThanIndex: 2], 4);
	OTAssertEqual([_indexSet indexGreaterThanIndex: 3], 4);
	OTAssertEqual([_indexSet indexGreaterThanIndex: 4], 5);
	OTAssertEqual([_indexSet indexGreaterThanIndex: 5], 6);
	OTAssertEqual([_indexSet indexGreaterThanIndex: 6], 9);
	OTAssertEqual([_indexSet indexGreaterThanIndex: 7], 9);
	OTAssertEqual([_indexSet indexGreaterThanIndex: 8], 9);
	OTAssertEqual([_indexSet indexGreaterThanIndex: 9], 10);
	OTAssertEqual([_indexSet indexGreaterThanIndex: 10], OFNotFound);
}

- (void)testIndexGreaterThanOrEqualToIndex
{
	OTAssertEqual([_indexSet indexGreaterThanOrEqualToIndex: 0], 1);
	OTAssertEqual([_indexSet indexGreaterThanOrEqualToIndex: 1], 1);
	OTAssertEqual([_indexSet indexGreaterThanOrEqualToIndex: 2], 2);
	OTAssertEqual([_indexSet indexGreaterThanOrEqualToIndex: 3], 4);
	OTAssertEqual([_indexSet indexGreaterThanOrEqualToIndex: 4], 4);
	OTAssertEqual([_indexSet indexGreaterThanOrEqualToIndex: 5], 5);
	OTAssertEqual([_indexSet indexGreaterThanOrEqualToIndex: 6], 6);
	OTAssertEqual([_indexSet indexGreaterThanOrEqualToIndex: 7], 9);
	OTAssertEqual([_indexSet indexGreaterThanOrEqualToIndex: 8], 9);
	OTAssertEqual([_indexSet indexGreaterThanOrEqualToIndex: 9], 9);
	OTAssertEqual([_indexSet indexGreaterThanOrEqualToIndex: 10], 10);
	OTAssertEqual(
	    [_indexSet indexGreaterThanOrEqualToIndex: 11], OFNotFound);
}

- (void)testIndexLessThanIndex
{
	OTAssertEqual([_indexSet indexLessThanIndex: 0], OFNotFound);
	OTAssertEqual([_indexSet indexLessThanIndex: 1], OFNotFound);
	OTAssertEqual([_indexSet indexLessThanIndex: 2], 1);
	OTAssertEqual([_indexSet indexLessThanIndex: 3], 2);
	OTAssertEqual([_indexSet indexLessThanIndex: 4], 2);
	OTAssertEqual([_indexSet indexLessThanIndex: 5], 4);
	OTAssertEqual([_indexSet indexLessThanIndex: 6], 5);
	OTAssertEqual([_indexSet indexLessThanIndex: 7], 6);
	OTAssertEqual([_indexSet indexLessThanIndex: 8], 6);
	OTAssertEqual([_indexSet indexLessThanIndex: 9], 6);
	OTAssertEqual([_indexSet indexLessThanIndex: 10], 9);
	OTAssertEqual([_indexSet indexLessThanIndex: 11], 10);
	OTAssertEqual([_indexSet indexLessThanIndex: 12], 10);
}

- (void)testIndexLessThanOrEqualToIndex
{
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 0], OFNotFound);
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 1], 1);
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 2], 2);
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 3], 2);
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 4], 4);
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 5], 5);
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 6], 6);
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 7], 6);
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 8], 6);
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 9], 9);
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 10], 10);
	OTAssertEqual([_indexSet indexLessThanOrEqualToIndex: 11], 10);
}

- (void)testGetIndexesMaxCountInIndexRange
{
	size_t indexes[7];
	OFRange range;

	OTAssertEqual([_indexSet getIndexes: indexes
				   maxCount: 7
			       inIndexRange: NULL], 7);
	OTAssertEqual(indexes[0], 1);
	OTAssertEqual(indexes[1], 2);
	OTAssertEqual(indexes[2], 4);
	OTAssertEqual(indexes[3], 5);
	OTAssertEqual(indexes[4], 6);
	OTAssertEqual(indexes[5], 9);
	OTAssertEqual(indexes[6], 10);

	range = OFMakeRange(0, 6);
	OTAssertEqual([_indexSet getIndexes: indexes
				   maxCount: 7
			       inIndexRange: &range], 4);
	OTAssertEqual(indexes[0], 1);
	OTAssertEqual(indexes[1], 2);
	OTAssertEqual(indexes[2], 4);
	OTAssertEqual(indexes[3], 5);

	range = OFMakeRange(10, 10);
	OTAssertEqual([_indexSet getIndexes: indexes
				   maxCount: 7
			       inIndexRange: &range], 1);
	OTAssertEqual(indexes[0], 10);

	range = OFMakeRange(5, 3);
	OTAssertEqual([_indexSet getIndexes: indexes
				   maxCount: 7
			       inIndexRange: &range], 2);
	OTAssertEqual(indexes[0], 5);
	OTAssertEqual(indexes[1], 6);

	range = OFMakeRange(11, 10);
	OTAssertEqual([_indexSet getIndexes: indexes
				   maxCount: 7
			       inIndexRange: &range], 0);

	range = OFMakeRange(3, 10);
	OTAssertEqual([_indexSet getIndexes: indexes
				   maxCount: 2
			       inIndexRange: &range], 2);
	OTAssertEqual(indexes[0], 4);
	OTAssertEqual(indexes[1], 5);
}
@end
