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
# import <objc/Protocol.h>
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

struct pre_ivar {
	void	      **memoryChunks;
	unsigned int  memoryChunksSize;
	int32_t	      retainCount;
#if !defined(OF_ATOMIC_OPS) && defined(OF_THREADS)
	of_spinlock_t retainCountSpinlock;
#endif
};

/* Hopefully no arch needs more than 16 bytes padding */
#ifndef __BIGGEST_ALIGNMENT__
# define __BIGGEST_ALIGNMENT__ 16
#endif

#define PRE_IVAR_ALIGN ((sizeof(struct pre_ivar) + \
	(__BIGGEST_ALIGNMENT__ - 1)) & ~(__BIGGEST_ALIGNMENT__ - 1))
#define PRE_IVAR ((struct pre_ivar*)(void*)((char*)self - PRE_IVAR_ALIGN))

#ifdef OF_OLD_GNU_RUNTIME
extern void __objc_update_dispatch_table_for_class(Class);
#endif

static struct {
	Class isa;
} alloc_failed_exception;
static Class autoreleasePool = Nil;

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
enumeration_mutation_handler(id object)
{
	@throw [OFEnumerationMutationException
	    exceptionWithClass: [object class]
			object: object];
}

#ifndef HAVE_OBJC_ENUMERATIONMUTATION
void
objc_enumerationMutation(id object)
{
	enumeration_mutation_handler(object);
}
#endif

#if defined(HAVE_OBJC_ENUMERATIONMUTATION) && defined(OF_OLD_GNU_RUNTIME)
extern void objc_setEnumerationMutationHandler(void(*handler)(id));
#endif

const char*
_NSPrintForDebugger(id object)
{
	return [[object description]
	    cStringWithEncoding: OF_STRING_ENCODING_NATIVE];
}

/* References for static linking */
void _references_to_categories_of_OFObject(void)
{
	_OFObject_Serialization_reference = 1;
}

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

#ifdef HAVE_OBJC_ENUMERATIONMUTATION
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
	size_t instanceSize = class_getInstanceSize(self);
	Class class;
	void (*last)(id, SEL) = NULL;

	if ((instance = malloc(instanceSize + PRE_IVAR_ALIGN)) == NULL) {
		alloc_failed_exception.isa = [OFAllocFailedException class];
		@throw (OFAllocFailedException*)&alloc_failed_exception;
	}

	((struct pre_ivar*)instance)->memoryChunks = NULL;
	((struct pre_ivar*)instance)->memoryChunksSize = 0;
	((struct pre_ivar*)instance)->retainCount = 1;

#if !defined(OF_ATOMIC_OPS) && defined(OF_THREADS)
	if (!of_spinlock_new(
	    &((struct pre_ivar*)instance)->retainCountSpinlock)) {
		free(instance);
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	}
#endif

	instance = (OFObject*)((char*)instance + PRE_IVAR_ALIGN);
	memset(instance, 0, instanceSize);
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

+ new
{
	return [[self alloc] init];
}

+ (Class)class
{
	return self;
}

+ (OFString*)className
{
	return [OFString stringWithCString: class_getName(self)
				  encoding: OF_STRING_ENCODING_ASCII];
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
		@throw [OFNotImplementedException exceptionWithClass: self
							    selector: selector];

	return ret;
#elif defined(OF_OLD_GNU_RUNTIME)
	Method_t m;

	if ((m = class_get_instance_method(self, selector)) == NULL ||
	    m->method_types == NULL)
		@throw [OFNotImplementedException exceptionWithClass: self
							    selector: selector];

	return m->method_types;
#else
	Method m;
	const char *ret;

	if ((m = class_getInstanceMethod(self, selector)) == NULL ||
	    (ret = method_getTypeEncoding(m)) == NULL)
		@throw [OFNotImplementedException exceptionWithClass: self
							    selector: selector];

	return ret;
#endif
}

+ (OFString*)description
{
	return [self className];
}

+ (IMP)setImplementation: (IMP)newImp
	  forClassMethod: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	if (newImp == (IMP)0 || !class_respondsToSelector(self->isa, selector))
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

	return objc_replace_class_method(self, selector, newImp);
#elif defined(OF_OLD_GNU_RUNTIME)
	Method_t method;
	MethodList_t iter;

	method = class_get_class_method(self->class_pointer, selector);

	if (newImp == (IMP)0 || method == METHOD_NULL)
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

	for (iter = ((Class)self->class_pointer)->methods; iter != NULL;
	    iter = iter->method_next) {
		int i;

		for (i = 0; i < iter->method_count; i++)
			if (sel_eq(iter->method_list[i].method_name,
			    selector)) {
				IMP oldImp;

				oldImp = iter->method_list[i].method_imp;
				iter->method_list[i].method_imp = newImp;

				__objc_update_dispatch_table_for_class(
				    (Class)self->class_pointer);

				return oldImp;
			}
	}

	assert([self addClassMethod: selector
		   withTypeEncoding: method->method_types
		     implementation: newImp]);

	return (IMP)0;
