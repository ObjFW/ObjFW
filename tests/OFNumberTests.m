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

static OFString *module = @"OFNumber";

@implementation TestsAppDelegate (OFNumberTests)
- (void)numberTests
{
	void *pool = objc_autoreleasePoolPush();
	OFNumber *num;

	TEST(@"+[numberWithLongLong:]",
	    (num = [OFNumber numberWithLongLong: 123456789]))

	TEST(@"-[isEqual:]",
	    [num isEqual: [OFNumber numberWithLong: 123456789]])

	TEST(@"-[hash]", num.hash == 0x82D8BC42)

	TEST(@"-[charValue]", num.charValue == 21)

	TEST(@"-[doubleValue]", num.doubleValue == 123456789.L)

	TEST(@"signed char minimum & maximum unmodified",
	    (num = [OFNumber numberWithChar: SCHAR_MIN]) &&
	    num.charValue == SCHAR_MIN &&
	    (num = [OFNumber numberWithChar: SCHAR_MAX]) &&
	    num.charValue == SCHAR_MAX)

	TEST(@"short minimum & maximum unmodified",
	    (num = [OFNumber numberWithShort: SHRT_MIN]) &&
	    num.shortValue == SHRT_MIN &&
	    (num = [OFNumber numberWithShort: SHRT_MAX]) &&
	    num.shortValue == SHRT_MAX)

	TEST(@"int minimum & maximum unmodified",
	    (num = [OFNumber numberWithInt: INT_MIN]) &&
	    num.intValue == INT_MIN &&
	    (num = [OFNumber numberWithInt: INT_MAX]) &&
	    num.intValue == INT_MAX)

	TEST(@"long minimum & maximum unmodified",
	    (num = [OFNumber numberWithLong: LONG_MIN]) &&
	    num.longValue == LONG_MIN &&
	    (num = [OFNumber numberWithLong: LONG_MAX]) &&
	    num.longValue == LONG_MAX)

	TEST(@"long long minimum & maximum unmodified",
	    (num = [OFNumber numberWithLongLong: LLONG_MIN]) &&
	    num.longLongValue == LLONG_MIN &&
	    (num = [OFNumber numberWithLongLong: LLONG_MAX]) &&
	    num.longLongValue == LLONG_MAX)

	TEST(@"unsigned char maximum unmodified",
	    (num = [OFNumber numberWithUnsignedChar: UCHAR_MAX]) &&
	    num.unsignedCharValue == UCHAR_MAX)

	TEST(@"unsigned short maximum unmodified",
	    (num = [OFNumber numberWithUnsignedShort: USHRT_MAX]) &&
	    num.unsignedShortValue == USHRT_MAX)

	TEST(@"unsigned int maximum unmodified",
	    (num = [OFNumber numberWithUnsignedInt: UINT_MAX]) &&
	    num.unsignedIntValue == UINT_MAX)

	TEST(@"unsigned long maximum unmodified",
	    (num = [OFNumber numberWithUnsignedLong: ULONG_MAX]) &&
	    num.unsignedLongValue == ULONG_MAX)

	TEST(@"unsigned long long maximum unmodified",
	    (num = [OFNumber numberWithUnsignedLongLong: ULLONG_MAX]) &&
	    num.unsignedLongLongValue == ULLONG_MAX)

	objc_autoreleasePoolPop(pool);
}
@end
