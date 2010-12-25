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
#import "OFString.h"
#import "OFAutoreleasePool.h"
#import "OFArray.h"
#import "OFExceptions.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFFile";

@implementation TestsAppDelegate (OFFileTests)
- (void)fileTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFArray *tmp;

	TEST(@"+[componentsOfPath:]",
	    /* /tmp */
	    (tmp = [OFFile componentsOfPath: @"/tmp"]) &&
	    [tmp count] == 2 &&
	    [[tmp objectAtIndex: 0] isEqual: @""] &&
	    [[tmp objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* /tmp/ */
	    (tmp = [OFFile componentsOfPath: @"/tmp/"]) &&
	    [tmp count] == 2 &&
	    [[tmp objectAtIndex: 0] isEqual: @""] &&
	    [[tmp objectAtIndex: 1] isEqual: @"tmp"] &&
	    /* / */
	    (tmp = [OFFile componentsOfPath: @"/"]) &&
	    [tmp count] == 1 &&
	    [[tmp objectAtIndex: 0] isEqual: @""] &&
	    /* foo/bar */
	    (tmp = [OFFile componentsOfPath: @"foo/bar"]) &&
	    [tmp count] == 2 &&
	    [[tmp objectAtIndex: 0] isEqual: @"foo"] &&
	    [[tmp objectAtIndex: 1] isEqual: @"bar"] &&
	    /* foo/bar/baz/ */
	    (tmp = [OFFile componentsOfPath: @"foo/bar/baz"]) &&
	    [tmp count] == 3 &&
	    [[tmp objectAtIndex: 0] isEqual: @"foo"] &&
	    [[tmp objectAtIndex: 1] isEqual: @"bar"] &&
	    [[tmp objectAtIndex: 2] isEqual: @"baz"] &&
	    /* foo// */
	    (tmp = [OFFile componentsOfPath: @"foo//"]) &&
	    [tmp count] == 2 &&
	    [[tmp objectAtIndex: 0] isEqual: @"foo"] &&
	    [[tmp objectAtIndex: 1] isEqual: @""] &&
	    [[OFFile componentsOfPath: @""] count] == 0)

	TEST(@"+[lastComponentOfPath:]",
	    [[OFFile lastComponentOfPath: @"/tmp"] isEqual: @"tmp"] &&
	    [[OFFile lastComponentOfPath: @"/tmp/"] isEqual: @"tmp"] &&
	    [[OFFile lastComponentOfPath: @"/"] isEqual: @""] &&
	    [[OFFile lastComponentOfPath: @"foo"] isEqual: @"foo"] &&
	    [[OFFile lastComponentOfPath: @"foo/bar"] isEqual: @"bar"] &&
	    [[OFFile lastComponentOfPath: @"foo/bar/baz/"] isEqual: @"baz"])

	TEST(@"+[directoryNameOfPath:]",
	    [[OFFile directoryNameOfPath: @"/tmp"] isEqual: @"/"] &&
	    [[OFFile directoryNameOfPath: @"/tmp/"] isEqual: @"/"] &&
	    [[OFFile directoryNameOfPath: @"/tmp/foo/"] isEqual: @"/tmp"] &&
	    [[OFFile directoryNameOfPath: @"foo/bar"] isEqual: @"foo"] &&
	    [[OFFile directoryNameOfPath: @"/"] isEqual: @"/"] &&
	    [[OFFile directoryNameOfPath: @"foo"] isEqual: @"."])

	[pool drain];
}
@end