#else
	Method method;

	if (newImp == (IMP)0 ||
	    (method = class_getClassMethod(self, selector)) == NULL)
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

	/*
	 * Cast needed because it's isa in the Apple runtime, but class_pointer
	 * in the GNU runtime.
	 */
	return class_replaceMethod(((OFObject*)self)->isa, selector, newImp,
	    method_getTypeEncoding(method));
#endif
}

+ (IMP)replaceClassMethod: (SEL)selector
      withMethodFromClass: (Class)class
{
	IMP newImp;

	if (![class isSubclassOfClass: self])
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

	newImp = [class methodForSelector: selector];

	return [self setImplementation: newImp
			forClassMethod: selector];
}

+ (IMP)setImplementation: (IMP)newImp
       forInstanceMethod: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	if (newImp == (IMP)0 || !class_respondsToSelector(self, selector))
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

	return objc_replace_instance_method(self, selector, newImp);
#elif defined(OF_OLD_GNU_RUNTIME)
	Method_t method;
	MethodList_t iter;

	method = class_get_instance_method(self, selector);

	if (newImp == (IMP)0 || method == METHOD_NULL)
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

	for (iter = ((Class)self)->methods; iter != NULL;
	    iter = iter->method_next) {
		int i;

		for (i = 0; i < iter->method_count; i++)
			if (sel_eq(iter->method_list[i].method_name,
			    selector)) {
				IMP oldImp;

				oldImp = iter->method_list[i].method_imp;
				iter->method_list[i].method_imp = newImp;

				__objc_update_dispatch_table_for_class(self);

				return oldImp;
			}
	}

	assert([self addInstanceMethod: selector
		      withTypeEncoding: method->method_types
			implementation: newImp]);

	return (IMP)0;
#else
	Method method;

	if (newImp == (IMP)0 ||
	    (method = class_getInstanceMethod(self, selector)) == NULL)
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

	return class_replaceMethod(self, selector, newImp,
	    method_getTypeEncoding(method));
#endif
}

+ (IMP)replaceInstanceMethod: (SEL)selector
	 withMethodFromClass: (Class)class
{
	IMP newImp;

	if (![class isSubclassOfClass: self])
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

	newImp = [class instanceMethodForSelector: selector];

	return [self setImplementation: newImp
		     forInstanceMethod: selector];
}

