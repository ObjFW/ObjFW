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

	TEST(@"-[hash]", [num hash] == 0x82D8BC42)

	TEST(@"-[charValue]", [num charValue] == 21)

	TEST(@"-[doubleValue]", [num doubleValue] == 123456789.L)

	[pool drain];
}
@end
