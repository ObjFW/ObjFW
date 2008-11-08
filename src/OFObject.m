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

#import "config.h"

#import <stdlib.h>
#import <string.h>

#import <objc/objc-api.h>
#ifdef HAVE_OBJC_RUNTIME_H
#import <objc/runtime.h>
#endif

#import "OFObject.h"
#import "OFExceptions.h"

@implementation OFObject
- init
{
	if ((self = [super init]) != nil) {
		__memchunks = NULL;
		__memchunks_size = 0;
	}
	return self;
}

- free
{
	size_t i;

	for (i = 0; i < __memchunks_size; i++)
		free(__memchunks[i]);

	if (__memchunks != NULL)
		free(__memchunks);

	free(self);

	return nil;
}

- (void*)getMemWithSize: (size_t)size
{
	void *ptr, **memchunks;
	size_t memchunks_size;

	if (size == 0)
		return NULL;

	memchunks_size = __memchunks_size + 1;

	if (SIZE_MAX - __memchunks_size == 0 ||
	    memchunks_size > SIZE_MAX / sizeof(void*))
		[[OFOutOfRangeException newWithObject: self] raise];
	
	if ((memchunks = realloc(__memchunks,
	    memchunks_size * sizeof(void*))) == NULL)
		[[OFNoMemException newWithObject: self
					 andSize: memchunks_size] raise];

	if ((ptr = malloc(size)) == NULL) {
		free(memchunks);
		[[OFNoMemException newWithObject: self
					 andSize: size] raise];
	}

	__memchunks = memchunks;
	__memchunks[__memchunks_size] = ptr;
	__memchunks_size = memchunks_size;

	return ptr;
}

- (void*)getMemForNItems: (size_t)nitems
		  ofSize: (size_t)size
{
	size_t memsize;
	
	if (nitems == 0 || size == 0)
		return NULL;

	if (nitems > SIZE_MAX / size)
		[[OFOutOfRangeException newWithObject: self] raise];

	memsize = nitems * size;
	return [self getMemWithSize: memsize];
}

- (void*)resizeMem: (void*)ptr
	    toSize: (size_t)size
{
	size_t i;

	if (ptr == NULL)
		return [self getMemWithSize: size];

	if (size == 0) {
		[self freeMem: ptr];
		return NULL;
	}

	for (i = 0; i < __memchunks_size; i++) {
		if (__memchunks[i] == ptr) {
			if ((ptr = realloc(ptr, size)) == NULL)
				[[OFNoMemException newWithObject: self
							 andSize: size] raise];
			
			__memchunks[i] = ptr;
			return ptr;
		}
	}

	[[OFMemNotPartOfObjException newWithObject: self
					andPointer: ptr] raise];
	return NULL;	/* never reached, but makes gcc happy */
}

- (void*)resizeMem: (void*)ptr
	  toNItems: (size_t)nitems
	    ofSize: (size_t)size
{
	size_t memsize;

	if (ptr == NULL)
		return [self getMemForNItems: nitems
				      ofSize: size];
	
	if (nitems == 0 || size == 0) {
		[self freeMem: ptr];
		return NULL;
	}

	if (nitems > SIZE_MAX / size)
		[[OFOutOfRangeException newWithObject: self] raise];

	memsize = nitems * size;
	return [self resizeMem: ptr
			toSize: memsize];
}

- freeMem: (void*)ptr;
{
	void *last, **memchunks;
	size_t i, memchunks_size;

	for (i = 0; i < __memchunks_size; i++) {
		if (__memchunks[i] == ptr) {
			memchunks_size = __memchunks_size - 1;
			last = __memchunks[memchunks_size];

			if (__memchunks_size == 0 ||
			    memchunks_size > SIZE_MAX / sizeof(void*))
				[[OFOutOfRangeException newWithObject: self]
				    raise];

			if (memchunks_size == 0) {
				free(ptr);
				free(__memchunks);

				__memchunks = NULL;
				__memchunks_size = 0;

				return self;
			}

			if ((memchunks = realloc(__memchunks,
			    memchunks_size * sizeof(void*))) == NULL)
				[[OFNoMemException newWithObject: self
							 andSize:
							     memchunks_size]
				    raise];

			free(ptr);
			__memchunks = memchunks;
			__memchunks[i] = last;
			__memchunks_size = memchunks_size;

			return self;
		}
	}

	[[OFMemNotPartOfObjException newWithObject: self
					andPointer: ptr] raise];
	return self	/* never reached, but makes gcc happy */;
}
@end
