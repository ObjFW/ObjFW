/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

static OFString *const module = @"OFColor";

@implementation TestsAppDelegate (OFColorTests)
- (void)colorTests
{
	void *pool = objc_autoreleasePoolPush();
	OFColor *color;
	float red, green, blue, alpha;

	TEST(@"+[colorWithRed:green:blue:alpha:]",
	    (color = [OFColor colorWithRed: 63.f / 255
				     green: 127.f / 255
				      blue: 1
				     alpha: 1]))

#ifdef OF_OBJFW_RUNTIME
	TEST(@"+[colorWithRed:green:blue:alpha:] returns tagged pointer",
	    object_isTaggedPointer(color))
#endif

	TEST(@"-[getRed:green:blue:alpha:]",
	    R([color getRed: &red green: &green blue: &blue alpha: &alpha]) &&
	    red == 63.f / 255 && green == 127.f / 255 && blue == 1 &&
	    alpha == 1)

	objc_autoreleasePoolPop(pool);
}
@end
