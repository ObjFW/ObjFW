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

#import "OFObject.h"

@implementation OFObject
- init
{
	if ((self = [super init]) != nil)
		__mem_pool  = NULL;
	return self;
}

- (void*)getMem: (size_t)size
{
	struct __ofobject_allocated_mem *iter;

	if ((iter = malloc(sizeof(struct __ofobject_allocated_mem))) == NULL)
		return NULL;

	if ((iter->ptr = malloc(size)) == NULL) {
		free(iter);
		return NULL;
	}

	iter->next = NULL;
	iter->prev = __mem_pool;

	if (__mem_pool != NULL)
		__mem_pool->next = iter;

	__mem_pool = iter;

	return iter->ptr;
}

- (void*)resizeMem: (void*)ptr
	    toSize: (size_t)size
{
	struct __ofobject_allocated_mem *iter;

	for (iter = __mem_pool; iter != NULL; iter = iter->prev) {
		if (iter->ptr == ptr) {
			if ((ptr = realloc(iter->ptr, size)) == NULL)
				return NULL;
			
			iter->ptr = ptr;
			return ptr;
		}
	}

	@throw [OFMemNotPartOfObjException new: ptr fromObject: self];
	return NULL;
}

- (void)freeMem: (void*)ptr;
{
	struct __ofobject_allocated_mem *iter;

	for (iter = __mem_pool; iter != NULL; iter = iter->prev) {
		if (iter->ptr == ptr) {
			if (iter->prev != NULL) 
				iter->prev->next = iter->next;
			if (iter->next != NULL)
				iter->next->prev = iter->prev;
			if (__mem_pool == iter)
				__mem_pool = NULL;

			free(iter);
			free(ptr);

			return;
		}
	}

	@throw [OFMemNotPartOfObjException new: ptr fromObject: self];
}

- free
{
	struct __ofobject_allocated_mem *iter, *iter2;

	for (iter = __mem_pool; iter != NULL; iter = iter2) {
		iter2 = iter->prev;
		free(iter->ptr);
		free(iter);
	}

	return [super free];
}
@end

@implementation OFMemNotPartOfObjException
+ new: (void*)ptr fromObject: (id)obj
{
	return [[OFMemNotPartOfObjException alloc] init: ptr
					     fromObject: obj];
}

- init: (void*)ptr fromObject: (id)obj
{
	fprintf(stderr, "ERROR: Memory at %p was not allocated as part of "
	    "object %s!\n"
	    "ERROR: -> Not changing memory allocation!\n"
	    "ERROR: (Hint: It is possible that you tried to free the same "
	    "memory twice!)\n", ptr, [obj name]);

	return [super init];
}
@end
