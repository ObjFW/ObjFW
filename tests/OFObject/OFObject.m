/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import <stdio.h>
#import <stdlib.h>
#import <stdbool.h>

#import "OFObject.h"
#import "OFExceptions.h"

int
main()
{
	OFObject *obj = [OFObject new];
	bool caught;
	void *p, *q, *r;

	/* Test freeing memory not allocated by obj */
	puts("Freeing memory not allocated by object (should throw an "
	    "exception)...");
	caught = false;
	@try {
		[obj freeMem: (void*)123];
	} @catch (OFMemNotPartOfObjException *e) {
		caught = true;
		puts("CAUGHT! Resuming...");
	}
	if (!caught) {
		puts("NOT CAUGHT!");
		return 1;
	}

	/* Test allocating memory */
	puts("Allocating memory through object...");
	p = [obj getMem: 4096];
	puts("Allocated 4096 bytes.");

	/* Test freeing the just allocated memory */
	puts("Freeing just allocated memory...");
	[obj freeMem: p];
	puts("Free'd.");

	/* It shouldn't be recognized as part of our obj anymore */
	puts("Trying to free it again (should throw an exception)...");
	caught = false;
	@try {
		[obj freeMem: p];
	} @catch (OFMemNotPartOfObjException *e) {
		caught = true;
		puts("CAUGHT! Resuming...");
	}
	if (!caught) {
		puts("NOT CAUGHT!");
		return 1;
	}

	/* Test multiple memory chunks */
	puts("Allocating 3 chunks of memory...");
	p = [obj getMem: 4096];
	q = [obj getMem: 4096];
	r = [obj getMem: 4096];
	puts("Allocated 3 * 4096 bytes.");

	/* Free them */
	puts("Now freeing them...");
	[obj freeMem: p];
	[obj freeMem: q];
	[obj freeMem: r];
	puts("Freed them all.");

	/* Try to free again */
	puts("Now trying to free them again...");
	caught = false;
	@try {
		[obj freeMem: p];
	} @catch (OFMemNotPartOfObjException *e) {
		caught = true;
		puts("CAUGHT! Resuming...");
	}
	if (!caught) {
		puts("NOT CAUGHT!");
		return 1;
	}
	caught = false;
	@try {
		[obj freeMem: q];
	} @catch (OFMemNotPartOfObjException *e) {
		caught = true;
		puts("CAUGHT! Resuming...");
	}
	if (!caught) {
		puts("NOT CAUGHT!");
		return 1;
	}
	caught = false;
	@try {
		[obj freeMem: r];
	} @catch (OFMemNotPartOfObjException *e) {
		caught = true;
		puts("CAUGHT! Resuming...");
	}
	if (!caught) {
		puts("NOT CAUGHT!");
		return 1;
	}
	puts("Got all 3!");
	
	/* TODO: Test if freeing object frees all memory */

	return 0;
}
