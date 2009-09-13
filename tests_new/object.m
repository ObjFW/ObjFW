/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#import "main.h"

static OFString *module = @"OFObject";

void
object_tests()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFObject *obj = [[[OFObject alloc] init] autorelease];
	void *p, *q, *r;

	EXPECT_EXCEPTION(@"Detect freeing of memory not allocated by object",
	    OFMemoryNotPartOfObjectException, [obj freeMemory: NULL])

	TEST(@"Allocating 4096 bytes",
	    (p = [obj allocMemoryWithSize: 4096]) != NULL)

	TEST(@"Freeing memory", [obj freeMemory: p])

	EXPECT_EXCEPTION(@"Detect freeing of memory twice",
	    OFMemoryNotPartOfObjectException, [obj freeMemory: p])

	TEST(@"Allocating and freeing 4096 bytes 3 times",
	    (p = [obj allocMemoryWithSize: 4096]) != NULL &&
	    (q = [obj allocMemoryWithSize: 4096]) != NULL &&
	    (r = [obj allocMemoryWithSize: 4096]) != NULL &&
	    [obj freeMemory: p] && [obj freeMemory: q] && [obj freeMemory: r])

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

	[pool release];
}
