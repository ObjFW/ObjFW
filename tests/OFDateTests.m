/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFDate.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFDate";

@implementation TestsAppDelegate (OFDateTests)
- (void)dateTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFDate *d1, *d2;

	TEST(@"+[dateWithTimeIntervalSince1970:]",
	    (d1 = [OFDate dateWithTimeIntervalSince1970: 0]))

	TEST(@"+[dateWithTimeIntervalSince1970:microseconds:",
	    (d2 = [OFDate dateWithTimeIntervalSince1970: 3600 * 25 + 5
					   microseconds: 1]))

	TEST(@"-[description]",
	    [[d1 description] isEqual: @"1970-01-01T00:00:00Z"] &&
	    [[d2 description] isEqual: @"1970-01-02T01:00:05Z"])

	TEST(@"-[isEqual:]",
	    [d1 isEqual: [OFDate dateWithTimeIntervalSince1970: 0]] &&
	    ![d1 isEqual: [OFDate dateWithTimeIntervalSince1970: 0
						   microseconds: 1]])

	TEST(@"-[compare:]", [d1 compare: d2] == OF_ORDERED_ASCENDING)

	TEST(@"-[seconds]", [d1 second] == 0 && [d2 second] == 5)

	TEST(@"-[microsecond]",
	    [d1 microsecond] == 0 && [d2 microsecond] == 1)

	TEST(@"-[minute]", [d1 minute] == 0 && [d2 minute] == 0)

	TEST(@"-[hour]", [d1 hour] == 0 && [d2 hour] == 1)

	TEST(@"-[dayOfMonth]", [d1 dayOfMonth] == 1 && [d2 dayOfMonth] == 2)

	TEST(@"-[monthOfYear]", [d1 monthOfYear] == 1 && [d2 monthOfYear] == 1)

	TEST(@"-[year]", [d1 year] == 1970 && [d2 year] == 1970)

	TEST(@"-[dayOfWeek]", [d1 dayOfWeek] == 4 && [d2 dayOfWeek] == 5)

	TEST(@"-[dayOfYear]", [d1 dayOfYear] == 1 && [d2 dayOfYear] == 2)

	TEST(@"-[earlierDate:]", [[d1 earlierDate: d2] isEqual: d1])

	TEST(@"-[laterDate:]", [[d1 laterDate: d2] isEqual: d2])

	[pool drain];
}
@end