+ (BOOL)addInstanceMethod: (SEL)selector
	 withTypeEncoding: (const char*)typeEncoding
	   implementation: (IMP)implementation
{
#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
	return class_addMethod(self, selector, implementation, typeEncoding);
#elif defined(OF_OLD_GNU_RUNTIME)
	MethodList_t methodList;

	for (methodList = ((Class)self)->methods; methodList != NULL;
	    methodList = methodList->method_next) {
		int i;

		for (i = 0; i < methodList->method_count; i++)
			if (sel_eq(methodList->method_list[i].method_name,
			    selector))
				return NO;
	}

	if ((methodList = malloc(sizeof(*methodList))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithClass: self
			 requestedSize: sizeof(*methodList)];

	methodList->method_next = ((Class)self)->methods;
	methodList->method_count = 1;

	methodList->method_list[0].method_name = selector;
	methodList->method_list[0].method_types = typeEncoding;
	methodList->method_list[0].method_imp = implementation;

	((Class)self)->methods = methodList;

	__objc_update_dispatch_table_for_class(self);

	return YES;
#else
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
#endif
}

+ (BOOL)addClassMethod: (SEL)selector
      withTypeEncoding: (const char*)typeEncoding
	implementation: (IMP)implementation
{
#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
	return class_addMethod(((OFObject*)self)->isa, selector, implementation,
	    typeEncoding);
#elif defined(OF_OLD_GNU_RUNTIME)
	MethodList_t methodList;

	for (methodList = ((Class)self->class_pointer)->methods;
	    methodList != NULL; methodList = methodList->method_next) {
		int i;

		for (i = 0; i < methodList->method_count; i++)
			if (sel_eq(methodList->method_list[i].method_name,
			    selector))
				return NO;
	}

	if ((methodList = malloc(sizeof(*methodList))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithClass: self
			 requestedSize: sizeof(*methodList)];

	methodList->method_next = ((Class)self->class_pointer)->methods;
	methodList->method_count = 1;

	methodList->method_list[0].method_name = selector;
	methodList->method_list[0].method_types = typeEncoding;
	methodList->method_list[0].method_imp = implementation;

	((Class)self->class_pointer)->methods = methodList;

	__objc_update_dispatch_table_for_class((Class)self->class_pointer);

	return YES;
#else
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
#endif
}

+ (void)inheritMethodsFromClass: (Class)class
{
	Class superclass = [self superclass];

	if ([self isSubclassOfClass: class])
		return;

#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
	Method *methodList;
	unsigned i, count;

	methodList = class_copyMethodList(((OFObject*)class)->isa, &count);
	@try {
		for (i = 0; i < count; i++) {
			SEL selector = method_getName(methodList[i]);
			IMP implementation;

			/*
			 * Don't replace methods implemented in receiving class.
			 */
			if ([self methodForSelector: selector] !=
			    [superclass methodForSelector: selector])
				continue;

			implementation = [class methodForSelector: selector];

			if ([self respondsToSelector: selector])
				[self setImplementation: implementation
					 forClassMethod: selector];
			else {
				const char *typeEncoding =
				    method_getTypeEncoding(methodList[i]);
				[self addClassMethod: selector
				    withTypeEncoding: typeEncoding
				      implementation: implementation];
			}
		}
	} @finally {
		free(methodList);
	}

	methodList = class_copyMethodList(class, &count);
	@try {
		for (i = 0; i < count; i++) {
			SEL selector = method_getName(methodList[i]);
			IMP implementation;

			/*
			 * Don't replace methods implemented in receiving class.
			 */
			if ([self instanceMethodForSelector: selector] !=
			    [superclass instanceMethodForSelector: selector])
				continue;

			implementation =
			    [class instanceMethodForSelector: selector];

			if ([self instancesRespondToSelector: selector])
				     [self setImplementation: implementation
					   forInstanceMethod: selector];
			else {
				const char *typeEncoding =
				    method_getTypeEncoding(methodList[i]);
				[self addInstanceMethod: selector
				       withTypeEncoding: typeEncoding
					 implementation: implementation];
			}
		}
	} @finally {
		free(methodList);
	}
#elif defined(OF_OLD_GNU_RUNTIME)
	MethodList_t methodList;

	for (methodList = class->class_pointer->methods;
	    methodList != NULL; methodList = methodList->method_next) {
		int i;

		for (i = 0; i < methodList->method_count; i++) {
			SEL selector = methodList->method_list[i].method_name;
			IMP implementation;

			/*
			 * Don't replace methods implemented in receiving class.
			 */
			if ([self methodForSelector: selector] !=
			    [superclass methodForSelector: selector])
				continue;

			implementation = [class methodForSelector: selector];

			if ([self respondsToSelector: selector])
				     [self setImplementation: implementation
					      forClassMethod: selector];
			else {
				const char *typeEncoding =
				    methodList->method_list[i].method_types;
				[self addClassMethod: selector
				    withTypeEncoding: typeEncoding
				      implementation: implementation];
			}
		}
	}

	for (methodList = class->methods; methodList != NULL;
	    methodList = methodList->method_next) {
		int i;

		for (i = 0; i < methodList->method_count; i++) {
			SEL selector = methodList->method_list[i].method_name;
			IMP implementation;

			/*
			 * Don't replace methods implemented in receiving class.
			 */
			if ([self instanceMethodForSelector: selector] !=
			    [superclass instanceMethodForSelector: selector])
				continue;

			implementation =
			    [class instanceMethodForSelector: selector];

			if ([self instancesRespondToSelector: selector])
				     [self setImplementation: implementation
					   forInstanceMethod: selector];
			else {
				const char *typeEncoding =
				    methodList->method_list[i].method_types;
				[self addInstanceMethod: selector
				       withTypeEncoding: typeEncoding
					 implementation: implementation];
			}
		}
	}
#else
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
#endif

	[self inheritMethodsFromClass: [class superclass]];
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
	return [OFString stringWithCString: class_getName(isa)
				  encoding: OF_STRING_ENCODING_ASCII];
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
	   withObject: (id)object
{
	id (*imp)(id, SEL, id) =
	    (id(*)(id, SEL, id))[self methodForSelector: selector];

	return imp(self, selector, object);
}

- (id)performSelector: (SEL)selector
	   withObject: (id)object
	   withObject: (id)otherObject
{
	id (*imp)(id, SEL, id, id) =
	    (id(*)(id, SEL, id, id))[self methodForSelector: selector];

	return imp(self, selector, object, otherObject);
}

- (const char*)typeEncodingForSelector: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	const char *ret;

	if ((ret = objc_get_type_encoding(isa, selector)) == NULL)
		@throw [OFNotImplementedException exceptionWithClass: isa
							    selector: selector];

	return ret;
#elif defined(OF_OLD_GNU_RUNTIME)
	Method_t m;

	if ((m = class_get_instance_method(isa, selector)) == NULL ||
	    m->method_types == NULL)
		@throw [OFNotImplementedException exceptionWithClass: isa
							    selector: selector];

	return m->method_types;
#else
	Method m;
	const char *ret;

	if ((m = class_getInstanceMethod(isa, selector)) == NULL ||
	    (ret = method_getTypeEncoding(m)) == NULL)
		@throw [OFNotImplementedException exceptionWithClass: isa
							    selector: selector];

	return ret;
#endif
}

- (BOOL)isEqual: (id)object
{
	/* Classes containing data should reimplement this! */
	return (self == object);
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

- (void)addMemoryToPool: (void*)pointer
{
	void **memoryChunks;
	unsigned int memoryChunksSize;

	memoryChunksSize = PRE_IVAR->memoryChunksSize + 1;

	if (UINT_MAX - PRE_IVAR->memoryChunksSize < 1 ||
	    memoryChunksSize > UINT_MAX / sizeof(void*))
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	if ((memoryChunks = realloc(PRE_IVAR->memoryChunks,
	    memoryChunksSize * sizeof(void*))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithClass: isa
			 requestedSize: memoryChunksSize];

	PRE_IVAR->memoryChunks = memoryChunks;
	PRE_IVAR->memoryChunks[PRE_IVAR->memoryChunksSize] = pointer;
	PRE_IVAR->memoryChunksSize = memoryChunksSize;
}

- (void*)allocMemoryWithSize: (size_t)size
{
	void *pointer, **memoryChunks;
	unsigned int memoryChunksSize;

	if (size == 0)
		return NULL;

	memoryChunksSize = PRE_IVAR->memoryChunksSize + 1;

	if (UINT_MAX - PRE_IVAR->memoryChunksSize == 0 ||
	    memoryChunksSize > UINT_MAX / sizeof(void*))
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	if ((pointer = malloc(size)) == NULL)
		@throw [OFOutOfMemoryException exceptionWithClass: isa
						    requestedSize: size];

	if ((memoryChunks = realloc(PRE_IVAR->memoryChunks,
	    memoryChunksSize * sizeof(void*))) == NULL) {
		free(pointer);
		@throw [OFOutOfMemoryException
		    exceptionWithClass: isa
			 requestedSize: memoryChunksSize];
	}

	PRE_IVAR->memoryChunks = memoryChunks;
	PRE_IVAR->memoryChunks[PRE_IVAR->memoryChunksSize] = pointer;
	PRE_IVAR->memoryChunksSize = memoryChunksSize;

	return pointer;
}

- (void*)allocMemoryForNItems: (size_t)nItems
		       ofSize: (size_t)size
{
	if (nItems == 0 || size == 0)
		return NULL;

	if (nItems > SIZE_MAX / size)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	return [self allocMemoryWithSize: nItems * size];
}

- (void*)resizeMemory: (void*)pointer
	       toSize: (size_t)size
{
	void **iter;

	if (pointer == NULL)
		return [self allocMemoryWithSize: size];

	if (size == 0) {
		[self freeMemory: pointer];
		return NULL;
	}

	iter = PRE_IVAR->memoryChunks + PRE_IVAR->memoryChunksSize;

	while (iter-- > PRE_IVAR->memoryChunks) {
		if (OF_UNLIKELY(*iter == pointer)) {
			if (OF_UNLIKELY((pointer = realloc(pointer,
			    size)) == NULL))
				@throw [OFOutOfMemoryException
				     exceptionWithClass: isa
					  requestedSize: size];

			*iter = pointer;
			return pointer;
		}
	}

	@throw [OFMemoryNotPartOfObjectException exceptionWithClass: isa
							    pointer: pointer];
}

- (void*)resizeMemory: (void*)pointer
	     toNItems: (size_t)nItems
	       ofSize: (size_t)size
{
	if (pointer == NULL)
		return [self allocMemoryForNItems: nItems
					   ofSize: size];

	if (nItems == 0 || size == 0) {
		[self freeMemory: pointer];
		return NULL;
	}

	if (nItems > SIZE_MAX / size)
		@throw [OFOutOfRangeException exceptionWithClass: isa];

	return [self resizeMemory: pointer
			   toSize: nItems * size];
}

- (void)freeMemory: (void*)pointer
{
	void **iter, *last, **memoryChunks;
	unsigned int i, memoryChunksSize;

	if (pointer == NULL)
		return;

	iter = PRE_IVAR->memoryChunks + PRE_IVAR->memoryChunksSize;
	i = PRE_IVAR->memoryChunksSize;

	while (iter-- > PRE_IVAR->memoryChunks) {
		i--;

		if (OF_UNLIKELY(*iter == pointer)) {
			memoryChunksSize = PRE_IVAR->memoryChunksSize - 1;
			last = PRE_IVAR->memoryChunks[memoryChunksSize];

			assert(PRE_IVAR->memoryChunksSize != 0 &&
			    memoryChunksSize <= UINT_MAX / sizeof(void*));

			if (OF_UNLIKELY(memoryChunksSize == 0)) {
				free(pointer);
				free(PRE_IVAR->memoryChunks);

				PRE_IVAR->memoryChunks = NULL;
				PRE_IVAR->memoryChunksSize = 0;

				return;
			}

			free(pointer);
			PRE_IVAR->memoryChunks[i] = last;
			PRE_IVAR->memoryChunksSize = memoryChunksSize;

			if (OF_UNLIKELY((memoryChunks = realloc(
			    PRE_IVAR->memoryChunks, memoryChunksSize *
			    sizeof(void*))) == NULL))
				return;

			PRE_IVAR->memoryChunks = memoryChunks;

			return;
		}
	}

	@throw [OFMemoryNotPartOfObjectException exceptionWithClass: isa
							    pointer: pointer];
}

- retain
{
#if defined(OF_ATOMIC_OPS)
	of_atomic_inc_32(&PRE_IVAR->retainCount);
#elif defined(OF_THREADS)
	assert(of_spinlock_lock(&PRE_IVAR->retainCountSpinlock));
	PRE_IVAR->retainCount++;
	assert(of_spinlock_unlock(&PRE_IVAR->retainCountSspinlock));
#else
	PRE_IVAR->retainCount++;
#endif

	return self;
}

- (unsigned int)retainCount
{
	assert(PRE_IVAR->retainCount >= 0);
	return PRE_IVAR->retainCount;
}

- (void)release
{
#if defined(OF_ATOMIC_OPS)
	if (of_atomic_dec_32(&PRE_IVAR->retainCount) <= 0)
		[self dealloc];
#elif defined(OF_THREADS)
	size_t c;

	assert(of_spinlock_lock(&PRE_IVAR->retainCountSpinlock));
	c = --PRE_IVAR->retainCount;
	assert(of_spinlock_unlock(&PRE_IVAR->retainCountSpinlock));

	if (c == 0)
		[self dealloc];
#else
	if (--PRE_IVAR->retainCount == 0)
		[self dealloc];
#endif
}

- autorelease
{
	/*
	 * Cache OFAutoreleasePool since class lookups are expensive with the
	 * GNU runtime.
	 */
	if (autoreleasePool == Nil)
		autoreleasePool = [OFAutoreleasePool class];

	[autoreleasePool addObject: self];

	return self;
}

- self
{
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

	iter = PRE_IVAR->memoryChunks + PRE_IVAR->memoryChunksSize;
	while (iter-- > PRE_IVAR->memoryChunks)
		free(*iter);

	if (PRE_IVAR->memoryChunks != NULL)
		free(PRE_IVAR->memoryChunks);

	free((char*)self - PRE_IVAR_ALIGN);
}

/* Required to use properties with the Apple runtime */
- copyWithZone: (void*)zone
{
	if (zone != NULL)
		@throw [OFNotImplementedException exceptionWithClass: isa
							    selector: _cmd];

	return [(id)self copy];
}

- mutableCopyWithZone: (void*)zone
{
	if (zone != NULL)
		@throw [OFNotImplementedException exceptionWithClass: isa
							    selector: _cmd];

	return [(id)self mutableCopy];
}

/*
 * Those are needed as the root class is the superclass of the root class's
 * metaclass and thus instance methods can be sent to class objects as well.
 */
+ (void)addMemoryToPool: (void*)pointer
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

+ (void*)allocMemoryWithSize: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

+ (void*)allocMemoryForNItems: (size_t)nItems
		       ofSize: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

+ (void*)resizeMemory: (void*)pointer
	       toSize: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

+ (void*)resizeMemory: (void*)pointer
	     toNItems: (size_t)nItems
	      ofSize: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

+ (void)freeMemory: (void*)pointer
{
	@throw [OFNotImplementedException exceptionWithClass: self
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
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

+ copyWithZone: (void*)zone
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

+ mutableCopyWithZone: (void*)zone
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}
@end
