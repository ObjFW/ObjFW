/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFMemoryNotPartOfObjectException.h"
#import "OFOutOfMemoryException.h"

#import "TestsAppDelegate.h"

#if defined(OF_DRAGONFLYBSD) && defined(__LP64__)
# define TOO_BIG (SIZE_MAX / 3)
#else
# define TOO_BIG (SIZE_MAX - 128)
#endif

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
	char *tmp;

	TEST(@"Allocating 4096 bytes",
	    (p = [obj allocMemoryWithSize: 4096]) != NULL)

	TEST(@"Freeing memory", R([obj freeMemory: p]))

	TEST(@"Allocating and freeing 4096 bytes 3 times",
	    (p = [obj allocMemoryWithSize: 4096]) != NULL &&
	    (q = [obj allocMemoryWithSize: 4096]) != NULL &&
	    (r = [obj allocMemoryWithSize: 4096]) != NULL &&
	    R([obj freeMemory: p]) && R([obj freeMemory: q]) &&
	    R([obj freeMemory: r]))

	tmp = [self allocMemoryWithSize: 1024];
	EXPECT_EXCEPTION(@"Detect freeing of memory not allocated by object",
	    OFMemoryNotPartOfObjectException, [obj freeMemory: tmp])

	EXPECT_EXCEPTION(@"Detect out of memory on alloc",
	    OFOutOfMemoryException, [obj allocMemoryWithSize: TOO_BIG])

	EXPECT_EXCEPTION(@"Detect out of memory on resize",
	    OFOutOfMemoryException,
	    {
		p = [obj allocMemoryWithSize: 1];
		[obj resizeMemory: p
			     size: TOO_BIG];
	    })
	[obj freeMemory: p];

	TEST(@"Allocate when trying to resize NULL",
	    (p = [obj resizeMemory: NULL
			      size: 1024]) != NULL)
	[obj freeMemory: p];

	EXPECT_EXCEPTION(@"Detect resizing of memory not allocated by object",
	    OFMemoryNotPartOfObjectException, [obj resizeMemory: tmp
							   size: 2048])
	[self freeMemory: tmp];

	TEST(@"+[description]",
	    [[OFObject description] isEqual: @"OFObject"] &&
	    [[MyObj description] isEqual: @"MyObj"])

	o = [[[OFObject alloc] init] autorelease];
	m = [[[MyObj alloc] init] autorelease];

	TEST(@"-[description]",
	    [[o description] isEqual:
	    [OFString stringWithFormat: @"<OFObject: %p>", o]] &&
	    [[m description] isEqual:
	    [OFString stringWithFormat: @"<MyObj: %p>", m]])

	[pool drain];
}
@end
