/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include <string.h>

#import "OFDataTests.h"

@implementation OFDataTests
- (Class)dataClass
{
	return [OFData class];
}

- (void)setUp
{
	[super setUp];

	memset(&_items[0], 0xFF, 4096);
	memset(&_items[1], 0x42, 4096);

	_data = [[self.dataClass alloc] initWithItems: _items
						count: 2
					     itemSize: 4096];
}

- (void)dealloc
{
	[_data release];

	[super dealloc];
}

- (void)testCount
{
	OTAssertEqual(_data.count, 2);
}

- (void)testItemSize
{
	OTAssertEqual(_data.itemSize, 4096);
}

- (void)testItems
{
	OTAssertEqual(memcmp(_data.items, _items, 2 * _data.itemSize), 0);
}

- (void)testItemAtIndex
{
	OTAssertEqual(
	    memcmp([_data itemAtIndex: 1], &_items[1], _data.itemSize), 0);
}

- (void)testItemAtIndexThrowsOnOutOfRangeIndex
{
	OTAssertThrowsSpecific([_data itemAtIndex: _data.count],
	    OFOutOfRangeException);
}

- (void)testFirstItem
{
	OTAssertEqual(memcmp(_data.firstItem, &_items[0], _data.itemSize), 0);
}

- (void)testLastItem
{
	OTAssertEqual(memcmp(_data.lastItem, &_items[1], _data.itemSize), 0);
}

- (void)testIsEqual
{
	OTAssertEqualObjects(
	    _data, [OFData dataWithItems: _items count: 2 itemSize: 4096]);
	OTAssertNotEqualObjects(
	    _data, [OFData dataWithItems: _items count: 1 itemSize: 4096]);
}

- (void)testHash
{
	OTAssertEqual(_data.hash,
	    [[OFData dataWithItems: _items count: 2 itemSize: 4096] hash]);
	OTAssertNotEqual(_data.hash,
	    [[OFData dataWithItems: _items count: 1 itemSize: 4096] hash]);
}

- (void)testCompare
{
	OFData *data1 = [self.dataClass dataWithItems: "aa" count: 2];
	OFData *data2 = [self.dataClass dataWithItems: "ab" count: 2];
	OFData *data3 = [self.dataClass dataWithItems: "aaa" count: 3];

	OTAssertEqual([data1 compare: data2], OFOrderedAscending);
	OTAssertEqual([data2 compare: data1], OFOrderedDescending);
	OTAssertEqual([data1 compare: data1], OFOrderedSame);
	OTAssertEqual([data1 compare: data3], OFOrderedAscending);
	OTAssertEqual([data2 compare: data3], OFOrderedDescending);
}

- (void)testCopy
{
	OTAssertEqualObjects([[_data copy] autorelease], _data);
}

- (void)testRangeOfDataOptionsRange
{
	OFData *data = [self.dataClass dataWithItems: "aaabaccdacaabb"
					       count: 7
					    itemSize: 2];
	OFRange range;

	range = [data rangeOfData: [self.dataClass dataWithItems: "aa"
							   count: 1
							itemSize: 2]
			  options: 0
			    range: OFMakeRange(0, 7)];
	OTAssertEqual(range.location, 0);
	OTAssertEqual(range.length, 1);

	range = [data rangeOfData: [self.dataClass dataWithItems: "aa"
							   count: 1
							itemSize: 2]
			  options: OFDataSearchBackwards
			    range: OFMakeRange(0, 7)];
	OTAssertEqual(range.location, 5);
	OTAssertEqual(range.length, 1);

	range = [data rangeOfData: [self.dataClass dataWithItems: "ac"
							   count: 1
							itemSize: 2]
			  options: 0
			    range: OFMakeRange(0, 7)];
	OTAssertEqual(range.location, 2);
	OTAssertEqual(range.length, 1);

	range = [data rangeOfData: [self.dataClass dataWithItems: "aabb"
							   count: 2
							itemSize: 2]
			  options: 0
			    range: OFMakeRange(0, 7)];
	OTAssertEqual(range.location, 5);
	OTAssertEqual(range.length, 2);

	range = [data rangeOfData: [self.dataClass dataWithItems: "aa"
							   count: 1
							itemSize: 2]
			  options: 0
			    range: OFMakeRange(1, 6)];
	OTAssertEqual(range.location, 5);
	OTAssertEqual(range.length, 1);

	range = [data rangeOfData: [self.dataClass dataWithItems: "aa"
							   count: 1
							itemSize: 2]
			  options: OFDataSearchBackwards
			    range: OFMakeRange(0, 5)];
	OTAssertEqual(range.location, 0);
	OTAssertEqual(range.length, 1);
}

