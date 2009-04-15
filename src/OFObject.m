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

/*
 * Get rid of the stupid warnings until we have our own implementation for
 * objc_msgSendv.
 */
#define OBJC2_UNAVAILABLE

#import "config.h"

#include <stdlib.h>
#include <string.h>
#include <limits.h>

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

@implementation OFObject
#ifndef __objc_INCLUDE_GNU
+ load
{
	return self;
}
#endif

+ initialize
{
	return self;
}

+ alloc
{
	OFObject *instance;
#ifdef __objc_INCLUDE_GNU
	size_t isize = class_get_instance_size(self);
#else
	size_t isize = class_getInstanceSize(self);
#endif

	if ((instance = malloc(isize + PRE_IVAR_ALIGN)) == NULL)
		return nil;

	((struct pre_ivar*)instance)->memchunks = NULL;
	((struct pre_ivar*)instance)->memchunks_size = 0;
	((struct pre_ivar*)instance)->retain_count = 1;

	instance = (OFObject*)((char*)instance + PRE_IVAR_ALIGN);
	memset(instance, 0, isize);
	instance->isa = self;

	return instance;
}

+ new
{
	return [[self alloc] init];
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
	Method m;
	IMP imp;

	if ((m = class_getInstanceMethod(self, selector)) == NULL ||
	    (imp = method_getImplementation(m)) == NULL)
		@throw [OFInvalidArgumentException newWithClass: self
						    andSelector: _cmd];

	return method_setImplementation(m, imp);
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

#ifdef __objc_INCLUDE_GNU
- (retval_t)forward: (SEL)selector
		   : (arglist_t)args
#else
- (id)forward: (SEL)selector
	     : (marg_list)args
#endif
{
	@throw [OFNotImplementedException newWithClass: [self class]
					   andSelector: _cmd];
	return self;
}

#ifdef __objc_INCLUDE_GNU
- (retval_t)performv: (SEL)selector
		    : (arglist_t)args
{
	return objc_msg_sendv(self, selector, args);
}
#else
- performv: (SEL)selector
	  : (marg_list)args
{
#if !__OBJC2__
	Method method;
	unsigned size;

	if ((method = class_getInstanceMethod(isa, selector)) != NULL)
		size = method_getSizeOfArguments(method);
	else
		size = 0;

	if (!size)
		return [self forward: selector
				    : args];

	return objc_msgSendv(self, selector, size, args);
#else
#warning ObjC2 removed objc_msgSendv and there is
#warning no own implementation for it yet!
	return nil;
#endif
}
#endif

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

- addToMemoryPool: (void*)ptr
{
	void **memchunks;
	size_t memchunks_size;

	memchunks_size = PRE_IVAR->memchunks_size + 1;

	if (SIZE_MAX - PRE_IVAR->memchunks_size < 1 ||
	    memchunks_size > SIZE_MAX / sizeof(void*))
		@throw [OFOutOfRangeException newWithClass: [self class]];

	if ((memchunks = realloc(PRE_IVAR->memchunks,
	    memchunks_size * sizeof(void*))) == NULL)
		@throw [OFNoMemException newWithClass: [self class]
					      andSize: memchunks_size];

	PRE_IVAR->memchunks = memchunks;
	PRE_IVAR->memchunks[PRE_IVAR->memchunks_size] = ptr;
	PRE_IVAR->memchunks_size = memchunks_size;

	return self;
}

- (void*)getMemWithSize: (size_t)size
{
	void *ptr, **memchunks;
	size_t memchunks_size;

	if (size == 0)
		return NULL;

	memchunks_size = PRE_IVAR->memchunks_size + 1;

	if (SIZE_MAX - PRE_IVAR->memchunks_size == 0 ||
	    memchunks_size > SIZE_MAX / sizeof(void*))
		@throw [OFOutOfRangeException newWithClass: [self class]];

	if ((ptr = malloc(size)) == NULL)
		@throw [OFNoMemException newWithClass: [self class]
					      andSize: size];

	if ((memchunks = realloc(PRE_IVAR->memchunks,
	    memchunks_size * sizeof(void*))) == NULL) {
		free(ptr);
		@throw [OFNoMemException newWithClass: [self class]
					      andSize: memchunks_size];
	}

	PRE_IVAR->memchunks = memchunks;
	PRE_IVAR->memchunks[PRE_IVAR->memchunks_size] = ptr;
	PRE_IVAR->memchunks_size = memchunks_size;

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

	iter = PRE_IVAR->memchunks + PRE_IVAR->memchunks_size;

	while (iter-- > PRE_IVAR->memchunks) {
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

	iter = PRE_IVAR->memchunks + PRE_IVAR->memchunks_size;
	i = PRE_IVAR->memchunks_size;

	while (iter-- > PRE_IVAR->memchunks) {
		i--;

		if (OF_UNLIKELY(*iter == ptr)) {
			memchunks_size = PRE_IVAR->memchunks_size - 1;
			last = PRE_IVAR->memchunks[memchunks_size];

			if (OF_UNLIKELY(PRE_IVAR->memchunks_size == 0 ||
			    memchunks_size > SIZE_MAX / sizeof(void*)))
				@throw [OFOutOfRangeException
				    newWithClass: [self class]];

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
				@throw [OFNoMemException
				    newWithClass: [self class]
					 andSize: memchunks_size];

			free(ptr);
			PRE_IVAR->memchunks = memchunks;
			PRE_IVAR->memchunks[i] = last;
			PRE_IVAR->memchunks_size = memchunks_size;

			return self;
		}
	}

	@throw [OFMemNotPartOfObjException newWithClass: [self class]
					     andPointer: ptr];
	return self;	/* never reached, but makes gcc happy */
}

- retain
{
	PRE_IVAR->retain_count++;

	return self;
}

- autorelease
{
	[OFAutoreleasePool addToPool: self];

	return self;
}

- (size_t)retainCount
{
	return PRE_IVAR->retain_count;
}

- (void)release
{
	if (!--PRE_IVAR->retain_count)
		[self free];
}

- free
{
	void **iter = PRE_IVAR->memchunks + PRE_IVAR->memchunks_size;

	while (iter-- > PRE_IVAR->memchunks)
		free(*iter);

	if (PRE_IVAR->memchunks != NULL)
		free(PRE_IVAR->memchunks);

	free((char*)self - PRE_IVAR_ALIGN);
	return nil;
}
@end
