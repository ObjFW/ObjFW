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

	TEST(@"-[asDouble]", [num asDouble] == 123456789.L)

	TEST(@"-[decrease]",
	    [[num decrease] isEqual: [OFNumber numberWithInt32: 123456788]])

	TEST(@"-[divideBy:]",
	    [[num divideBy: [OFNumber numberWithInt: 2]] asInt] == 61728394)

	TEST(@"-[xor:]",
	    [[num xor: [OFNumber numberWithInt: 123456831]] asInt] == 42)

	TEST(@"-[shiftRight:]",
	    [[num shiftRight: [OFNumber numberWithInt: 8]] asInt] == 482253)

	[pool drain];
}
@end
