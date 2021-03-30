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
	of_range_t range = of_range(1, 64), range2;
	of_point_t point = of_point(1.5f, 3.0f), point2;
	of_dimension_t dimension = of_dimension(4.5f, 5.0f), dimension2;
	of_rectangle_t rectangle = of_rectangle(1.5f, 3.0f, 4.5f, 6.0f);
	of_rectangle_t rectangle2;
	OFValue *value;
	void *pointer = &value;

	TEST(@"+[valueWithBytes:objCType:]",
	    (value = [OFValue valueWithBytes: &range
				    objCType: @encode(of_range_t)]))

	TEST(@"-[objCType]", strcmp(value.objCType, @encode(of_range_t)) == 0)

	TEST(@"-[getValue:size:]",
	    R([value getValue: &range2 size: sizeof(of_range_t)]) &&
	    of_range_equal(range2, range))

	EXPECT_EXCEPTION(@"-[getValue:size:] with wrong size throws",
	    OFOutOfRangeException,
	    [value getValue: &range size: sizeof(of_range_t) - 1])

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
	    of_range_equal(value.rangeValue, range) &&
	    (value = [OFValue valueWithBytes: &range
				    objCType: @encode(of_range_t)]) &&
	    of_range_equal(value.rangeValue, range))

	TEST(@"-[getValue:size:] for OFRangeValue",
	    (value = [OFValue valueWithRange: range]) &&
	    R([value getValue: &range2 size: sizeof(range2)]) &&
	    of_range_equal(range2, range))

	EXPECT_EXCEPTION(@"-[rangeValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] rangeValue])

	TEST(@"+[valueWithPoint:]",
	    (value = [OFValue valueWithPoint: point]))

	TEST(@"-[pointValue]",
	    of_point_equal(value.pointValue, point) &&
	    (value = [OFValue valueWithBytes: &point
				    objCType: @encode(of_point_t)]) &&
	    of_point_equal(value.pointValue, point))

	TEST(@"-[getValue:size:] for OFPointValue",
	    (value = [OFValue valueWithPoint: point]) &&
	    R([value getValue: &point2 size: sizeof(point2)]) &&
	    of_point_equal(point2, point))

	EXPECT_EXCEPTION(@"-[pointValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] pointValue])

	TEST(@"+[valueWithDimension:]",
	    (value = [OFValue valueWithDimension: dimension]))

	TEST(@"-[dimensionValue]",
	    of_dimension_equal(value.dimensionValue, dimension) &&
	    (value = [OFValue valueWithBytes: &dimension
				    objCType: @encode(of_dimension_t)]) &&
	    of_dimension_equal(value.dimensionValue, dimension))

	TEST(@"-[getValue:size:] for OFDimensionValue",
	    (value = [OFValue valueWithDimension: dimension]) &&
	    R([value getValue: &dimension2 size: sizeof(dimension2)]) &&
	    of_dimension_equal(dimension2, dimension))

	EXPECT_EXCEPTION(@"-[dimensionValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] dimensionValue])

	TEST(@"+[valueWithRectangle:]",
	    (value = [OFValue valueWithRectangle: rectangle]))

	TEST(@"-[rectangleValue]",
	    of_rectangle_equal(value.rectangleValue, rectangle) &&
	    (value = [OFValue valueWithBytes: &rectangle
				    objCType: @encode(of_rectangle_t)]) &&
	    of_rectangle_equal(value.rectangleValue, rectangle))

	TEST(@"-[getValue:size:] for OFRectangleValue",
	    (value = [OFValue valueWithRectangle: rectangle]) &&
	    R([value getValue: &rectangle2 size: sizeof(rectangle2)]) &&
	    of_rectangle_equal(rectangle2, rectangle))

	EXPECT_EXCEPTION(@"-[rectangleValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] rectangleValue])

	TEST(@"-[isEqual:]",
	    [[OFValue valueWithRectangle: rectangle]
	    isEqual: [OFValue valueWithBytes: &rectangle
				    objCType: @encode(of_rectangle_t)]] &&
	    ![[OFValue valueWithBytes: "a" objCType: @encode(signed char)]
	    isEqual: [OFValue valueWithBytes: "a"
				    objCType: @encode(unsigned char)]] &&
	    ![[OFValue valueWithBytes: "a" objCType: @encode(char)]
	    isEqual: [OFValue valueWithBytes: "b" objCType: @encode(char)]])

	objc_autoreleasePoolPop(pool);
}
@end
