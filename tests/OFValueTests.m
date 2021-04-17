/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

static OFString *module = @"OFValue";

@implementation TestsAppDelegate (OFValueTests)
- (void)valueTests
{
	void *pool = objc_autoreleasePoolPush();
	OFRange range = OFMakeRange(1, 64), range2;
	OFPoint point = OFMakePoint(1.5f, 3.0f), point2;
	OFSize size = OFMakeSize(4.5f, 5.0f), size2;
	OFRect rect = OFMakeRect(1.5f, 3.0f, 4.5f, 6.0f), rect2;
	OFValue *value;
	void *pointer = &value;

	TEST(@"+[valueWithBytes:objCType:]",
	    (value = [OFValue valueWithBytes: &range
				    objCType: @encode(OFRange)]))

	TEST(@"-[objCType]", strcmp(value.objCType, @encode(OFRange)) == 0)

	TEST(@"-[getValue:size:]",
	    R([value getValue: &range2 size: sizeof(OFRange)]) &&
	    OFEqualRanges(range2, range))

	EXPECT_EXCEPTION(@"-[getValue:size:] with wrong size throws",
	    OFOutOfRangeException,
	    [value getValue: &range size: sizeof(OFRange) - 1])

	TEST(@"+[valueWithPointer:]",
	    (value = [OFValue valueWithPointer: pointer]))

	TEST(@"-[pointerValue]",
	    value.pointerValue == pointer &&
	    [[OFValue valueWithBytes: &pointer
			    objCType: @encode(void *)] pointerValue] == pointer)

	EXPECT_EXCEPTION(@"-[pointerValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] pointerValue])

	TEST(@"+[valueWithNonretainedObject:]",
	    (value = [OFValue valueWithNonretainedObject: pointer]))

	TEST(@"-[nonretainedObjectValue]",
	    value.nonretainedObjectValue == pointer &&
	    [[OFValue valueWithBytes: &pointer
			    objCType: @encode(id)] pointerValue] == pointer)

	EXPECT_EXCEPTION(@"-[nonretainedObjectValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] nonretainedObjectValue])

	TEST(@"+[valueWithRange:]",
	    (value = [OFValue valueWithRange: range]))

	TEST(@"-[rangeValue]",
	    OFEqualRanges(value.rangeValue, range) &&
	    (value = [OFValue valueWithBytes: &range
				    objCType: @encode(OFRange)]) &&
	    OFEqualRanges(value.rangeValue, range))

	TEST(@"-[getValue:size:] for OFRangeValue",
	    (value = [OFValue valueWithRange: range]) &&
	    R([value getValue: &range2 size: sizeof(range2)]) &&
	    OFEqualRanges(range2, range))

	EXPECT_EXCEPTION(@"-[rangeValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] rangeValue])

	TEST(@"+[valueWithPoint:]",
	    (value = [OFValue valueWithPoint: point]))

	TEST(@"-[pointValue]",
	    OFEqualPoints(value.pointValue, point) &&
	    (value = [OFValue valueWithBytes: &point
				    objCType: @encode(OFPoint)]) &&
	    OFEqualPoints(value.pointValue, point))

	TEST(@"-[getValue:size:] for OFPointValue",
	    (value = [OFValue valueWithPoint: point]) &&
	    R([value getValue: &point2 size: sizeof(point2)]) &&
	    OFEqualPoints(point2, point))

	EXPECT_EXCEPTION(@"-[pointValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] pointValue])

	TEST(@"+[valueWithSize:]",
	    (value = [OFValue valueWithSize: size]))

	TEST(@"-[sizeValue]",
	    OFEqualSizes(value.sizeValue, size) &&
	    (value = [OFValue valueWithBytes: &size
				    objCType: @encode(OFSize)]) &&
	    OFEqualSizes(value.sizeValue, size))

	TEST(@"-[getValue:size:] for OFSizeValue",
	    (value = [OFValue valueWithSize: size]) &&
	    R([value getValue: &size2 size: sizeof(size2)]) &&
	    OFEqualSizes(size2, size))

	EXPECT_EXCEPTION(@"-[sizeValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] sizeValue])

	TEST(@"+[valueWithRect:]",
	    (value = [OFValue valueWithRect: rect]))

	TEST(@"-[rectValue]",
	    OFEqualRects(value.rectValue, rect) &&
	    (value = [OFValue valueWithBytes: &rect
				    objCType: @encode(OFRect)]) &&
	    OFEqualRects(value.rectValue, rect))

	TEST(@"-[getValue:size:] for OFRectValue",
	    (value = [OFValue valueWithRect: rect]) &&
	    R([value getValue: &rect2 size: sizeof(rect2)]) &&
	    OFEqualRects(rect2, rect))

	EXPECT_EXCEPTION(@"-[rectValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a" objCType: @encode(char)] rectValue])

	TEST(@"-[isEqual:]",
	    [[OFValue valueWithRect: rect]
	    isEqual: [OFValue valueWithBytes: &rect
				    objCType: @encode(OFRect)]] &&
	    ![[OFValue valueWithBytes: "a" objCType: @encode(signed char)]
	    isEqual: [OFValue valueWithBytes: "a"
				    objCType: @encode(unsigned char)]] &&
	    ![[OFValue valueWithBytes: "a" objCType: @encode(char)]
	    isEqual: [OFValue valueWithBytes: "b" objCType: @encode(char)]])

	objc_autoreleasePoolPop(pool);
}
@end
