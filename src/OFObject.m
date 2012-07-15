/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#ifdef __QNX__
# include <sys/syspage.h>
#endif

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

#if defined(OF_APPLE_RUNTIME) && __OBJC2__
# import <objc/objc-exception.h>
#elif defined(OF_OBJFW_RUNTIME)
# import "runtime.h"
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
	int32_t retainCount;
	struct pre_mem *firstMem, *lastMem;
#if !defined(OF_ATOMIC_OPS) && defined(OF_THREADS)
	of_spinlock_t retainCountSpinlock;
#endif
};

struct pre_mem {
	struct pre_mem *prev, *next;
	id owner;
};

#define PRE_IVAR_ALIGN ((sizeof(struct pre_ivar) + \
	(__BIGGEST_ALIGNMENT__ - 1)) & ~(__BIGGEST_ALIGNMENT__ - 1))
#define PRE_IVAR ((struct pre_ivar*)(void*)((char*)self - PRE_IVAR_ALIGN))

#define PRE_MEM_ALIGN ((sizeof(struct pre_mem) + \
	(__BIGGEST_ALIGNMENT__ - 1)) & ~(__BIGGEST_ALIGNMENT__ - 1))
#define PRE_MEM(mem) ((struct pre_mem*)(void*)((char*)mem - PRE_MEM_ALIGN))

static struct {
	Class isa;
} alloc_failed_exception;
static Class autoreleasePool = Nil;

static SEL cxx_construct = NULL;
static SEL cxx_destruct = NULL;

size_t of_pagesize;
size_t of_num_cpus;

#ifdef OF_OBJFW_RUNTIME
extern BOOL objc_sync_init();
extern BOOL objc_properties_init();
#endif

#if !defined(OF_APPLE_RUNTIME) || defined(__OBJC2__)
static void
uncaught_exception_handler(id exception)
{
	fprintf(stderr, "\nUnhandled exception:\n%s\n",
	    [[exception description] UTF8String]);
}
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

id
of_alloc_object(Class class, size_t extraSize, size_t extraAlignment,
    void **extra)
{
	OFObject *instance;
	size_t instanceSize;

	instanceSize = class_getInstanceSize(class);

	if (OF_UNLIKELY(extraAlignment > 0))
		extraAlignment = ((instanceSize + extraAlignment - 1) &
		    ~(extraAlignment - 1)) - extraAlignment;

	instance = malloc(PRE_IVAR_ALIGN + instanceSize +
	    extraAlignment + extraSize);

	if (OF_UNLIKELY(instance == nil)) {
		object_setClass((id)&alloc_failed_exception,
		    [OFAllocFailedException class]);
		@throw (id)&alloc_failed_exception;
	}

	((struct pre_ivar*)instance)->retainCount = 1;
	((struct pre_ivar*)instance)->firstMem = NULL;
	((struct pre_ivar*)instance)->lastMem = NULL;

#if !defined(OF_ATOMIC_OPS) && defined(OF_THREADS)
	if (OF_UNLIKELY(!of_spinlock_new(
	    &((struct pre_ivar*)instance)->retainCountSpinlock))) {
		free(instance);
		@throw [OFInitializationFailedException
		    exceptionWithClass: class];
	}
#endif

	instance = (OFObject*)((char*)instance + PRE_IVAR_ALIGN);

	memset(instance, 0, instanceSize);
	object_setClass(instance, class);

	if (OF_UNLIKELY(extra != NULL))
		*extra = (char*)instance + instanceSize + extraAlignment;

	return instance;
}

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
#ifdef OF_OBJFW_RUNTIME
	if (!objc_sync_init()) {
		fputs("Runtime error: objc_sync_init() failed!\n", stderr);
		abort();
	}

	if (!objc_properties_init()) {
		fputs("Runtime error: objc_properties_init() failed!\n",
		    stderr);
		abort();
	}
#endif

#if !defined(OF_APPLE_RUNTIME) || defined(__OBJC2__)
	objc_setUncaughtExceptionHandler(uncaught_exception_handler);
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
	of_num_cpus = si.dwNumberOfProcessors;
#elif defined(__QNX__)
	if ((of_pagesize = sysconf(_SC_PAGESIZE)) < 1)
		of_pagesize = 4096;
	of_num_cpus = _syspage_ptr->num_cpu;