- (void)testRangeOfDataOptionsRangeThrowsOnDifferentItemSize
{
	OTAssertThrowsSpecific(
	    [_data rangeOfData: [OFData dataWithItems: "a" count: 1]
		       options: 0
			 range: OFMakeRange(0, 1)],
	    OFInvalidArgumentException);
}

- (void)testRangeOfDataOptionsRangeThrowsOnOutOfRangeRange
{
	OTAssertThrowsSpecific(
	    [_data rangeOfData: [OFData dataWithItemSize: 4096]
		       options: 0
			 range: OFMakeRange(1, 2)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific(
	    [_data rangeOfData: [OFData dataWithItemSize: 4096]
		       options: 0
			 range: OFMakeRange(2, 1)],
	    OFOutOfRangeException);
}

- (void)testSubdataWithRange
{
	OFData *data1 = [self.dataClass dataWithItems: "aaabaccdacaabb"
						count: 7
					     itemSize: 2];
	OFData *data2 = [self.dataClass dataWithItems: "abcde" count: 5];

	OTAssertEqualObjects(
	    [data1 subdataWithRange: OFMakeRange(2, 4)],
	    [OFData dataWithItems: "accdacaa" count: 4 itemSize: 2]);

	OTAssertEqualObjects(
	    [data2 subdataWithRange: OFMakeRange(2, 3)],
	    [OFData dataWithItems: "cde" count: 3]);
}

- (void)testSubdataWithRangeThrowsOnOutOfRangeRange
{
	OFData *data1 = [self.dataClass dataWithItems: "aaabaccdacaabb"
						count: 7
					     itemSize: 2];
	OFData *data2 = [self.dataClass dataWithItems: "abcde" count: 5];

	OTAssertThrowsSpecific([data1 subdataWithRange: OFMakeRange(7, 1)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific([data1 subdataWithRange: OFMakeRange(8, 0)],
	    OFOutOfRangeException);

	OTAssertThrowsSpecific([data2 subdataWithRange: OFMakeRange(6, 1)],
	    OFOutOfRangeException);
}

- (void)testStringByMD5Hashing
{
	OTAssertEqualObjects(_data.stringByMD5Hashing,
	    @"37d65c8816008d58175b1d71ee892de3");
}

- (void)testStringByRIPEMD160Hashing
{
	OTAssertEqualObjects(_data.stringByRIPEMD160Hashing,
	    @"ab33a6a725f9fcec6299054dc604c0eb650cd889");
}

- (void)testStringBySHA1Hashing
{
	OTAssertEqualObjects(_data.stringBySHA1Hashing,
	    @"eb50cfcc29d0bed96b3bafe03e99110bcf6663b3");
}

- (void)testStringBySHA224Hashing
{
	OTAssertEqualObjects(_data.stringBySHA224Hashing,
	    @"204f8418a914a6828f8eb27871e01f74366f6d8fac8936029ebf0041");
}

- (void)testStringBySHA256Hashing
{
	OTAssertEqualObjects(_data.stringBySHA256Hashing,
	    @"27c521859f6f5b10aeac4e210a6d005c"
	    @"85e382c594e2622af9c46c6da8906821");
}

- (void)testStringBySHA384Hashing
{
	OTAssertEqualObjects(_data.stringBySHA384Hashing,
	    @"af99a52c26c00f01fe649dcc53d7c7a0"
	    @"a9ee0150b971955be2af395708966120"
	    @"5f2634f70df083ef63b232d5b8549db4");
}

- (void)testStringBySHA512Hashing
{
	OTAssertEqualObjects(_data.stringBySHA512Hashing,
	    @"1cbd53bf8bed9b45a63edda645ee1217"
	    @"24d2f0323c865e1039ba13320bc6c66e"
	    @"c79b6cdf6d08395c612b7decb1e59ad1"
	    @"e72bfa007c2f76a823d10204d47d2e2d");
}

- (void)testStringByBase64Encoding
{
	OTAssertEqualObjects([[self.dataClass dataWithItems: "abcde" count: 5]
	    stringByBase64Encoding], @"YWJjZGU=");
}

- (void)testDataWithBase64EncodedString
{
	OTAssertEqualObjects(
	    [self.dataClass dataWithBase64EncodedString: @"YWJjZGU="],
	    [OFData dataWithItems: "abcde" count: 5]);
}
@end
