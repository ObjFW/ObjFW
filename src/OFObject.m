/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <assert.h>

#import "OFObject.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "macros.h"

#if defined(OF_OBJFW_RUNTIME)
# import <objfw-rt.h>
#elif defined(OF_APPLE_RUNTIME)
# import <objc/objc-api.h>
# import <objc/runtime.h>
#elif defined(OF_GNU_RUNTIME)
# import <objc/objc-api.h>
# import <objc/sarray.h>
#endif

#ifdef _WIN32
# include <windows.h>
#endif

#ifdef OF_ATOMIC_OPS
# import "atomic.h"
#else
# import "threading.h"
#endif

/* A few macros to reduce #ifdefs */
#ifdef OF_GNU_RUNTIME
# define class_getInstanceSize class_get_instance_size
# define class_getName class_get_class_name
# define class_getSuperclass class_get_super_class
#endif

/// \cond internal
struct pre_ivar {
	void	      **memchunks;
	size_t	      memchunks_size;
	int32_t	      retain_count; /* int32_t because atomic ops use int32_t */
#ifndef OF_ATOMIC_OPS
	of_spinlock_t retain_spinlock;
#endif
};
/// \endcond

/* Hopefully no arch needs more than 16 bytes padding */
#define PRE_IVAR_ALIGN ((sizeof(struct pre_ivar) + 15) & ~15)
#define PRE_IVAR ((struct pre_ivar*)((char*)self - PRE_IVAR_ALIGN))

static struct {
	Class isa;
} alloc_failed_exception;

size_t of_pagesize;

#ifdef NEED_OBJC_SYNC_INIT
extern BOOL objc_sync_init();
#endif

#ifdef NEED_OBJC_PROPERTIES_INIT
extern BOOL objc_properties_init();
#endif

static void
enumeration_mutation_handler(id obj)
{
	@throw [OFEnumerationMutationException newWithClass: [obj class]];
}

#ifndef HAVE_OBJC_ENUMERATIONMUTATION
void
objc_enumerationMutation(id obj)
{
	enumeration_mutation_handler(obj);
}
#endif

@implementation OFObject
+ (void)load
{
#ifdef NEED_OBJC_SYNC_INIT
	if (!objc_sync_init()) {
		fputs("Runtime error: objc_sync_init() failed!\n", stderr);
		abort();
	}
#endif

#ifdef NEED_OBJC_PROPERTIES_INIT
	if (!objc_properties_init()) {
		fputs("Runtime error: objc_properties_init() failed!\n",
		    stderr);
		abort();
	}
#endif

#ifdef OF_APPLE_RUNTIME
	objc_setEnumerationMutationHandler(enumeration_mutation_handler);
#endif

#ifndef _WIN32
	if ((of_pagesize = sysconf(_SC_PAGESIZE)) < 1)
		of_pagesize = 4096;
#else
	SYSTEM_INFO si;
	GetSystemInfo(&si);
	of_pagesize = si.dwPageSize;
#endif
}

+ (void)initialize
{
}

+ alloc
{
	OFObject *instance;
	size_t isize = class_getInstanceSize(self);

	if ((instance = malloc(isize + PRE_IVAR_ALIGN)) == NULL) {
		alloc_failed_exception.isa = [OFAllocFailedException class];
		@throw (OFAllocFailedException*)&alloc_failed_exception;
	}

	((struct pre_ivar*)instance)->memchunks = NULL;
	((struct pre_ivar*)instance)->memchunks_size = 0;
	((struct pre_ivar*)instance)->retain_count = 1;

#ifndef OF_ATOMIC_OPS
	if (!of_spinlock_new(&((struct pre_ivar*)instance)->retain_spinlock)) {
		free(instance);
		@throw [OFInitializationFailedException newWithClass: self];
	}
#endif

	instance = (OFObject*)((char*)instance + PRE_IVAR_ALIGN);
	memset(instance, 0, isize);
	instance->isa = self;

	return instance;
}

+ (Class)class
{
	return self;
}

+ (const char*)className
{
	return class_getName(self);
}

+ (BOOL)isSubclassOfClass: (Class)class
{
	Class iter;

	for (iter = self; iter != Nil; iter = class_getSuperclass(iter))
		if (iter == class)
			return YES;

	return NO;
}

+ (Class)superclass
{
	return class_getSuperclass(self);
}

+ (BOOL)instancesRespondToSelector: (SEL)selector
{
#ifdef OF_GNU_RUNTIME
	return class_get_instance_method(self, selector) != METHOD_NULL;
#else
	return class_respondsToSelector(self, selector);
#endif
}

