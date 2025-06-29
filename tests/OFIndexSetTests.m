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
@end

@implementation OFIndexSetTests
- (void)testContainsIndex
{
	OFIndexSet *indexSet;

	indexSet = [OFIndexSet indexSetWithIndexesInRange: OFMakeRange(1, 2)];
	OTAssertFalse([indexSet containsIndex: 0]);
	OTAssertTrue([indexSet containsIndex: 1]);
	OTAssertTrue([indexSet containsIndex: 2]);
	OTAssertFalse([indexSet containsIndex: 3]);
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
@end
