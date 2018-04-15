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

#import "OFLocalization.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

@implementation TestsAppDelegate (OFLocalizationTests)
- (void)localizationTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *msg;

	msg = [OFString stringWithFormat:
	     @"[OFLocalization] Language: %@\n", [OFLocalization language]];
	[self outputString: msg
		   inColor: GREEN];

	msg = [OFString stringWithFormat:
	    @"[OFLocalization] Territory: %@\n", [OFLocalization territory]];
	[self outputString: msg
		   inColor: GREEN];

	msg = [OFString stringWithFormat:
	    @"[OFLocalization] Encoding: %@\n",
	    of_string_name_of_encoding([OFLocalization encoding])];
	[self outputString: msg
		   inColor: GREEN];

	msg = [OFString stringWithFormat:
	    @"[OFLocalization] Decimal point: %@\n",
	    [OFLocalization decimalPoint]];
	[self outputString: msg
		   inColor: GREEN];

	[pool drain];
}
@end
