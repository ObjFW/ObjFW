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

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#import "OFObject.h"
#import "OFExceptions.h"

#define CATCH_EXCEPTION(code, exception)		\
	@try {						\
		code;					\
							\
		puts("NOT CAUGHT!");			\
		return 1;				\
	} @catch (exception *e) {			\
		puts("CAUGHT! Error string was:");	\
		puts([[e string] cString]);		\
		puts("Resuming...");			\
	}

int
main()
{
	OFObject *obj = [[OFObject alloc] init];
	void *p, *q, *r;

	/* Test freeing memory not allocated by obj */
	puts("Freeing memory not allocated by object (should throw an "
	    "exception)...");
	CATCH_EXCEPTION([obj freeMemory: NULL],
	    OFMemoryNotPartOfObjectException)

	/* Test allocating memory */
	puts("Allocating memory through object...");
	p = [obj allocMemoryWithSize: 4096];
	puts("Allocated 4096 bytes.");

	/* Test freeing the just allocated memory */
	puts("Freeing just allocated memory...");
	[obj freeMemory: p];
	puts("Free'd.");

	/* It shouldn't be recognized as part of our obj anymore */
	puts("Trying to free it again (should throw an exception)...");
	CATCH_EXCEPTION([obj freeMemory: p], OFMemoryNotPartOfObjectException)

	/* Test multiple memory chunks */
	puts("Allocating 3 chunks of memory...");
	p = [obj allocMemoryWithSize: 4096];
	q = [obj allocMemoryWithSize: 4096];
	r = [obj allocMemoryWithSize: 4096];
	puts("Allocated 3 * 4096 bytes.");

	/* Free them */
	puts("Now freeing them...");
	[obj freeMemory: p];
	[obj freeMemory: q];
	[obj freeMemory: r];
	puts("Freed them all.");

	/* Try to free again */
	puts("Now trying to free them again...");
	CATCH_EXCEPTION([obj freeMemory: p], OFMemoryNotPartOfObjectException)
	CATCH_EXCEPTION([obj freeMemory: q], OFMemoryNotPartOfObjectException)
	CATCH_EXCEPTION([obj freeMemory: r], OFMemoryNotPartOfObjectException)
	puts("Got all 3!");

	puts("Trying to allocate more memory than possible...");
	CATCH_EXCEPTION(p = [obj allocMemoryWithSize: SIZE_MAX],
	    OFOutOfMemoryException)

	puts("Allocating 1 byte...");
	p = [obj allocMemoryWithSize: 1];

	puts("Trying to resize that 1 byte to more than possible...");
	CATCH_EXCEPTION(p = [obj resizeMemory: p
				       toSize: SIZE_MAX],
	    OFOutOfMemoryException)

	puts("Trying to resize NULL to 1024 bytes...");
	p = [obj resizeMemory: NULL
		       toSize: 1024];
	[obj freeMemory: p];

	puts("Trying to resize memory that is not part of object...");
	CATCH_EXCEPTION(p = [obj resizeMemory: (void*)1
				       toSize: 1024],
	    OFMemoryNotPartOfObjectException)

	/* TODO: Test if freeing object frees all memory */

	return 0;
}
