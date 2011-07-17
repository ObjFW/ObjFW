/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#define __NO_EXT_QNX

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>

#include <assert.h>

#import "OFObject.h"
#import "OFAutoreleasePool.h"

#import "OFAllocFailedException.h"
#import "OFEnumerationMutationException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFMemoryNotPartOfObjectException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

#if defined(OF_OBJFW_RUNTIME)
# import <objfw-rt.h>
#elif defined(OF_OLD_GNU_RUNTIME)
# import <objc/objc-api.h>
# import <objc/sarray.h>
# import <objc/Protocol.h>
#else
# import <objc/runtime.h>
#endif

#ifdef _WIN32
# include <windows.h>
#endif

#import "OFString.h"

#if defined(OF_ATOMIC_OPS)
# import "atomic.h"
#elif defined(OF_THREADS)
# import "threading.h"
#endif

/* A few macros to reduce #ifdefs */
#ifdef OF_OLD_GNU_RUNTIME
# define class_getInstanceSize class_get_instance_size
# define class_getName class_get_class_name
# define class_getSuperclass class_get_super_class
# define sel_registerName sel_get_uid
#endif

struct pre_ivar {
	void	      **memchunks;
	size_t	      memchunks_size;
	int32_t	      retain_count;
#if !defined(OF_ATOMIC_OPS)
	of_spinlock_t retain_spinlock;
#endif
};

/* Hopefully no arch needs more than 16 bytes padding */
#ifndef __BIGGEST_ALIGNMENT__
# define __BIGGEST_ALIGNMENT__ 16
#endif

#define PRE_IVAR_ALIGN ((sizeof(struct pre_ivar) + \
	(__BIGGEST_ALIGNMENT__ - 1)) & ~(__BIGGEST_ALIGNMENT__ - 1))
#define PRE_IVAR ((struct pre_ivar*)(void*)((char*)self - PRE_IVAR_ALIGN))

static struct {
	Class isa;
} alloc_failed_exception;
static Class autoreleasepool = Nil;

static SEL cxx_construct = NULL;
static SEL cxx_destruct = NULL;

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
	@throw [OFEnumerationMutationException newWithClass: [obj class]
						     object: obj];
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

#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
	objc_setEnumerationMutationHandler(enumeration_mutation_handler);
#endif

	cxx_construct = sel_registerName(".cxx_construct");
	cxx_destruct = sel_registerName(".cxx_destruct");

	if (cxx_construct == NULL || cxx_destruct == NULL) {
		fputs("Runtime error: Failed to register selector "
		    ".cxx_construct and/or .cxx_destruct!\n", stderr);
		abort();
	}

#if defined(_WIN32)
	SYSTEM_INFO si;
	GetSystemInfo(&si);
	of_pagesize = si.dwPageSize;
#elif defined(_PSP)
	of_pagesize = 4096;
#else
	if ((of_pagesize = sysconf(_SC_PAGESIZE)) < 1)
		of_pagesize = 4096;
#endif
}

+ (void)initialize
{
}

+ alloc
{
	OFObject *instance;
	size_t isize = class_getInstanceSize(self);
	Class class;
	void (*last)(id, SEL) = NULL;

	if ((instance = malloc(isize + PRE_IVAR_ALIGN)) == NULL) {
		alloc_failed_exception.isa = [OFAllocFailedException class];
		@throw (OFAllocFailedException*)&alloc_failed_exception;
	}

	((struct pre_ivar*)instance)->memchunks = NULL;
	((struct pre_ivar*)instance)->memchunks_size = 0;
	((struct pre_ivar*)instance)->retain_count = 1;

#if !defined(OF_ATOMIC_OPS)
	if (!of_spinlock_new(&((struct pre_ivar*)instance)->retain_spinlock)) {
		free(instance);
		@throw [OFInitializationFailedException newWithClass: self];
	}
#endif

	instance = (OFObject*)((char*)instance + PRE_IVAR_ALIGN);
	memset(instance, 0, isize);
	instance->isa = self;

	for (class = self; class != Nil; class = class_getSuperclass(class)) {
		void (*construct)(id, SEL);

		if ([class instancesRespondToSelector: cxx_construct]) {
			if ((construct = (void(*)(id, SEL))[class
			    instanceMethodForSelector: cxx_construct]) != last)
				construct(instance, cxx_construct);

			last = construct;
		} else
			break;
	}

	return instance;
}

