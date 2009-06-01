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
#include <string.h>
#include <limits.h>
#include <assert.h>

#import "OFObject.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "OFMacros.h"

#import <objc/objc-api.h>
#ifndef __objc_INCLUDE_GNU
#import <objc/runtime.h>
#endif

struct pre_ivar {
	void   **memchunks;
	size_t memchunks_size;
	size_t retain_count;
};

/* Hopefully no arch needs more than 16 bytes padding */
#define PRE_IVAR_ALIGN ((sizeof(struct pre_ivar) + 15) & ~15)
#define PRE_IVAR ((struct pre_ivar*)((char*)self - PRE_IVAR_ALIGN))

static struct {
	Class isa;
} alloc_failed_exception;

#ifdef NEED_OBJC_SYNC_INIT
extern BOOL objc_sync_init();
#endif

@implementation OFObject
+ (void)initialize
{
#ifdef NEED_OBJC_SYNC_INIT
	if (!objc_sync_init()) {
		fputs("Runtime error: objc_sync_init() failed!\n", stderr);
		abort();
	}
#endif
}

+ alloc
{
	OFObject *instance;
#ifdef __objc_INCLUDE_GNU
	size_t isize = class_get_instance_size(self);
#else
	size_t isize = class_getInstanceSize(self);
#endif

	if ((instance = malloc(isize + PRE_IVAR_ALIGN)) == NULL) {
		alloc_failed_exception.isa = [OFAllocFailedException class];
		@throw (OFAllocFailedException*)&alloc_failed_exception;
	}

	((struct pre_ivar*)instance)->memchunks = NULL;
	((struct pre_ivar*)instance)->memchunks_size = 0;
	((struct pre_ivar*)instance)->retain_count = 1;

	instance = (OFObject*)((char*)instance + PRE_IVAR_ALIGN);
	memset(instance, 0, isize);
	instance->isa = self;

	return instance;
}

+ (Class)class
{
	return self;
}

+ (const char*)name
{
#ifdef __objc_INCLUDE_GNU
	return class_get_class_name(self);
#else
	return class_getName(self);
#endif
}

+ (BOOL)conformsTo: (Protocol*)protocol
{
#ifdef __objc_INCLUDE_GNU
	Class c;
	struct objc_protocol_list *pl;
	size_t i;

	for (c = self; c != Nil; c = class_get_super_class(c))
		for (pl = c->protocols; pl != NULL; pl = pl->next)
			for (i = 0; i < pl->count; i++)
				if ([pl->list[i] conformsTo: protocol])
					return YES;

	return NO;
#else
	Class c;

	for (c = self; c != Nil; c = class_getSuperclass(c))
		if (class_conformsToProtocol(c, protocol))
			return YES;

	return NO;
#endif
}

+ (IMP)replaceMethod: (SEL)selector
 withMethodFromClass: (Class)class;
{
#ifdef __objc_INCLUDE_GNU
	Method_t method = class_get_instance_method(self, selector);
	IMP oldimp, newimp;

	if (method == NULL)
		@throw [OFInvalidArgumentException newWithClass: self
						    andSelector: _cmd];

	oldimp = method_get_imp(method);
	newimp = method_get_imp(class_get_instance_method(class, selector));

	if (oldimp == (IMP)0 || newimp == (IMP)0)
		@throw [OFInvalidArgumentException newWithClass: self
						    andSelector: _cmd];

	method->method_imp = newimp;
	return oldimp;
#else
	Method method = class_getInstanceMethod(self, selector);
	IMP imp = class_getMethodImplementation(class, selector);

	if (method == NULL || imp == NULL)
		@throw [OFInvalidArgumentException newWithClass: self
						    andSelector: _cmd];

	return method_setImplementation(method, imp);
#endif
}

- init
{
	return self;
}

- (Class)class
{
	return isa;
}

- (const char*)name
{
#ifdef __objc_INCLUDE_GNU
	return object_get_class_name(self);
#else
	return class_getName(isa);
#endif
}

- (BOOL)isKindOf: (Class)class
{
	Class iter;

#ifdef __objc_INCLUDE_GNU
	for (iter = isa; iter != Nil; iter = class_get_super_class(iter))
#else
	for (iter = isa; iter != Nil; iter = class_getSuperclass(iter))
#endif
		if (iter == class)
			return YES;

	return NO;
}

- (BOOL)respondsTo: (SEL)selector
{
#ifdef __objc_INCLUDE_GNU
	if (object_is_instance(self))
		return class_get_instance_method(isa, selector) != METHOD_NULL;
	else
		return class_get_class_method(isa, selector) != METHOD_NULL;
#else
	return class_respondsToSelector(isa, selector);
#endif
}

- (BOOL)conformsTo: (Protocol*)protocol
{
	return [isa conformsTo: protocol];
}

- (IMP)methodFor: (SEL)selector
{
#ifdef __objc_INCLUDE_GNU
	if (object_is_instance(self))
		return method_get_imp(class_get_instance_method(isa, selector));
	else
		return method_get_imp(class_get_class_method(isa, selector));
#else
	return class_getMethodImplementation(isa, selector);
#endif
}

- (BOOL)isEqual: (id)obj
{
	/* Classes containing data should reimplement this! */
	return (self == obj ? YES : NO);
}

- (uint32_t)hash
{
	/* Classes containing data should reimplement this! */
	return (uint32_t)(intptr_t)self;
}

