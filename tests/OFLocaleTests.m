/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

@implementation TestsAppDelegate (OFLocaleTests)
- (void)localeTests
{
	void *pool = objc_autoreleasePoolPush();

	[of_stdout setForegroundColor: [OFColor lime]];

	[of_stdout writeFormat: @"[OFLocale] Language: %@\n",
	    [OFLocale language]];

	[of_stdout writeFormat: @"[OFLocale] Territory: %@\n",
	    [OFLocale territory]];

	[of_stdout writeFormat: @"[OFLocale] Encoding: %@\n",
	    of_string_name_of_encoding([OFLocale encoding])];

	[of_stdout writeFormat: @"[OFLocale] Decimal point: %@\n",
	    [OFLocale decimalPoint]];

	objc_autoreleasePoolPop(pool);
}
@end
