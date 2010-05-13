/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFString.h"
#import "OFNumber.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFNumber";

@implementation TestsAppDelegate (OFNumberTests)
- (void)numberTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFNumber *num;

	TEST(@"+[numberWithIntMax:]",
	    (num = [OFNumber numberWithIntMax: 123456789]))

	TEST(@"-[isEqual:]",
	    [num isEqual: [OFNumber numberWithUInt32: 123456789]])

	TEST(@"-[hash]", [num hash] == 123456789)

	TEST(@"-[asDouble]", [num doubleValue] == 123456789.L)

	TEST(@"-[numberByDecreasing]",
	    [[num numberByDecreasing]
	    isEqual: [OFNumber numberWithInt32: 123456788]])

	TEST(@"-[numberByDividingBy:]",
	    [[num numberByDividingWithNumber: [OFNumber numberWithInt: 2]]
	    intValue] == 61728394)

	TEST(@"-[numberByXORing:]",
	    [[num numberByXORingWithNumber: [OFNumber numberWithInt: 123456831]]
	    intValue] == 42)

	TEST(@"-[numberByShiftingRightBy:]",
	    [[num numberByShiftingRightWithNumber: [OFNumber numberWithInt: 8]]
	    intValue] == 482253)

	TEST(@"-[remainderOfDivisionWithNumber:]",
	    [[num remainderOfDivisionWithNumber: [OFNumber numberWithInt: 11]]
	    intValue] == 5)

	[pool drain];
}
@end
