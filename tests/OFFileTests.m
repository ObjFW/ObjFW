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

#import "OFFile.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFFile";

@implementation TestsAppDelegate (OFFileTests)
- (void)fileTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	TEST(@"+[lastComponentOfPath",
	    [[OFFile lastComponentOfPath: @"/tmp"] isEqual: @"tmp"] &&
	    [[OFFile lastComponentOfPath: @"/tmp/"] isEqual: @"tmp"] &&
	    [[OFFile lastComponentOfPath: @"/"] isEqual: @""] &&
	    [[OFFile lastComponentOfPath: @"foo"] isEqual: @"foo"] /* &&
	    [[OFFile lastComponentOfPath: @"foo/bar"] isEqual: @"bar"] &&
	    [[OFFile lastComponentOfPath: @"foo/bar/baz/"] isEqual: @"baz"]*/)

	[pool drain];
}
@end