+ (BOOL)conformsToProtocol: (Protocol*)protocol
{
#ifdef OF_GNU_RUNTIME
	Class c;
	struct objc_protocol_list *pl;
	size_t i;

	for (c = self; c != Nil; c = class_get_super_class(c))
		for (pl = c->protocols; pl != NULL; pl = pl->next)
			for (i = 0; i < pl->count; i++)
				if ([pl->list[i] conformsToProtocol: protocol])
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

+ (IMP)instanceMethodForSelector: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	return objc_get_instance_method(self, selector);
#elif defined(OF_APPLE_RUNTIME)
	return class_getMethodImplementation(self, selector);
#else
	return method_get_imp(class_get_instance_method(self, selector));
#endif
}

+ (IMP)setImplementation: (IMP)newimp
	  forClassMethod: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	return objc_replace_class_method(self, selector, newimp);
#elif defined(OF_APPLE_RUNTIME)
	return class_replaceMethod(self->isa, selector, newimp,
	    method_getTypeEncoding(class_getClassMethod(self, selector)));
#else
	Method_t method;
	IMP oldimp;

	/* The class method is the instance method of the meta class */
	if ((method = class_get_instance_method(self->class_pointer,
	    selector)) == NULL)
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	if ((oldimp = method_get_imp(method)) == (IMP)0 || newimp == (IMP)0)
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	method->method_imp = newimp;

	/* Update the dtable if necessary */
	if (sarray_get_safe(((Class)self->class_pointer)->dtable,
	    (sidx)method->method_name->sel_id))
		sarray_at_put_safe(((Class)self->class_pointer)->dtable,
		    (sidx)method->method_name->sel_id, method->method_imp);

	return oldimp;
#endif
}

+  (IMP)replaceClassMethod: (SEL)selector
  withClassMethodFromClass: (Class)class;
{
	IMP newimp;

#if defined(OF_OBJFW_RUNTIME)
	newimp = objc_get_class_method(class, selector);
#elif defined(OF_APPLE_RUNTIME)
	newimp = method_getImplementation(class_getClassMethod(class,
	    selector));
#else
	/* The class method is the instance method of the meta class */
	newimp = method_get_imp(class_get_instance_method(class->class_pointer,
	    selector));
#endif

	return [self setImplementation: newimp
			forClassMethod: selector];
}

+ (IMP)setImplementation: (IMP)newimp
       forInstanceMethod: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	return objc_replace_instance_method(self, selector, newimp);
#elif defined(OF_APPLE_RUNTIME)
	return class_replaceMethod(self, selector, newimp,
	    method_getTypeEncoding(class_getInstanceMethod(self, selector)));
#else
	Method_t method = class_get_instance_method(self, selector);
	IMP oldimp;

	if (method == NULL)
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	if ((oldimp = method_get_imp(method)) == (IMP)0 || newimp == (IMP)0)
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	method->method_imp = newimp;

	/* Update the dtable if necessary */
	if (sarray_get_safe(((Class)self)->dtable,
	    (sidx)method->method_name->sel_id))
		sarray_at_put_safe(((Class)self)->dtable,
		    (sidx)method->method_name->sel_id, method->method_imp);

	return oldimp;
#endif
}

+  (IMP)replaceInstanceMethod: (SEL)selector
  withInstanceMethodFromClass: (Class)class;
{
	IMP newimp;

#if defined(OF_OBJFW_RUNTIME)
	newimp = objc_get_instance_method(class, selector);
#elif defined(OF_APPLE_RUNTIME)
	newimp = class_getMethodImplementation(class, selector);
#else
	newimp = method_get_imp(class_get_instance_method(class, selector));
#endif

	return [self setImplementation: newimp
		     forInstanceMethod: selector];
}

- init
{
	return self;
}

- (Class)class
{
	return isa;
}

- (const char*)className
{
#ifdef OF_GNU_RUNTIME
	return object_get_class_name(self);
#else
	return class_getName(isa);
#endif
}

- (BOOL)isKindOfClass: (Class)class
{
	Class iter;

	for (iter = isa; iter != Nil; iter = class_getSuperclass(iter))
		if (iter == class)
			return YES;

	return NO;
}

- (BOOL)respondsToSelector: (SEL)selector
{
#ifdef OF_GNU_RUNTIME
	if (object_is_instance(self))
		return class_get_instance_method(isa, selector) != METHOD_NULL;
	else
		return class_get_class_method(isa, selector) != METHOD_NULL;
#else
	return class_respondsToSelector(isa, selector);
#endif
}

- (BOOL)conformsToProtocol: (Protocol*)protocol
{
	return [isa conformsToProtocol: protocol];
}

