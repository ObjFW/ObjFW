/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFValue.h"
#import "OFAutoreleasePool.h"

#import "OFOutOfRangeException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFValue";

@implementation TestsAppDelegate (OFValueTests)
- (void)valueTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	of_range_t range = of_range(1, 64), range2 = of_range(1, 64);
	OFValue *value;
	void *pointer = &value;

	TEST(@"+[valueWithBytes:objCType:]",
	    (value = [OFValue valueWithBytes: &range
				    objCType: @encode(of_range_t)]))

	TEST(@"-[objCType]", strcmp([value objCType], @encode(of_range_t)) == 0)

	range = of_range(OF_NOT_FOUND, 0);
	TEST(@"-[getValue:size:]",
	    R([value getValue: &range
			 size: sizeof(of_range_t)]) &&
	    memcmp(&range, &range2, sizeof(of_range_t)) == 0)

	EXPECT_EXCEPTION(@"-[getValue:size:] with wrong size throws",
	    OFOutOfRangeException,
	    [value getValue: &range
		       size: sizeof(of_range_t) - 1])

	TEST(@"+[valueWithPointer:]",
	    (value = [OFValue valueWithPointer: pointer]))

	TEST(@"-[pointerValue]",
	    [value pointerValue] == pointer &&
	    [[OFValue valueWithBytes: &pointer
			    objCType: @encode(void *)] pointerValue] == pointer)

	EXPECT_EXCEPTION(@"-[pointerValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] pointerValue])

	TEST(@"+[valueWithNonretainedObject:]",
	    (value = [OFValue valueWithNonretainedObject: pointer]))

	TEST(@"-[nonretainedObjectValue]",
	    [value nonretainedObjectValue] == pointer &&
	    [[OFValue valueWithBytes: &pointer
			    objCType: @encode(id)] pointerValue] == pointer)

	EXPECT_EXCEPTION(@"-[nonretainedObjectValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] nonretainedObjectValue])

	TEST(@"+[valueWithRange:]",
	    (value = [OFValue valueWithRange: range]))

	TEST(@"-[rangeValue]",
	    R(range = [value rangeValue]) &&
	    memcmp(&range, &range2, sizeof(of_range_t)) == 0 && R(range =
	    [[OFValue valueWithBytes: &range
			    objCType: @encode(of_range_t)] rangeValue]) &&
	    memcmp(&range, &range2, sizeof(of_range_t)) == 0)

	EXPECT_EXCEPTION(@"-[rangeValue] with wrong size throws",
	    OFOutOfRangeException,
	    [[OFValue valueWithBytes: "a"
			    objCType: @encode(char)] rangeValue])

	[pool drain];
}
@end