+ (Class)class
{
	return self;
}

+ (OFString*)className
{
	return [OFString stringWithCString: class_getName(self)];
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
#ifdef OF_OLD_GNU_RUNTIME
	return class_get_instance_method(self, selector) != METHOD_NULL;
#else
	return class_respondsToSelector(self, selector);
#endif
}

+ (BOOL)conformsToProtocol: (Protocol*)protocol
{
#ifdef OF_OLD_GNU_RUNTIME
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

+ (IMP)instanceMethodForSelector: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	return objc_get_instance_method(self, selector);
#elif defined(OF_OLD_GNU_RUNTIME)
	return method_get_imp(class_get_instance_method(self, selector));
#else
	return class_getMethodImplementation(self, selector);
#endif
}

+ (const char*)typeEncodingForInstanceSelector: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	const char *ret;

	if ((ret = objc_get_type_encoding(self, selector)) == NULL)
		@throw [OFNotImplementedException newWithClass: self
						      selector: selector];

	return ret;
#elif defined(OF_OLD_GNU_RUNTIME)
	Method_t m;

	if ((m = class_get_instance_method(self, selector)) == NULL ||
	    m->method_types == NULL)
		@throw [OFNotImplementedException newWithClass: self
						      selector: selector];

	return m->method_types;
#else
	Method m;
	const char *ret;

	if ((m = class_getInstanceMethod(self, selector)) == NULL ||
	    (ret = method_getTypeEncoding(m)) == NULL)
		@throw [OFNotImplementedException newWithClass: self
						      selector: selector];

	return ret;
#endif
}

+ (OFString*)description
{
	return [self className];
}

+ (IMP)setImplementation: (IMP)newimp
	  forClassMethod: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	if (newimp == (IMP)0 || !class_respondsToSelector(self->isa, selector))
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	return objc_replace_class_method(self, selector, newimp);
#elif defined(OF_OLD_GNU_RUNTIME)
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
#else
	Method method;

	if (newimp == (IMP)0 ||
	    (method = class_getClassMethod(self, selector)) == NULL)
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	/*
	 * Cast needed because it's isa in the Apple runtime, but class_pointer
	 * in the GNU runtime.
	 */
	return class_replaceMethod(((OFObject*)self)->isa, selector, newimp,
	    method_getTypeEncoding(method));
#endif
}

+ (IMP)replaceClassMethod: (SEL)selector
      withMethodFromClass: (Class)class
{
	IMP newimp;

	if (![class isSubclassOfClass: self])
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	newimp = [class methodForSelector: selector];

	return [self setImplementation: newimp
			forClassMethod: selector];
}

+ (IMP)setImplementation: (IMP)newimp
       forInstanceMethod: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	if (newimp == (IMP)0 || !class_respondsToSelector(self, selector))
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	return objc_replace_instance_method(self, selector, newimp);
#elif defined(OF_OLD_GNU_RUNTIME)
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
#else
	Method method;

	if (newimp == (IMP)0 ||
	    (method = class_getInstanceMethod(self, selector)) == NULL)
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	return class_replaceMethod(self, selector, newimp,
	    method_getTypeEncoding(method));
#endif
}

