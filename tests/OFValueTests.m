/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFValueTests: OTTestCase
@end

@implementation OFValueTests
- (void)testObjCType
{
	OFRange range = OFMakeRange(1, 64);
	OFValue *value = [OFValue valueWithBytes: &range
					objCType: @encode(OFRange)];

	OTAssertEqual(strcmp(value.objCType, @encode(OFRange)), 0);
}

- (void)testGetValueSize
{
	OFRange range = OFMakeRange(1, 64), range2;
	OFValue *value = [OFValue valueWithBytes: &range
					objCType: @encode(OFRange)];

	[value getValue: &range2 size: sizeof(OFRange)];
	OTAssert(OFEqualRanges(range2, range));
}

- (void)testGetValueSizeThrowsOnWrongSize
{
	OFRange range = OFMakeRange(1, 64);
	OFValue *value = [OFValue valueWithBytes: &range
					objCType: @encode(OFRange)];

	OTAssertThrowsSpecific(
	    [value getValue: &range size: sizeof(OFRange) - 1],
	    OFOutOfRangeException);
}

- (void)testPointer
{
	void *pointer = &pointer;
	OFValue *value = [OFValue valueWithPointer: pointer];

	OTAssertEqual(value.pointerValue, pointer);
	OTAssertEqual([[OFValue valueWithBytes: &pointer
				      objCType: @encode(void *)] pointerValue],
	    pointer);

	OTAssertThrowsSpecific(
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] pointerValue],
	    OFOutOfRangeException);
}

- (void)testNonretainedObject
{
	id object = (id)&object;
	OFValue *value = [OFValue valueWithNonretainedObject: object];

	OTAssertEqual(value.nonretainedObjectValue, object);
	OTAssertEqual([[OFValue
	    valueWithBytes: &object
		  objCType: @encode(id)] nonretainedObjectValue], object);

	OTAssertThrowsSpecific(
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] nonretainedObjectValue],
	    OFOutOfRangeException);
}

- (void)testRange
{
	OFRange range = OFMakeRange(1, 64), range2;
	OFValue *value = [OFValue valueWithRange: range];

	OTAssert(OFEqualRanges(value.rangeValue, range));
	OTAssert(OFEqualRanges(
	    [[OFValue valueWithBytes: &range
			    objCType: @encode(OFRange)] rangeValue], range));

	[value getValue: &range2 size: sizeof(range2)];
	OTAssert(OFEqualRanges(range2, range));

	OTAssertThrowsSpecific(
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] rangeValue],
	    OFOutOfRangeException);
}

- (void)testPoint
{
	OFPoint point = OFMakePoint(1.5f, 3.0f), point2;
	OFValue *value = [OFValue valueWithPoint: point];

	OTAssert(OFEqualPoints(value.pointValue, point));
	OTAssert(OFEqualPoints(
	    [[OFValue valueWithBytes: &point
			    objCType: @encode(OFPoint)] pointValue], point));

	[value getValue: &point2 size: sizeof(point2)];
	OTAssert(OFEqualPoints(point2, point));

	OTAssertThrowsSpecific(
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] pointValue],
	    OFOutOfRangeException);
}

- (void)testSize
{
	OFSize size = OFMakeSize(4.5f, 5.0f), size2;
	OFValue *value = [OFValue valueWithSize: size];

	OTAssert(OFEqualSizes(value.sizeValue, size));
	OTAssert(OFEqualSizes(
	    [[OFValue valueWithBytes: &size
			    objCType: @encode(OFSize)] sizeValue], size));

	[value getValue: &size2 size: sizeof(size2)];
	OTAssert(OFEqualSizes(size2, size));

	OTAssertThrowsSpecific(
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] sizeValue],
	    OFOutOfRangeException);
}

- (void)testRect
{
	OFRect rect = OFMakeRect(1.5f, 3.0f, 4.5f, 6.0f), rect2;
	OFValue *value = [OFValue valueWithRect: rect];

	OTAssert(OFEqualRects(value.rectValue, rect));
	OTAssert(OFEqualRects(
	    [[OFValue valueWithBytes: &rect
			    objCType: @encode(OFRect)] rectValue], rect));

	[value getValue: &rect2 size: sizeof(rect2)];
	OTAssert(OFEqualRects(rect2, rect));

	OTAssertThrowsSpecific(
	    [[OFValue valueWithBytes: "a" objCType: @encode(char)] rectValue],
	    OFOutOfRangeException);
}

- (void)testIsEqual
{
	OFRect rect = OFMakeRect(1.5f, 3.0f, 4.5f, 6.0f);

	OTAssertEqualObjects([OFValue valueWithRect: rect],
	    [OFValue valueWithBytes: &rect
			   objCType: @encode(OFRect)]);
	OTAssertNotEqualObjects(
	    [OFValue valueWithBytes: "a" objCType: @encode(signed char)],
	    [OFValue valueWithBytes: "a" objCType: @encode(unsigned char)]);
	OTAssertNotEqualObjects(
	    [OFValue valueWithBytes: "a" objCType: @encode(char)],
	    [OFValue valueWithBytes: "b" objCType: @encode(char)]);
}
@end
