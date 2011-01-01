/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFString.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFObject";

@interface MyObj: OFObject
@end

@implementation MyObj
@end

@implementation TestsAppDelegate (OFObjectTests)
- (void)objectTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFObject *obj = [[[OFObject alloc] init] autorelease];
	void *p, *q, *r;
	OFObject *o;
	MyObj *m;

	EXPECT_EXCEPTION(@"Detect freeing of memory not allocated by object",
	    OFMemoryNotPartOfObjectException, [obj freeMemory: (void*)1])

	TEST(@"Allocating 4096 bytes",
	    (p = [obj allocMemoryWithSize: 4096]) != NULL)

	TEST(@"Freeing memory", R([obj freeMemory: p]))

	EXPECT_EXCEPTION(@"Detect freeing of memory twice",
	    OFMemoryNotPartOfObjectException, [obj freeMemory: p])

	TEST(@"Allocating and freeing 4096 bytes 3 times",
	    (p = [obj allocMemoryWithSize: 4096]) != NULL &&
	    (q = [obj allocMemoryWithSize: 4096]) != NULL &&
	    (r = [obj allocMemoryWithSize: 4096]) != NULL &&
	    R([obj freeMemory: p]) && R([obj freeMemory: q]) &&
	    R([obj freeMemory: r]))

	EXPECT_EXCEPTION(@"Detect out of memory on alloc",
	    OFOutOfMemoryException, [obj allocMemoryWithSize: SIZE_MAX])

	EXPECT_EXCEPTION(@"Detect out of memory on resize",
	    OFOutOfMemoryException,
	    {
		p = [obj allocMemoryWithSize: 1];
		[obj resizeMemory: p
			   toSize: SIZE_MAX];
	    })
	[obj freeMemory: p];

	TEST(@"Allocate when trying to resize NULL",
	    (p = [obj resizeMemory: NULL
			    toSize: 1024]) != NULL)
	[obj freeMemory: p];

	EXPECT_EXCEPTION(@"Detect resizing of memory not allocated by object",
	    OFMemoryNotPartOfObjectException, [obj resizeMemory: (void*)1
							 toSize: 1024])

	TEST(@"+[description]",
	    [[OFObject description] isEqual: @"OFObject"] &&
	    [[MyObj description] isEqual: @"MyObj"])

	o = [[[OFObject alloc] init] autorelease];
	m = [[[MyObj alloc] init] autorelease];

	TEST(@"-[description]",
	    [[o description] isEqual:
	    ([OFString stringWithFormat: @"<OFObject: %p>", o])] &&
	    [[m description] isEqual:
	    ([OFString stringWithFormat: @"<MyObj: %p>", m])])

	[pool drain];
}
@end