#else
# ifdef _SC_PAGESIZE
	if ((of_pagesize = sysconf(_SC_PAGESIZE)) < 1)
# endif
		of_pagesize = 4096;
# ifdef _SC_NPROCESSORS_CONF
	if ((of_num_cpus = sysconf(_SC_NPROCESSORS_CONF)) < 1)
# endif
		of_num_cpus = 1;
#endif
}

+ (void)initialize
{
}

+ alloc
{
	return of_alloc_object(self, 0, 0, NULL);
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
	return class_respondsToSelector(self, selector);
}

+ (BOOL)conformsToProtocol: (Protocol*)protocol
{
	Class c;

	for (c = self; c != Nil; c = class_getSuperclass(c))
		if (class_conformsToProtocol(c, protocol))
			return YES;

	return NO;
}

+ (IMP)instanceMethodForSelector: (SEL)selector
{
	return class_getMethodImplementation(self, selector);
}

+ (const char*)typeEncodingForInstanceSelector: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	const char *ret;

	if ((ret = objc_get_type_encoding(self, selector)) == NULL)
		@throw [OFNotImplementedException exceptionWithClass: self
							    selector: selector];

	return ret;
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

+ (IMP)replaceClassMethod: (SEL)selector
      withMethodFromClass: (Class)class
{
	IMP newImp;
	const char *typeEncoding;

	newImp = [class methodForSelector: selector];
	typeEncoding = [class typeEncodingForSelector: selector];

	return [self replaceClassMethod: selector
		     withImplementation: newImp
			   typeEncoding: typeEncoding];
}

+ (IMP)replaceInstanceMethod: (SEL)selector
	 withMethodFromClass: (Class)class
{
	IMP newImp;
	const char *typeEncoding;

	newImp = [class instanceMethodForSelector: selector];
	typeEncoding = [class typeEncodingForInstanceSelector: selector];

	return [self replaceInstanceMethod: selector
			withImplementation: newImp
			      typeEncoding: typeEncoding];
}

+ (IMP)replaceInstanceMethod: (SEL)selector
	  withImplementation: (IMP)implementation
		typeEncoding: (const char*)typeEncoding
{
	return class_replaceMethod(self, selector, implementation,
	    typeEncoding);
}

+ (IMP)replaceClassMethod: (SEL)selector
       withImplementation: (IMP)implementation
	     typeEncoding: (const char*)typeEncoding
{
	return class_replaceMethod(object_getClass(self), selector,
	    implementation, typeEncoding);
}

+ (void)inheritMethodsFromClass: (Class)class
{
	Class superclass = [self superclass];

	if ([self isSubclassOfClass: class])
		return;

#if defined(OF_APPLE_RUNTIME)
	Method *methodList;
	unsigned i, count;

	methodList = class_copyMethodList(object_getClass(class), &count);
	@try {
		for (i = 0; i < count; i++) {
			SEL selector = method_getName(methodList[i]);

			/*
			 * Don't replace methods implemented in receiving class.
			 */
			if ([self methodForSelector: selector] !=
			    [superclass methodForSelector: selector])
				continue;

			[self replaceClassMethod: selector
			     withMethodFromClass: class];
		}
	} @finally {
		free(methodList);
	}

	methodList = class_copyMethodList(class, &count);
	@try {
		for (i = 0; i < count; i++) {
			SEL selector = method_getName(methodList[i]);

			/*
			 * Don't replace methods implemented in receiving class.
			 */
			if ([self instanceMethodForSelector: selector] !=
			    [superclass instanceMethodForSelector: selector])
				continue;

			[self replaceInstanceMethod: selector
				withMethodFromClass: class];
		}
	} @finally {
		free(methodList);
	}
#elif defined(OF_OBJFW_RUNTIME)
	struct objc_method_list *methodlist;

	for (methodlist = object_getClass(class)->methodlist;
	    methodlist != NULL; methodlist = methodlist->next) {
		int i;

		for (i = 0; i < methodlist->count; i++) {
			SEL selector = (SEL)&methodlist->methods[i].sel;

			/*
			 * Don't replace methods implemented in receiving class.
			 */
			if ([self methodForSelector: selector] !=
			    [superclass methodForSelector: selector])
				continue;

			[self replaceClassMethod: selector
			     withMethodFromClass: class];
		}
	}

	for (methodlist = class->methodlist; methodlist != NULL;
	    methodlist = methodlist->next) {
		int i;

		for (i = 0; i < methodlist->count; i++) {
			SEL selector = (SEL)&methodlist->methods[i].sel;

			/*
			 * Don't replace methods implemented in receiving class.
			 */
			if ([self instanceMethodForSelector: selector] !=
			    [superclass instanceMethodForSelector: selector])
				continue;

			[self replaceInstanceMethod: selector
				withMethodFromClass: class];
		}
	}
#endif

	[self inheritMethodsFromClass: [class superclass]];
}

