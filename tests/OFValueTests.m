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

	[pool drain];
}
@end