- addMemoryToPool: (void*)ptr
{
	void **memchunks;
	size_t memchunks_size;

	memchunks_size = PRE_IVAR->memchunks_size + 1;

	if (SIZE_MAX - PRE_IVAR->memchunks_size < 1 ||
	    memchunks_size > SIZE_MAX / sizeof(void*))
		@throw [OFOutOfRangeException newWithClass: isa];

	if ((memchunks = realloc(PRE_IVAR->memchunks,
	    memchunks_size * sizeof(void*))) == NULL)
		@throw [OFOutOfMemoryException newWithClass: isa
						    andSize: memchunks_size];

	PRE_IVAR->memchunks = memchunks;
	PRE_IVAR->memchunks[PRE_IVAR->memchunks_size] = ptr;
	PRE_IVAR->memchunks_size = memchunks_size;

	return self;
}

- (void*)allocMemoryWithSize: (size_t)size
{
	void *ptr, **memchunks;
	size_t memchunks_size;

	if (size == 0)
		return NULL;

	memchunks_size = PRE_IVAR->memchunks_size + 1;

	if (SIZE_MAX - PRE_IVAR->memchunks_size == 0 ||
	    memchunks_size > SIZE_MAX / sizeof(void*))
		@throw [OFOutOfRangeException newWithClass: isa];

	if ((ptr = malloc(size)) == NULL)
		@throw [OFOutOfMemoryException newWithClass: isa
						    andSize: size];

	if ((memchunks = realloc(PRE_IVAR->memchunks,
	    memchunks_size * sizeof(void*))) == NULL) {
		free(ptr);
		@throw [OFOutOfMemoryException newWithClass: isa
						    andSize: memchunks_size];
	}

	PRE_IVAR->memchunks = memchunks;
	PRE_IVAR->memchunks[PRE_IVAR->memchunks_size] = ptr;
	PRE_IVAR->memchunks_size = memchunks_size;

	return ptr;
}

- (void*)allocMemoryForNItems: (size_t)nitems
		     withSize: (size_t)size
{
	if (nitems == 0 || size == 0)
		return NULL;

	if (nitems > SIZE_MAX / size)
		@throw [OFOutOfRangeException newWithClass: isa];

	return [self allocMemoryWithSize: nitems * size];
}

- (void*)resizeMemory: (void*)ptr
	       toSize: (size_t)size
{
	void **iter;

	if (ptr == NULL)
		return [self allocMemoryWithSize: size];

	if (size == 0) {
		[self freeMemory: ptr];
		return NULL;
	}

	iter = PRE_IVAR->memchunks + PRE_IVAR->memchunks_size;

	while (iter-- > PRE_IVAR->memchunks) {
		if (OF_UNLIKELY(*iter == ptr)) {
			if (OF_UNLIKELY((ptr = realloc(ptr, size)) == NULL))
				@throw [OFOutOfMemoryException
				    newWithClass: isa
					 andSize: size];

			*iter = ptr;
			return ptr;
		}
	}

	@throw [OFMemoryNotPartOfObjectException newWithClass: isa
						   andPointer: ptr];
}

- (void*)resizeMemory: (void*)ptr
	     toNItems: (size_t)nitems
	     withSize: (size_t)size
{
	if (ptr == NULL)
		return [self allocMemoryForNItems: nitems
					 withSize: size];

	if (nitems == 0 || size == 0) {
		[self freeMemory: ptr];
		return NULL;
	}

	if (nitems > SIZE_MAX / size)
		@throw [OFOutOfRangeException newWithClass: isa];

	return [self resizeMemory: ptr
			   toSize: nitems * size];
}

- freeMemory: (void*)ptr;
{
	void **iter, *last, **memchunks;
	size_t i, memchunks_size;

	iter = PRE_IVAR->memchunks + PRE_IVAR->memchunks_size;
	i = PRE_IVAR->memchunks_size;

	while (iter-- > PRE_IVAR->memchunks) {
		i--;

		if (OF_UNLIKELY(*iter == ptr)) {
			memchunks_size = PRE_IVAR->memchunks_size - 1;
			last = PRE_IVAR->memchunks[memchunks_size];

			assert(PRE_IVAR->memchunks_size != 0 &&
			    memchunks_size <= SIZE_MAX / sizeof(void*));

			if (OF_UNLIKELY(memchunks_size == 0)) {
				free(ptr);
				free(PRE_IVAR->memchunks);

				PRE_IVAR->memchunks = NULL;
				PRE_IVAR->memchunks_size = 0;

				return self;
			}

			if (OF_UNLIKELY((memchunks = realloc(
			    PRE_IVAR->memchunks, memchunks_size *
			    sizeof(void*))) == NULL))
				return self;

			free(ptr);
			PRE_IVAR->memchunks = memchunks;
			PRE_IVAR->memchunks[i] = last;
			PRE_IVAR->memchunks_size = memchunks_size;

			return self;
		}
	}

	@throw [OFMemoryNotPartOfObjectException newWithClass: isa
						   andPointer: ptr];
}

- retain
{
	PRE_IVAR->retain_count++;

	return self;
}

- autorelease
{
	[OFAutoreleasePool addObjectToTopmostPool: self];

	return self;
}

- (size_t)retainCount
{
	return PRE_IVAR->retain_count;
}

- (void)release
{
	if (!--PRE_IVAR->retain_count)
		[self dealloc];
}

- (void)dealloc
{
	void **iter = PRE_IVAR->memchunks + PRE_IVAR->memchunks_size;

	while (iter-- > PRE_IVAR->memchunks)
		free(*iter);

	if (PRE_IVAR->memchunks != NULL)
		free(PRE_IVAR->memchunks);

	free((char*)self - PRE_IVAR_ALIGN);
}
@end