- init
{
	Class class;
	void (*last)(id, SEL) = NULL;

	for (class = object_getClass(self); class != Nil;
	    class = class_getSuperclass(class)) {
		void (*construct)(id, SEL);

		if ([class instancesRespondToSelector: cxx_construct]) {
			if ((construct = (void(*)(id, SEL))[class
			    instanceMethodForSelector: cxx_construct]) != last)
				construct(self, cxx_construct);

			last = construct;
		} else
			break;
	}

	return self;
}

- (Class)class
{
	return object_getClass(self);
}

- (OFString*)className
{
	return [OFString stringWithCString: object_getClassName(self)
				  encoding: OF_STRING_ENCODING_ASCII];
}

- (BOOL)isKindOfClass: (Class)class
{
	Class iter;

	for (iter = object_getClass(self); iter != Nil;
	    iter = class_getSuperclass(iter))
		if (iter == class)
			return YES;

	return NO;
}

- (BOOL)isMemberOfClass: (Class)class
{
	return (object_getClass(self) == class);
}

- (BOOL)respondsToSelector: (SEL)selector
{
	return class_respondsToSelector(object_getClass(self), selector);
}

- (BOOL)conformsToProtocol: (Protocol*)protocol
{
	return [object_getClass(self) conformsToProtocol: protocol];
}

