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

#import "config.h"

#include <stdlib.h>
#include <string.h>
#include <limits.h>

#import "OFObject.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "OFMacros.h"

@implementation OFObject
- init
{
	if ((self = [super init]) != nil) {
		__memchunks = NULL;
		__memchunks_size = 0;
		__retain_count = 1;
	}

	return self;
}

- free
{
	void **iter = __memchunks + __memchunks_size;

	while (iter-- > __memchunks)
		free(*iter);

	if (__memchunks != NULL)
		free(__memchunks);

	return [super free];
}

- retain
{
	__retain_count++;

	return self;
}

- release
{
	if (!--__retain_count)
		return [self free];

	return self;
}

- autorelease
{
	[OFAutoreleasePool addToPool: self];

	return self;
}

- (size_t)retainCount
{
	return __retain_count;
}

- addToMemoryPool: (void*)ptr
{
	void **memchunks;
	size_t memchunks_size;

	memchunks_size = __memchunks_size + 1;

	if (SIZE_MAX - __memchunks_size < 1 ||
	    memchunks_size > SIZE_MAX / sizeof(void*))
		@throw [OFOutOfRangeException newWithClass: [self class]];

	if ((memchunks = realloc(__memchunks,
	    memchunks_size * sizeof(void*))) == NULL)
		@throw [OFNoMemException newWithClass: [self class]
					      andSize: memchunks_size];

	__memchunks = memchunks;
	__memchunks[__memchunks_size] = ptr;
	__memchunks_size = memchunks_size;

	return self;
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
		@throw [OFOutOfRangeException newWithClass: [self class]];

	if ((ptr = malloc(size)) == NULL)
		@throw [OFNoMemException newWithClass: [self class]
					      andSize: size];

	if ((memchunks = realloc(__memchunks,
	    memchunks_size * sizeof(void*))) == NULL) {
		free(ptr);
		@throw [OFNoMemException newWithClass: [self class]
					      andSize: memchunks_size];
	}

	__memchunks = memchunks;
	__memchunks[__memchunks_size] = ptr;
	__memchunks_size = memchunks_size;

	return ptr;
}

- (void*)getMemForNItems: (size_t)nitems
		  ofSize: (size_t)size
{
	if (nitems == 0 || size == 0)
		return NULL;

	if (nitems > SIZE_MAX / size)
		@throw [OFOutOfRangeException newWithClass: [self class]];

	return [self getMemWithSize: nitems * size];
}

- (void*)resizeMem: (void*)ptr
	    toSize: (size_t)size
{
	void **iter;

	if (ptr == NULL)
		return [self getMemWithSize: size];

	if (size == 0) {
		[self freeMem: ptr];
		return NULL;
	}

	iter = __memchunks + __memchunks_size;

	while (iter-- > __memchunks) {
		if (OF_UNLIKELY(*iter == ptr)) {
			if (OF_UNLIKELY((ptr = realloc(ptr, size)) == NULL))
				@throw [OFNoMemException
				    newWithClass: [self class]
					 andSize: size];

			*iter = ptr;
			return ptr;
		}
	}

	@throw [OFMemNotPartOfObjException newWithClass: [self class]
					     andPointer: ptr];
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
		@throw [OFOutOfRangeException newWithClass: [self class]];

	memsize = nitems * size;
	return [self resizeMem: ptr
			toSize: memsize];
}

- freeMem: (void*)ptr;
{
	void **iter, *last, **memchunks;
	size_t i, memchunks_size;

	iter = __memchunks + __memchunks_size;
	i = __memchunks_size;

	while (iter-- > __memchunks) {
		i--;

		if (OF_UNLIKELY(*iter == ptr)) {
			memchunks_size = __memchunks_size - 1;
			last = __memchunks[memchunks_size];

			if (OF_UNLIKELY(__memchunks_size == 0 ||
			    memchunks_size > SIZE_MAX / sizeof(void*)))
				@throw [OFOutOfRangeException
				    newWithClass: [self class]];

			if (OF_UNLIKELY(memchunks_size == 0)) {
				free(ptr);
				free(__memchunks);

				__memchunks = NULL;
				__memchunks_size = 0;

				return self;
			}

			if (OF_UNLIKELY((memchunks = realloc(__memchunks,
			    memchunks_size * sizeof(void*))) == NULL))
				@throw [OFNoMemException
				    newWithClass: [self class]
					 andSize: memchunks_size];

			free(ptr);
			__memchunks = memchunks;
			__memchunks[i] = last;
			__memchunks_size = memchunks_size;

			return self;
		}
	}

	@throw [OFMemNotPartOfObjException newWithClass: [self class]
					     andPointer: ptr];
	return self;	/* never reached, but makes gcc happy */
}
@end