- (IMP)methodForSelector: (SEL)selector
{
#ifdef OF_APPLE_RUNTIME
	return class_getMethodImplementation(isa, selector);
#else
	return objc_msg_lookup(self, selector);
#endif
}

- (BOOL)isEqual: (OFObject*)obj
{
	/* Classes containing data should reimplement this! */
	return (self == obj ? YES : NO);
}

- (uint32_t)hash
{
	/* Classes containing data should reimplement this! */
	return (uint32_t)(uintptr_t)self;
}

- (void)addMemoryToPool: (void*)ptr
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
						       size: memchunks_size];

	PRE_IVAR->memchunks = memchunks;
	PRE_IVAR->memchunks[PRE_IVAR->memchunks_size] = ptr;
	PRE_IVAR->memchunks_size = memchunks_size;
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
						       size: size];

	if ((memchunks = realloc(PRE_IVAR->memchunks,
	    memchunks_size * sizeof(void*))) == NULL) {
		free(ptr);
		@throw [OFOutOfMemoryException newWithClass: isa
						       size: memchunks_size];
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
					    size: size];

			*iter = ptr;
			return ptr;
		}
	}

	@throw [OFMemoryNotPartOfObjectException newWithClass: isa
						      pointer: ptr];
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

- (void)freeMemory: (void*)ptr;
{
	void **iter, *last, **memchunks;
	size_t i, memchunks_size;

	if (ptr == NULL)
		return;

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

				return;
			}

			free(ptr);
			PRE_IVAR->memchunks[i] = last;
			PRE_IVAR->memchunks_size = memchunks_size;

			if (OF_UNLIKELY((memchunks = realloc(
			    PRE_IVAR->memchunks, memchunks_size *
			    sizeof(void*))) == NULL))
				return;

			PRE_IVAR->memchunks = memchunks;

			return;
		}
	}

	@throw [OFMemoryNotPartOfObjectException newWithClass: isa
						      pointer: ptr];
}

- retain
{
#ifdef OF_ATOMIC_OPS
	of_atomic_inc_32(&PRE_IVAR->retain_count);
#else
	assert(of_spinlock_lock(&PRE_IVAR->retain_spinlock));
	PRE_IVAR->retain_count++;
	assert(of_spinlock_unlock(&PRE_IVAR->retain_spinlock));
#endif

	return self;
}

- (size_t)retainCount
{
	assert(PRE_IVAR->retain_count >= 0);
	return (size_t)PRE_IVAR->retain_count;
}

- (void)release
{
#ifdef OF_ATOMIC_OPS
	if (of_atomic_dec_32(&PRE_IVAR->retain_count) <= 0)
		[self dealloc];
#else
	size_t c;

	assert(of_spinlock_lock(&PRE_IVAR->retain_spinlock));
	c = --PRE_IVAR->retain_count;
	assert(of_spinlock_unlock(&PRE_IVAR->retain_spinlock));

	if (!c)
		[self dealloc];
#endif
}

- autorelease
{
	[OFAutoreleasePool addObjectToTopmostPool: self];

	return self;
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

/* Required to use properties with the Apple runtime */
- copyWithZone: (void*)zone
{
	if (zone != NULL)
		@throw [OFNotImplementedException newWithClass: isa
						      selector: _cmd];

	return [(id)self copy];
}

- mutableCopyWithZone: (void*)zone
{
	if (zone != NULL)
		@throw [OFNotImplementedException newWithClass: isa
						      selector: _cmd];

	return [(id)self mutableCopy];
}

/*
 * Those are needed as the root class is the superclass of the root class's
 * metaclass and thus instance methods can be sent to class objects as well.
 */
+ (void)addMemoryToPool: (void*)ptr
{
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
}

+ (void*)allocMemoryWithSize: (size_t)size
{
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
}

+ (void*)allocMemoryForNItems: (size_t)nitems
                     withSize: (size_t)size
{
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
}

+ (void*)resizeMemory: (void*)ptr
	       toSize: (size_t)size
{
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
}

+ (void*)resizeMemory: (void*)ptr
	     toNItems: (size_t)nitems
	     withSize: (size_t)size
{
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
}

+ (void)freeMemory: (void*)ptr
{
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
}

+ retain
{
	return self;
}

+ autorelease
{
	return self;
}

+ (size_t)retainCount
{
	return SIZE_MAX;
}

+ (void)release
{
}

+ (void)dealloc
{
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
}

+ copyWithZone: (void*)zone
{
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
}

+ mutableCopyWithZone: (void*)zone
{
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
}
@end
