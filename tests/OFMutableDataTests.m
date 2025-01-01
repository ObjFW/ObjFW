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

#include <string.h>

#import "OFDataTests.h"

@interface OFMutableDataTests: OFDataTests
{
	OFMutableData *_mutableData;
}
@end

@implementation OFMutableDataTests
- (Class)dataClass
{
	return [OFMutableData class];
}

- (void)setUp
{
	[super setUp];

	_mutableData = [[OFMutableData alloc] initWithItems: "abcdef" count: 6];
}

- (void)dealloc
{
	[_mutableData release];

	[super dealloc];
}

- (void)testMutableCopy
{
	OTAssertEqualObjects([[_data mutableCopy] autorelease], _data);
	OTAssertNotEqual([[_data mutableCopy] autorelease], _data);
}

- (void)testAddItem
{
	[_mutableData addItem: "g"];

	OTAssertEqualObjects(_mutableData,
	    [OFData dataWithItems: "abcdefg" count: 7]);
}

- (void)testAddItemsCount
{
	[_mutableData addItems: "gh" count: 2];

	OTAssertEqualObjects(_mutableData,
	    [OFData dataWithItems: "abcdefgh" count: 8]);
}

- (void)testAddItemsCountThrowsOnOutOfRange
{
	OTAssertThrowsSpecific([_mutableData addItems: "" count: SIZE_MAX],
	    OFOutOfRangeException);
}

- (void)testRemoveLastItem
{
	[_mutableData removeLastItem];

	OTAssertEqualObjects(_mutableData,
	    [OFData dataWithItems: "abcde" count: 5]);
}

- (void)testRemoveItemsInRange
{
	[_mutableData removeItemsInRange: OFMakeRange(1, 2)];

	OTAssertEqualObjects(_mutableData,
	    [OFData dataWithItems: "adef" count: 4]);
}

- (void)testRemoveItemsInRangeThrowsOnOutOfRangeRange
{
	OTAssertThrowsSpecific(
	    [_mutableData removeItemsInRange: OFMakeRange(6, 1)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [_mutableData removeItemsInRange: OFMakeRange(7, 0)],
	    OFOutOfRangeException);
}

- (void)testInsertItemsAtIndexCount
{
	[_mutableData insertItems: "BC" atIndex: 1 count: 2];

	OTAssertEqualObjects(_mutableData,
	    [OFData dataWithItems: "aBCbcdef" count: 8]);
}

- (void)testInsertItemsAtIndexCountThrowsOnOutOfRangeIndex
{
	OTAssertThrowsSpecific(
	    [_mutableData insertItems: "a" atIndex: 7 count: 1],
	    OFOutOfRangeException);
}
@end
