/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFMutableDataTests.h"

@interface CustomMutableData: OFMutableData
{
	OFMutableData *_data;
}
@end

@implementation OFMutableDataTests
- (Class)dataClass
{
	return [CustomMutableData class];
}

- (void)setUp
{
	[super setUp];

	_mutableData = [[OFMutableData alloc] initWithItems: "abcdef" count: 6];
}

- (void)dealloc
{
	objc_release(_mutableData);

	[super dealloc];
}

- (void)testMutableCopy
{
	OTAssertEqualObjects(objc_autorelease([_data mutableCopy]), _data);
	OTAssertNotEqual(objc_autorelease([_data mutableCopy]), _data);
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

- (void)testRemoveItemsAtIndexes
{
	OFMutableIndexSet *indexes = [OFMutableIndexSet indexSet];

	[indexes addIndex: 1];
	[indexes addIndex: 3];
	[_mutableData removeItemsAtIndexes: indexes];

	OTAssertEqualObjects(_mutableData,
	    [OFData dataWithItems: "acef" count: 4]);
}

- (void)testRemoveItemsAtIndexesThrowsOnOutOfRangeRange
{
	OFIndexSet *indexes;

	indexes = [OFIndexSet indexSetWithIndexesInRange: OFMakeRange(6, 1)];
	OTAssertThrowsSpecific([_mutableData removeItemsAtIndexes: indexes],
	    OFOutOfRangeException);

	indexes = [OFIndexSet indexSetWithIndexesInRange: OFMakeRange(7, 0)];
	OTAssertThrowsSpecific([_mutableData removeItemsAtIndexes: indexes],
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

- (void)testInsertItemsAtIndexes
{
	OFMutableIndexSet *indexes = [OFMutableIndexSet indexSet];
	[indexes addIndexesInRange: OFMakeRange(1, 3)];
	[indexes addIndexesInRange: OFMakeRange(5, 2)];
	[indexes addIndexesInRange: OFMakeRange(11, 2)];

	[_mutableData insertItems: "1234567" atIndexes: indexes];

	OTAssertEqualObjects(_mutableData,
	    [OFData dataWithItems: "a123b45cdef67" count: 13]);
}

- (void)testInsertItemsAtIndexesThrowsOnOutOfRangeIndex
{
	OFIndexSet *indexes =
	    [OFIndexSet indexSetWithIndexesInRange: OFMakeRange(7, 1)];
	OTAssertThrowsSpecific(
	    [_mutableData insertItems: "a" atIndexes: indexes],
	    OFOutOfRangeException);
}
@end

@implementation CustomMutableData
- (instancetype)initWithItemSize: (size_t)itemSize
{
	self = [super init];

	@try {
		_data = [[OFMutableData alloc] initWithItemSize: itemSize];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithItems: (const void *)items
			count: (size_t)count
		     itemSize: (size_t)itemSize
{
	self = [super init];

	@try {
		_data = [[OFMutableData alloc] initWithItems: items
						       count: count
						    itemSize: itemSize];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
			   itemSize: (size_t)itemSize
		       freeWhenDone: (bool)freeWhenDone
{
	self = [super init];

	@try {
		_data = [[OFMutableData alloc]
		    initWithItemsNoCopy: items
				  count: count
			       itemSize: itemSize
			   freeWhenDone: freeWhenDone];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_data);

	[super dealloc];
}

- (size_t)count
{
	return _data.count;
}

- (size_t)itemSize
{
	return _data.itemSize;
}

- (const void *)items
{
	return _data.items;
}

- (void *)mutableItems
{
	return _data.mutableItems;
}

- (void)insertItems: (const void *)items
	    atIndex: (size_t)idx
	      count: (size_t)count
{
	[_data insertItems: items atIndex: idx count: count];
}

- (void)increaseCountBy: (size_t)count
{
	[_data increaseCountBy: count];
}

- (void)removeItemsInRange: (OFRange)range
{
	[_data removeItemsInRange: range];
}
@end
