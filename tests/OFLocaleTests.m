/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

	[OFStdOut setForegroundColor: [OFColor lime]];

	[OFStdOut writeFormat: @"[OFLocale] Language code: %@\n",
	    [OFLocale languageCode]];

	[OFStdOut writeFormat: @"[OFLocale] Country code: %@\n",
	    [OFLocale countryCode]];

	[OFStdOut writeFormat: @"[OFLocale] Encoding: %@\n",
	    OFStringEncodingName([OFLocale encoding])];

	[OFStdOut writeFormat: @"[OFLocale] Decimal separator: %@\n",
	    [OFLocale decimalSeparator]];

	objc_autoreleasePoolPop(pool);
}
@end
