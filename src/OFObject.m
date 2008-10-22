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

#ifdef HAVE_OBJC_RUNTIME_H
#define MEM_POOL (*(struct __ofobject_allocated_mem**)((char*)self + \
	class_getInstanceSize([self class])))
#else
#define MEM_POOL (*(struct __ofobject_allocated_mem**)((char*)self + \
	([self class])->instance_size))
#endif

@implementation OFObject
+ alloc
{
	Class class = [self class];
	id inst = nil;

#ifdef HAVE_OBJC_RUNTIME_H
	if ((inst = (id)malloc(class_getInstanceSize(class) +
	    sizeof(struct __ofobject_allocated_mem*))) != nil) {
		memset(inst, 0, class_getInstanceSize(class) +
		    sizeof(struct __ofobject_allocated_mem*));
		inst->isa = class;
	}
#else
	if ((inst = (id)malloc(class->instance_size) +
	    sizeof(struct __ofobject_allocated_mem*)) != nil) {
		memset(inst, 0, class->instance_size +
		    sizeof(struct __ofobject_allocated_mem*));
		inst->class_pointer = class;
	}
#endif

	return inst;
}

- init
{
	if ((self = [super init]) != nil)
		MEM_POOL = NULL;
	return self;
}

- free
{
	struct __ofobject_allocated_mem *iter, *iter2;

	for (iter = MEM_POOL; iter != NULL; iter = iter2) {
		iter2 = iter->prev;
		free(iter->ptr);
		free(iter);
	}

	free(self);

	return nil;
}

- (void*)getMemWithSize: (size_t)size
{
	struct __ofobject_allocated_mem *iter;

	if ((iter = malloc(sizeof(struct __ofobject_allocated_mem))) == NULL) {
		[[OFNoMemException newWithObject: self
					andSize: sizeof(struct
						     __ofobject_allocated_mem)
		    ] raise];
		return NULL;
	}

	if ((iter->ptr = malloc(size)) == NULL) {
		free(iter);
		[[OFNoMemException newWithObject: self
					andSize: size] raise];
		return NULL;
	}

	iter->next = NULL;
	iter->prev = MEM_POOL;

	if (MEM_POOL != NULL)
		MEM_POOL->next = iter;

	MEM_POOL = iter;

	return iter->ptr;
}

- (void*)resizeMem: (void*)ptr
	    toSize: (size_t)size
{
	struct __ofobject_allocated_mem *iter;

	for (iter = MEM_POOL; iter != NULL; iter = iter->prev) {
		if (iter->ptr == ptr) {
			if ((ptr = realloc(iter->ptr, size)) == NULL) {
				[[OFNoMemException newWithObject: self
							 andSize: size] raise];
				return NULL;
			}
			
			iter->ptr = ptr;
			return ptr;
		}
	}

	[[OFMemNotPartOfObjException newWithObject: self
					andPointer: ptr] raise];
	return NULL;
}

- (void)freeMem: (void*)ptr;
{
	struct __ofobject_allocated_mem *iter;

	for (iter = MEM_POOL; iter != NULL; iter = iter->prev) {
		if (iter->ptr == ptr) {
			if (iter->prev != NULL) 
				iter->prev->next = iter->next;
			if (iter->next != NULL)
				iter->next->prev = iter->prev;
			if (MEM_POOL == iter)
				MEM_POOL = NULL;

			free(iter);
			free(ptr);

			return;
		}
	}

	[[OFMemNotPartOfObjException newWithObject: self
					andPointer: ptr] raise];
}
@end
