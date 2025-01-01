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

@interface OFNumberTests: OTTestCase
{
	OFNumber *_number;
}
@end

@implementation OFNumberTests
- (void)setUp
{
	[super setUp];

	_number = [[OFNumber alloc] initWithLongLong: 123456789];
}

- (void)dealloc
{
	[_number release];

	[super dealloc];
}

- (void)testIsEqual
{
	OTAssertEqualObjects(_number, [OFNumber numberWithLong: 123456789]);
}

- (void)testHash
{
	OTAssertEqual(_number.hash,
	    [[OFNumber numberWithLong: 123456789] hash]);
}

- (void)testCharValue
{
	OTAssertEqual(_number.charValue, 21);
}

- (void)testDoubleValue
{
	OTAssertEqual(_number.doubleValue, 123456789.L);
}

- (void)testSignedCharMinAndMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithChar: SCHAR_MIN] charValue],
	    SCHAR_MIN);
	OTAssertEqual([[OFNumber numberWithChar: SCHAR_MAX] charValue],
	    SCHAR_MAX);
}

- (void)testShortMinAndMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithShort: SHRT_MIN] shortValue],
	    SHRT_MIN);
	OTAssertEqual([[OFNumber numberWithShort: SHRT_MAX] shortValue],
	    SHRT_MAX);
}

- (void)testIntMinAndMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithInt: INT_MIN] intValue], INT_MIN);
	OTAssertEqual([[OFNumber numberWithInt: INT_MAX] intValue], INT_MAX);
}

- (void)testLongMinAndMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithLong: LONG_MIN] longValue],
	    LONG_MIN);
	OTAssertEqual([[OFNumber numberWithLong: LONG_MAX] longValue],
	    LONG_MAX);;
}

- (void)testLongLongMinAndMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithLongLong: LLONG_MIN] longLongValue],
	    LLONG_MIN);
	OTAssertEqual([[OFNumber numberWithLongLong: LLONG_MAX] longLongValue],
	    LLONG_MAX);
}

- (void)testUnsignedCharMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithUnsignedChar: UCHAR_MAX]
	    unsignedCharValue], UCHAR_MAX);
}

- (void)testUnsignedShortMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithUnsignedShort: USHRT_MAX]
	    unsignedShortValue], USHRT_MAX);
}

- (void)testUnsignedIntMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithUnsignedInt: UINT_MAX]
	    unsignedIntValue], UINT_MAX);
}

- (void)testUnsignedLongMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithUnsignedLong: ULONG_MAX]
	    unsignedLongValue], ULONG_MAX);
}

- (void)testUnsignedLongLongMaxUnmodified
{
	OTAssertEqual([[OFNumber numberWithUnsignedLongLong: ULLONG_MAX]
	    unsignedLongLongValue], ULLONG_MAX);
}
@end