- (IMP)methodForSelector: (SEL)selector
{
	return class_getMethodImplementation(object_getClass(self), selector);
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

	if ((ret = objc_get_type_encoding(object_getClass(self),
	    selector)) == NULL)
		@throw [OFNotImplementedException
		    exceptionWithClass: [self class]
			      selector: selector];

	return ret;
#else
	Method m;
	const char *ret;

	if ((m = class_getInstanceMethod(object_getClass(self),
	    selector)) == NULL || (ret = method_getTypeEncoding(m)) == NULL)
		@throw [OFNotImplementedException
		    exceptionWithClass: [self class]
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

- (void*)allocMemoryWithSize: (size_t)size
{
	void *pointer;
	struct pre_mem *preMem;

	if (size > SIZE_MAX - PRE_IVAR_ALIGN)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	if ((pointer = malloc(PRE_MEM_ALIGN + size)) == NULL)
		@throw [OFOutOfMemoryException exceptionWithClass: [self class]
						    requestedSize: size];
	preMem = pointer;

	preMem->owner = self;
	preMem->prev = PRE_IVAR->lastMem;
	preMem->next = NULL;

	if (PRE_IVAR->lastMem != NULL)
		PRE_IVAR->lastMem->next = preMem;

	if (PRE_IVAR->firstMem == NULL)
		PRE_IVAR->firstMem = preMem;
	PRE_IVAR->lastMem = preMem;

	return (char*)pointer + PRE_MEM_ALIGN;
}

- (void*)allocMemoryWithSize: (size_t)size
		       count: (size_t)count
{
	if (size == 0 || count == 0)
		return NULL;

	if (count > SIZE_MAX / size)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	return [self allocMemoryWithSize: size * count];
}

- (void*)resizeMemory: (void*)pointer
		 size: (size_t)size
{
	void *new;
	struct pre_mem *preMem;

	if (pointer == NULL)
		return [self allocMemoryWithSize: size];

	if (size == 0) {
		[self freeMemory: pointer];
		return NULL;
	}

	if (PRE_MEM(pointer)->owner != self)
		@throw [OFMemoryNotPartOfObjectException
		    exceptionWithClass: [self class]
			       pointer: pointer];

	if ((new = realloc(PRE_MEM(pointer), PRE_MEM_ALIGN + size)) == NULL)
		@throw [OFOutOfMemoryException exceptionWithClass: [self class]
						    requestedSize: size];
	preMem = new;

	if (preMem != PRE_MEM(pointer)) {
		if (preMem->prev != NULL)
			preMem->prev->next = preMem;
		if (preMem->next != NULL)
			preMem->next->prev = preMem;

		if (PRE_IVAR->firstMem == PRE_MEM(pointer))
			PRE_IVAR->firstMem = preMem;
		if (PRE_IVAR->lastMem == PRE_MEM(pointer))
			PRE_IVAR->lastMem = preMem;
	}

	return (char*)new + PRE_MEM_ALIGN;
}

- (void*)resizeMemory: (void*)pointer
		 size: (size_t)size
		count: (size_t)count
{
	if (pointer == NULL)
		return [self allocMemoryWithSize: size
					   count: count];

	if (size == 0 || count == 0) {
		[self freeMemory: pointer];
		return NULL;
	}

	if (count > SIZE_MAX / size)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	return [self resizeMemory: pointer
			     size: size * count];
}

- (void)freeMemory: (void*)pointer
{
	if (pointer == NULL)
		return;

	if (PRE_MEM(pointer)->owner != self)
		@throw [OFMemoryNotPartOfObjectException
		    exceptionWithClass: [self class]
			       pointer: pointer];

	if (PRE_MEM(pointer)->prev != NULL)
		PRE_MEM(pointer)->prev->next = PRE_MEM(pointer)->next;
	if (PRE_MEM(pointer)->next != NULL)
		PRE_MEM(pointer)->next->prev = PRE_MEM(pointer)->prev;

	if (PRE_IVAR->firstMem == PRE_MEM(pointer))
		PRE_IVAR->firstMem = PRE_MEM(pointer)->next;
	if (PRE_IVAR->lastMem == PRE_MEM(pointer))
		PRE_IVAR->lastMem = PRE_MEM(pointer)->prev;

	/* To detect double-free */
	PRE_MEM(pointer)->owner = nil;

	free(PRE_MEM(pointer));
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
	 * GNU ABI.
	 */
	if (autoreleasePool == Nil)
		autoreleasePool = [OFAutoreleasePool class];

	return [autoreleasePool addObject: self];
}

- self
{
	return self;
}

- (BOOL)isProxy
{
	return NO;
}

- (void)dealloc
{
	Class class;
	void (*last)(id, SEL) = NULL;
	struct pre_mem *iter;

	for (class = object_getClass(self); class != Nil;
	    class = class_getSuperclass(class)) {
		void (*destruct)(id, SEL);

		if ([class instancesRespondToSelector: cxx_destruct]) {
			if ((destruct = (void(*)(id, SEL))[class
			    instanceMethodForSelector: cxx_destruct]) != last)
				destruct(self, cxx_destruct);

			last = destruct;
		} else
			break;
	}

	iter = PRE_IVAR->firstMem;
	while (iter != NULL) {
		struct pre_mem *next = iter->next;

		/*
		 * We can use owner as a sentinel to prevent exploitation in
		 * case there is a buffer underflow somewhere.
		 */
		if (iter->owner != self)
			abort();

		free(iter);

		iter = next;
	}

	free((char*)self - PRE_IVAR_ALIGN);
}

/* Required to use properties with the Apple runtime */
- copyWithZone: (void*)zone
{
	if (zone != NULL)
		@throw [OFNotImplementedException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	return [(id)self copy];
}

- mutableCopyWithZone: (void*)zone
{
	if (zone != NULL)
		@throw [OFNotImplementedException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	return [(id)self mutableCopy];
}

/*
 * Those are needed as the root class is the superclass of the root class's
 * metaclass and thus instance methods can be sent to class objects as well.
 */
+ (void*)allocMemoryWithSize: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

+ (void*)allocMemoryWithSize: (size_t)size
		       count: (size_t)count
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

+ (void*)resizeMemory: (void*)pointer
		 size: (size_t)size
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

+ (void*)resizeMemory: (void*)pointer
		 size: (size_t)size
		count: (size_t)count
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
