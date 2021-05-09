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

#import "TestsAppDelegate.h"

static OFString *const module = @"OFNumber";

@implementation TestsAppDelegate (OFNumberTests)
- (void)numberTests
{
	void *pool = objc_autoreleasePoolPush();
	OFNumber *number;

	TEST(@"+[numberWithLongLong:]",
	    (number = [OFNumber numberWithLongLong: 123456789]))

	TEST(@"-[isEqual:]",
	    [number isEqual: [OFNumber numberWithLong: 123456789]])

	TEST(@"-[hash]", number.hash == 0x82D8BC42)

	TEST(@"-[charValue]", number.charValue == 21)

	TEST(@"-[doubleValue]", number.doubleValue == 123456789.L)

	TEST(@"signed char minimum & maximum unmodified",
	    (number = [OFNumber numberWithChar: SCHAR_MIN]) &&
	    number.charValue == SCHAR_MIN &&
	    (number = [OFNumber numberWithChar: SCHAR_MAX]) &&
	    number.charValue == SCHAR_MAX)

	TEST(@"short minimum & maximum unmodified",
	    (number = [OFNumber numberWithShort: SHRT_MIN]) &&
	    number.shortValue == SHRT_MIN &&
	    (number = [OFNumber numberWithShort: SHRT_MAX]) &&
	    number.shortValue == SHRT_MAX)

	TEST(@"int minimum & maximum unmodified",
	    (number = [OFNumber numberWithInt: INT_MIN]) &&
	    number.intValue == INT_MIN &&
	    (number = [OFNumber numberWithInt: INT_MAX]) &&
	    number.intValue == INT_MAX)

	TEST(@"long minimum & maximum unmodified",
	    (number = [OFNumber numberWithLong: LONG_MIN]) &&
	    number.longValue == LONG_MIN &&
	    (number = [OFNumber numberWithLong: LONG_MAX]) &&
	    number.longValue == LONG_MAX)

	TEST(@"long long minimum & maximum unmodified",
	    (number = [OFNumber numberWithLongLong: LLONG_MIN]) &&
	    number.longLongValue == LLONG_MIN &&
	    (number = [OFNumber numberWithLongLong: LLONG_MAX]) &&
	    number.longLongValue == LLONG_MAX)

	TEST(@"unsigned char maximum unmodified",
	    (number = [OFNumber numberWithUnsignedChar: UCHAR_MAX]) &&
	    number.unsignedCharValue == UCHAR_MAX)

	TEST(@"unsigned short maximum unmodified",
	    (number = [OFNumber numberWithUnsignedShort: USHRT_MAX]) &&
	    number.unsignedShortValue == USHRT_MAX)

	TEST(@"unsigned int maximum unmodified",
	    (number = [OFNumber numberWithUnsignedInt: UINT_MAX]) &&
	    number.unsignedIntValue == UINT_MAX)

	TEST(@"unsigned long maximum unmodified",
	    (number = [OFNumber numberWithUnsignedLong: ULONG_MAX]) &&
	    number.unsignedLongValue == ULONG_MAX)

	TEST(@"unsigned long long maximum unmodified",
	    (number = [OFNumber numberWithUnsignedLongLong: ULLONG_MAX]) &&
	    number.unsignedLongLongValue == ULLONG_MAX)

	objc_autoreleasePoolPop(pool);
}
@end