+ (IMP)replaceInstanceMethod: (SEL)selector
	 withMethodFromClass: (Class)class
{
	IMP newimp;

	if (![class isSubclassOfClass: self])
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	newimp = [class instanceMethodForSelector: selector];

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

- (OFString*)className
{
	return [OFString stringWithCString: class_getName(isa)];
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
#ifdef OF_OLD_GNU_RUNTIME
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
#if defined(OF_OBJFW_RUNTIME) || defined(OF_OLD_GNU_RUNTIME)
	return objc_msg_lookup(self, selector);
#else
	return class_getMethodImplementation(isa, selector);
#endif
}

- (id)performSelector: (SEL)selector
{
	id (*imp)(id, SEL) = (id(*)(id, SEL))[self methodForSelector: selector];

	return imp(self, selector);
}

- (id)performSelector: (SEL)selector
	   withObject: (id)obj
{
	id (*imp)(id, SEL, id) =
	    (id(*)(id, SEL, id))[self methodForSelector: selector];

	return imp(self, selector, obj);
}

- (id)performSelector: (SEL)selector
	   withObject: (id)obj1
	   withObject: (id)obj2
{
	id (*imp)(id, SEL, id, id) =
	    (id(*)(id, SEL, id, id))[self methodForSelector: selector];

	return imp(self, selector, obj1, obj2);
}

- (const char*)typeEncodingForSelector: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	const char *ret;

	if ((ret = objc_get_type_encoding(isa, selector)) == NULL)
		@throw [OFNotImplementedException newWithClass: isa
						      selector: selector];

	return ret;
#elif defined(OF_OLD_GNU_RUNTIME)
	Method_t m;

	if ((m = class_get_instance_method(isa, selector)) == NULL ||
	    m->method_types == NULL)
		@throw [OFNotImplementedException newWithClass: isa
						      selector: selector];

	return m->method_types;
#else
	Method m;
	const char *ret;

	if ((m = class_getInstanceMethod(isa, selector)) == NULL ||
	    (ret = method_getTypeEncoding(m)) == NULL)
		@throw [OFNotImplementedException newWithClass: isa
						      selector: selector];

	return ret;
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
	return (uint32_t)(uintptr_t)self;
}

- (OFString*)description
{
	/* Classes containing data should reimplement this! */
	return [OFString stringWithFormat: @"<%@: %p>", [self className], self];
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
					      requestedSize: memchunks_size];

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
					      requestedSize: size];

	if ((memchunks = realloc(PRE_IVAR->memchunks,
	    memchunks_size * sizeof(void*))) == NULL) {
		free(ptr);
		@throw [OFOutOfMemoryException newWithClass: isa
					      requestedSize: memchunks_size];
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
				    requestedSize: size];

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

- (void)freeMemory: (void*)ptr
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
#if defined(OF_ATOMIC_OPS)
	of_atomic_inc_32(&PRE_IVAR->retain_count);
#else
	assert(of_spinlock_lock(&PRE_IVAR->retain_spinlock));
	PRE_IVAR->retain_count++;
	assert(of_spinlock_unlock(&PRE_IVAR->retain_spinlock));
#endif

	return self;
}

- (unsigned int)retainCount
{
	assert(PRE_IVAR->retain_count >= 0);
	return PRE_IVAR->retain_count;
}

- (void)release
{
#if defined(OF_ATOMIC_OPS)
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
	/*
	 * Cache OFAutoreleasePool since class lookups are expensive with the
	 * GNU runtime.
	 */
	if (autoreleasepool == Nil)
		autoreleasepool = [OFAutoreleasePool class];

	[autoreleasepool addObject: self];

	return self;
}

- (void)dealloc
{
	Class class;
	void (*last)(id, SEL) = NULL;
	void **iter;

	for (class = isa; class != Nil; class = class_getSuperclass(class)) {
		void (*destruct)(id, SEL);

		if ([class instancesRespondToSelector: cxx_destruct]) {
			if ((destruct = (void(*)(id, SEL))[class
			    instanceMethodForSelector: cxx_destruct]) != last)
				destruct(self, cxx_destruct);

			last = destruct;
		} else
			break;
	}

	iter = PRE_IVAR->memchunks + PRE_IVAR->memchunks_size;
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

+ (unsigned int)retainCount
{
	return OF_RETAIN_COUNT_MAX;
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
