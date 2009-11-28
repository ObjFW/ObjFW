/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFArray.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

#import "main.h"

static OFString *module = @"OFArray";
static OFString *c_ary[] = {
	@"Foo",
	@"Bar",
	@"Baz",
	nil
};

void
array_tests()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFArray *a[3];

	TEST(@"+[array]", (a[0] = [OFMutableArray array]))

	TEST(@"+[arrayWithObjects:]",
	    (a[1] = [OFArray arrayWithObjects: @"Foo", @"Bar", @"Baz", nil]))

	TEST(@"+[arrayWithCArray:]", (a[2] = [OFArray arrayWithCArray: c_ary]))

	TEST(@"-[addObject:]", [a[0] addObject: c_ary[0]] &&
	    [a[0] addObject: c_ary[1]] && [a[0] addObject: c_ary[2]])

	TEST(@"-[count]", [a[0] count] == 3 && [a[1] count] == 3 &&
	    [a[2] count] == 3)

	TEST(@"-[isEqual:]", [a[0] isEqual: a[1]] && [a[1] isEqual: a[2]])

	TEST(@"-[objectAtIndex:]",
	    [[a[0] objectAtIndex: 0] isEqual: c_ary[0]] &&
	    [[a[0] objectAtIndex: 1] isEqual: c_ary[1]] &&
	    [[a[0] objectAtIndex: 2] isEqual: c_ary[2]] &&
	    [[a[1] objectAtIndex: 0] isEqual: c_ary[0]] &&
	    [[a[1] objectAtIndex: 1] isEqual: c_ary[1]] &&
	    [[a[1] objectAtIndex: 2] isEqual: c_ary[2]] &&
	    [[a[2] objectAtIndex: 0] isEqual: c_ary[0]] &&
	    [[a[2] objectAtIndex: 1] isEqual: c_ary[1]] &&
	    [[a[2] objectAtIndex: 2] isEqual: c_ary[2]])

	TEST(@"-[indexOfObject:]", [a[0] indexOfObject: c_ary[1]] == 1)

	TEST(@"-[indexOfObjectIdenticalTo:]",
	    [a[0] indexOfObjectIdenticalTo: c_ary[1]] == 1)

	TEST(@"-[removeObject:]",
	    [a[0] removeObject: c_ary[1]] && [a[0] count] == 2)

	TEST(@"-[removeObjectIdenticalTo:]",
	    [a[0] removeObjectIdenticalTo: c_ary[2]] && [a[0] count] == 1)

	[a[0] addObject: c_ary[0]];
	[a[0] addObject: c_ary[1]];
	TEST(@"-[removeNObjects:]", [a[0] removeNObjects: 2] &&
	    [a[0] count] == 1 && [[a[0] objectAtIndex: 0] isEqual: c_ary[0]])

	a[1] = [[a[1] mutableCopy] autorelease];
	TEST(@"-[removeObjectAtIndex:]", [a[1] removeObjectAtIndex: 1] &&
	    [a[1] count] == 2 && [[a[1] objectAtIndex: 1] isEqual: c_ary[2]])

	a[2] = [[a[2] mutableCopy] autorelease];
	TEST(@"-[removeNObjects:atIndex:]", [a[2] removeNObjects: 2
							 atIndex: 0] &&
	    [a[2] count] == 1 && [[a[2] objectAtIndex: 0] isEqual: c_ary[2]])

	EXPECT_EXCEPTION(@"Detect out of range in -[objectAtIndex:]",
	    OFOutOfRangeException, [a[0] objectAtIndex: [a[0] count]])

	EXPECT_EXCEPTION(@"Detect out of range in -[removeNItems:]",
	    OFOutOfRangeException, [a[0] removeNObjects: [a[0] count] + 1])

	[pool drain];
}
