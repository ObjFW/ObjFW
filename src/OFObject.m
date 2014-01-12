/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <assert.h>

#include <sys/time.h>

#import "OFObject.h"
#import "OFArray.h"
#import "OFTimer.h"
#import "OFRunLoop.h"
#import "OFThread.h"

#import "OFAllocFailedException.h"
#import "OFEnumerationMutationException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFMemoryNotPartOfObjectException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "autorelease.h"
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

#import "instance.h"
#if defined(OF_HAVE_ATOMIC_OPS)
# import "atomic.h"
#elif defined(OF_HAVE_THREADS)
# import "threading.h"
#endif

#if defined(OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR)
extern id of_forward(id, SEL, ...);
extern struct stret of_forward_stret(id, SEL, ...);
#else
# define of_forward of_method_not_found
# define of_forward_stret of_method_not_found_stret
#endif

struct pre_ivar {
	int32_t retainCount;
	struct pre_mem *firstMem, *lastMem;
#if !defined(OF_HAVE_ATOMIC_OPS) && defined(OF_HAVE_THREADS)
	of_spinlock_t retainCountSpinlock;
#endif
};

struct pre_mem {
	struct pre_mem *prev, *next;
	id owner;
};

#define PRE_IVARS_ALIGN ((sizeof(struct pre_ivar) + \
	(OF_BIGGEST_ALIGNMENT - 1)) & ~(OF_BIGGEST_ALIGNMENT - 1))
#define PRE_IVARS ((struct pre_ivar*)(void*)((char*)self - PRE_IVARS_ALIGN))

#define PRE_MEM_ALIGN ((sizeof(struct pre_mem) + \
	(OF_BIGGEST_ALIGNMENT - 1)) & ~(OF_BIGGEST_ALIGNMENT - 1))
#define PRE_MEM(mem) ((struct pre_mem*)(void*)((char*)mem - PRE_MEM_ALIGN))

static struct {
	Class isa;
} allocFailedException;

uint32_t of_hash_seed;

#if !defined(OF_APPLE_RUNTIME) || defined(__OBJC2__)
static void
uncaughtExceptionHandler(id exception)
{
	OFString *description = [exception description];
	OFArray *backtrace = nil;

	fprintf(stderr, "\nRuntime error: Unhandled exception:\n%s\n",
	    [description cStringWithEncoding: OF_STRING_ENCODING_NATIVE]);

	if ([exception respondsToSelector: @selector(backtrace)])
		backtrace = [exception backtrace];

	if (backtrace != nil) {
		OFString *s = [backtrace componentsJoinedByString: @"\n  "];
		fprintf(stderr, "\nBacktrace:\n  %s\n\n",
		      [s cStringWithEncoding: OF_STRING_ENCODING_NATIVE]);
	}

	abort();
}
#endif

static void
enumerationMutationHandler(id object)
{
	@throw [OFEnumerationMutationException exceptionWithObject: object];
}

void
of_method_not_found(id obj, SEL sel)
{
	[obj doesNotRecognizeSelector: sel];

	/*
	 * Just in case doesNotRecognizeSelector: returned, even though it must
	 * never return.
	 */
	abort();
}

void
of_method_not_found_stret(void *st, id obj, SEL sel)
{
	of_method_not_found(obj, sel);
}

#ifndef HAVE_OBJC_ENUMERATIONMUTATION
void
objc_enumerationMutation(id object)
{
	enumerationMutationHandler(object);
}
#endif

id
of_alloc_object(Class class, size_t extraSize, size_t extraAlignment,
    void **extra)
{
	OFObject *instance;
	size_t instanceSize;

	instanceSize = class_getInstanceSize(class);

	if OF_UNLIKELY (extraAlignment > 1)
		extraAlignment = ((instanceSize + extraAlignment - 1) &
		    ~(extraAlignment - 1)) - extraAlignment;

	instance = malloc(PRE_IVARS_ALIGN + instanceSize +
	    extraAlignment + extraSize);

	if OF_UNLIKELY (instance == nil) {
		allocFailedException.isa = [OFAllocFailedException class];
		@throw (id)&allocFailedException;
	}

	((struct pre_ivar*)instance)->retainCount = 1;
	((struct pre_ivar*)instance)->firstMem = NULL;
	((struct pre_ivar*)instance)->lastMem = NULL;

#if !defined(OF_HAVE_ATOMIC_OPS) && defined(OF_HAVE_THREADS)
	if OF_UNLIKELY (!of_spinlock_new(
	    &((struct pre_ivar*)instance)->retainCountSpinlock)) {
		free(instance);
		@throw [OFInitializationFailedException
		    exceptionWithClass: class];
	}
#endif

	instance = (OFObject*)((char*)instance + PRE_IVARS_ALIGN);

	memset(instance, 0, instanceSize);

	if (!objc_constructInstance(class, instance)) {
		free((char*)instance - PRE_IVARS_ALIGN);
		@throw [OFInitializationFailedException
		    exceptionWithClass: class];
	}

	if OF_UNLIKELY (extra != NULL)
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
#if !defined(OF_APPLE_RUNTIME) || defined(__OBJC2__)
	objc_setUncaughtExceptionHandler(uncaughtExceptionHandler);
#endif

	objc_setForwardHandler(of_forward, of_forward_stret);

#ifdef HAVE_OBJC_ENUMERATIONMUTATION
	objc_setEnumerationMutationHandler(enumerationMutationHandler);
#endif

#if defined(HAVE_ARC4RANDOM)
	of_hash_seed = arc4random();
#elif defined(HAVE_RANDOM)
	struct timeval t;
	gettimeofday(&t, NULL);
	srandom((unsigned)(t.tv_sec ^ t.tv_usec));
	of_hash_seed = (uint32_t)((random() << 16) | (random() & 0xFFFF));
#else
	struct timeval t;
	gettimeofday(&t, NULL);
	srand((unsigned)(t.tv_sec ^ t.tv_usec));
	of_hash_seed = (uint32_t)((rand() << 16) | (rand() & 0xFFFF));
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

+ (bool)isSubclassOfClass: (Class)class
{
	Class iter;

	for (iter = self; iter != Nil; iter = class_getSuperclass(iter))
		if (iter == class)
			return true;

	return false;
}

+ (Class)superclass
{
	return class_getSuperclass(self);
}

+ (bool)instancesRespondToSelector: (SEL)selector
{
	return class_respondsToSelector(self, selector);
}

+ (bool)conformsToProtocol: (Protocol*)protocol
{
	Class c;

	for (c = self; c != Nil; c = class_getSuperclass(c))
		if (class_conformsToProtocol(c, protocol))
			return true;

	return false;
}

+ (IMP)instanceMethodForSelector: (SEL)selector
{
	return class_getMethodImplementation(self, selector);
}

+ (const char*)typeEncodingForInstanceSelector: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	return class_getMethodTypeEncoding(self, selector);
#else
	Method m;

	if ((m = class_getInstanceMethod(self, selector)) == NULL)
		return NULL;

	return method_getTypeEncoding(m);
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

#if defined(OF_OBJFW_RUNTIME)
	struct objc_method_list *methodlist;

	for (methodlist = object_getClass(class)->methodlist;
	    methodlist != NULL; methodlist = methodlist->next) {
		int i;

		for (i = 0; i < methodlist->count; i++) {
			SEL selector = (SEL)&methodlist->methods[i].sel;

			/*
			 * Don't replace methods implemented in the receiving
			 * class.
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
			 * Don't replace methods implemented in the receiving
			 * class.
			 */
			if ([self instanceMethodForSelector: selector] !=
			    [superclass instanceMethodForSelector: selector])
				continue;

			[self replaceInstanceMethod: selector
				withMethodFromClass: class];
		}
	}
#elif defined(OF_APPLE_RUNTIME)
	Method *methodList;
	unsigned i, count;

	methodList = class_copyMethodList(object_getClass(class), &count);
	@try {
		for (i = 0; i < count; i++) {
			SEL selector = method_getName(methodList[i]);

			/*
			 * Don't replace methods implemented in the receiving
			 * class.
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
			 * Don't replace methods implemented in the receiving
			 * class.
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
#endif

	[self inheritMethodsFromClass: [class superclass]];
}

+ (bool)resolveClassMethod: (SEL)selector
{
	return false;
}

+ (bool)resolveInstanceMethod: (SEL)selector
{
	return false;
}

- init
{
	return self;
}

- (Class)class
{
	return object_getClass(self);
}

- (Class)superclass
{
	return class_getSuperclass(object_getClass(self));
}

- (OFString*)className
{
	return [OFString stringWithCString: object_getClassName(self)
				  encoding: OF_STRING_ENCODING_ASCII];
}

- (bool)isKindOfClass: (Class)class
{
	Class iter;

	for (iter = object_getClass(self); iter != Nil;
	    iter = class_getSuperclass(iter))
		if (iter == class)
			return true;

	return false;
}

- (bool)isMemberOfClass: (Class)class
{
	return (object_getClass(self) == class);
}

- (bool)respondsToSelector: (SEL)selector
{
	return class_respondsToSelector(object_getClass(self), selector);
}

- (bool)conformsToProtocol: (Protocol*)protocol
{
	return [object_getClass(self) conformsToProtocol: protocol];
}

- (IMP)methodForSelector: (SEL)selector
{
	return class_getMethodImplementation(object_getClass(self), selector);
}

- (id)performSelector: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	id (*imp)(id, SEL) = (id(*)(id, SEL))objc_msg_lookup(self, selector);

	return imp(self, selector);
#elif defined(OF_APPLE_RUNTIME)
	return objc_msgSend(self, selector);
#endif
}

- (id)performSelector: (SEL)selector
	   withObject: (id)object
{
#if defined(OF_OBJFW_RUNTIME)
	id (*imp)(id, SEL, id) =
	    (id(*)(id, SEL, id))objc_msg_lookup(self, selector);

	return imp(self, selector, object);
#elif defined(OF_APPLE_RUNTIME)
	return objc_msgSend(self, selector, object);
#endif
}

- (id)performSelector: (SEL)selector
	   withObject: (id)object1
	   withObject: (id)object2
{
#if defined(OF_OBJFW_RUNTIME)
	id (*imp)(id, SEL, id, id) =
	    (id(*)(id, SEL, id, id))objc_msg_lookup(self, selector);

	return imp(self, selector, object1, object2);
#elif defined(OF_APPLE_RUNTIME)
	return objc_msgSend(self, selector, object1, object2);
#endif
}

- (void)performSelector: (SEL)selector
	     afterDelay: (double)delay
{
	void *pool = objc_autoreleasePoolPush();

	[OFTimer scheduledTimerWithTimeInterval: delay
					 target: self
				       selector: selector
					repeats: false];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	     withObject: (id)object
	     afterDelay: (double)delay
{
	void *pool = objc_autoreleasePoolPush();

	[OFTimer scheduledTimerWithTimeInterval: delay
					 target: self
				       selector: selector
					 object: object
					repeats: false];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	     withObject: (id)object1
	     withObject: (id)object2
	     afterDelay: (double)delay
{
	void *pool = objc_autoreleasePoolPush();

	[OFTimer scheduledTimerWithTimeInterval: delay
					 target: self
				       selector: selector
					 object: object1
					 object: object2
					repeats: false];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_THREADS
- (void)performSelector: (SEL)selector
	       onThread: (OFThread*)thread
	  waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						repeats: false];
	[[thread runLoop] addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread*)thread
	     withObject: (id)object
	  waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						 object: object
						repeats: false];
	[[thread runLoop] addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread*)thread
	     withObject: (id)object1
	     withObject: (id)object2
	  waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						 object: object1
						 object: object2
						repeats: false];
	[[thread runLoop] addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelectorOnMainThread: (SEL)selector
		      waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						repeats: false];
	[[OFRunLoop mainRunLoop] addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (id)object
		      waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						 object: object
						repeats: false];
	[[OFRunLoop mainRunLoop] addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (id)object1
			 withObject: (id)object2
		      waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						 object: object1
						 object: object2
						repeats: false];
	[[OFRunLoop mainRunLoop] addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread*)thread
	     afterDelay: (double)delay
{
	void *pool = objc_autoreleasePoolPush();

	[[thread runLoop] addTimer: [OFTimer timerWithTimeInterval: delay
							    target: self
							  selector: selector
							   repeats: false]];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread*)thread
	     withObject: (id)object
	     afterDelay: (double)delay
{
	void *pool = objc_autoreleasePoolPush();

	[[thread runLoop] addTimer: [OFTimer timerWithTimeInterval: delay
							    target: self
							  selector: selector
							    object: object
							   repeats: false]];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread*)thread
	     withObject: (id)object1
	     withObject: (id)object2
	     afterDelay: (double)delay
{
	void *pool = objc_autoreleasePoolPush();

	[[thread runLoop] addTimer: [OFTimer timerWithTimeInterval: delay
							    target: self
							  selector: selector
							    object: object1
							    object: object2
							   repeats: false]];

	objc_autoreleasePoolPop(pool);
}
#endif

- (const char*)typeEncodingForSelector: (SEL)selector
{
#if defined(OF_OBJFW_RUNTIME)
	return class_getMethodTypeEncoding(object_getClass(self), selector);
#else
	Method m;

	if ((m = class_getInstanceMethod(object_getClass(self),
	    selector)) == NULL)
		return NULL;

	return method_getTypeEncoding(m);
#endif
}

- (bool)isEqual: (id)object
{
	return (self == object);
}

- (uint32_t)hash
{
	uintptr_t ptr = (uintptr_t)self;
	uint32_t hash;

	OF_HASH_INIT(hash);

	while (ptr != 0) {
		OF_HASH_ADD(hash, ptr & 0xFF);
		ptr <<= 8;
	}

	OF_HASH_FINALIZE(hash);

	return hash;
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

	if OF_UNLIKELY (size == 0)
		return NULL;

	if OF_UNLIKELY (size > SIZE_MAX - PRE_IVARS_ALIGN)
		@throw [OFOutOfRangeException exception];

	if OF_UNLIKELY ((pointer = malloc(PRE_MEM_ALIGN + size)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: size];
	preMem = pointer;

	preMem->owner = self;
	preMem->prev = PRE_IVARS->lastMem;
	preMem->next = NULL;

	if OF_LIKELY (PRE_IVARS->lastMem != NULL)
		PRE_IVARS->lastMem->next = preMem;

	if OF_UNLIKELY (PRE_IVARS->firstMem == NULL)
		PRE_IVARS->firstMem = preMem;
	PRE_IVARS->lastMem = preMem;

	return (char*)pointer + PRE_MEM_ALIGN;
}

- (void*)allocMemoryWithSize: (size_t)size
		       count: (size_t)count
{
	if OF_UNLIKELY (count > SIZE_MAX / size)
		@throw [OFOutOfRangeException exception];

	return [self allocMemoryWithSize: size * count];
}

- (void*)resizeMemory: (void*)pointer
		 size: (size_t)size
{
	void *new;
	struct pre_mem *preMem;

	if OF_UNLIKELY (pointer == NULL)
		return [self allocMemoryWithSize: size];

	if OF_UNLIKELY (size == 0) {
		[self freeMemory: pointer];
		return NULL;
	}

	if OF_UNLIKELY (PRE_MEM(pointer)->owner != self)
		@throw [OFMemoryNotPartOfObjectException
		    exceptionWithPointer: pointer
				  object: self];

	if OF_UNLIKELY ((new = realloc(PRE_MEM(pointer),
	    PRE_MEM_ALIGN + size)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: size];
	preMem = new;

	if OF_UNLIKELY (preMem != PRE_MEM(pointer)) {
		if OF_LIKELY (preMem->prev != NULL)
			preMem->prev->next = preMem;
		if OF_LIKELY (preMem->next != NULL)
			preMem->next->prev = preMem;

		if OF_UNLIKELY (PRE_IVARS->firstMem == PRE_MEM(pointer))
			PRE_IVARS->firstMem = preMem;
		if OF_UNLIKELY (PRE_IVARS->lastMem == PRE_MEM(pointer))
			PRE_IVARS->lastMem = preMem;
	}

	return (char*)new + PRE_MEM_ALIGN;
}

- (void*)resizeMemory: (void*)pointer
		 size: (size_t)size
		count: (size_t)count
{
	if OF_UNLIKELY (pointer == NULL)
		return [self allocMemoryWithSize: size
					   count: count];

	if OF_UNLIKELY (size == 0 || count == 0) {
		[self freeMemory: pointer];
		return NULL;
	}

	if OF_UNLIKELY (count > SIZE_MAX / size)
		@throw [OFOutOfRangeException exception];

	return [self resizeMemory: pointer
			     size: size * count];
}

- (void)freeMemory: (void*)pointer
{
	if OF_UNLIKELY (pointer == NULL)
		return;

	if OF_UNLIKELY (PRE_MEM(pointer)->owner != self)
		@throw [OFMemoryNotPartOfObjectException
		    exceptionWithPointer: pointer
				  object: self];

	if OF_LIKELY (PRE_MEM(pointer)->prev != NULL)
		PRE_MEM(pointer)->prev->next = PRE_MEM(pointer)->next;
	if OF_LIKELY (PRE_MEM(pointer)->next != NULL)
		PRE_MEM(pointer)->next->prev = PRE_MEM(pointer)->prev;

	if OF_UNLIKELY (PRE_IVARS->firstMem == PRE_MEM(pointer))
		PRE_IVARS->firstMem = PRE_MEM(pointer)->next;
	if OF_UNLIKELY (PRE_IVARS->lastMem == PRE_MEM(pointer))
		PRE_IVARS->lastMem = PRE_MEM(pointer)->prev;

	/* To detect double-free */
	PRE_MEM(pointer)->owner = nil;

	free(PRE_MEM(pointer));
}

- (id)forwardingTargetForSelector: (SEL)selector
{
	return nil;
}

- (void)doesNotRecognizeSelector: (SEL)selector
{
	@throw [OFNotImplementedException exceptionWithSelector: selector
							 object: self];
}

- retain
{
#if defined(OF_HAVE_ATOMIC_OPS)
	of_atomic_inc_32(&PRE_IVARS->retainCount);
#else
	OF_ENSURE(of_spinlock_lock(&PRE_IVARS->retainCountSpinlock));
	PRE_IVARS->retainCount++;
	OF_ENSURE(of_spinlock_unlock(&PRE_IVARS->retainCountSpinlock));
#endif

	return self;
}

- (unsigned int)retainCount
{
	assert(PRE_IVARS->retainCount >= 0);
	return PRE_IVARS->retainCount;
}

- (void)release
{
#if defined(OF_HAVE_ATOMIC_OPS)
	if (of_atomic_dec_32(&PRE_IVARS->retainCount) <= 0)
		[self dealloc];
#else
	size_t c;

	OF_ENSURE(of_spinlock_lock(&PRE_IVARS->retainCountSpinlock));
	c = --PRE_IVARS->retainCount;
	OF_ENSURE(of_spinlock_unlock(&PRE_IVARS->retainCountSpinlock));

	if (c == 0)
		[self dealloc];
#endif
}

- autorelease
{
	return _objc_rootAutorelease(self);
}

- self
{
	return self;
}

- (bool)isProxy
{
	return false;
}

- (void)dealloc
{
	struct pre_mem *iter;

	objc_destructInstance(self);

	iter = PRE_IVARS->firstMem;
	while (iter != NULL) {
		struct pre_mem *next = iter->next;

		/*
		 * We can use owner as a sentinel to prevent exploitation in
		 * case there is a buffer underflow somewhere.
		 */
		OF_ENSURE(iter->owner == self);

		free(iter);

		iter = next;
	}

	free((char*)self - PRE_IVARS_ALIGN);
}

/* Required to use properties with the Apple runtime */
- copyWithZone: (void*)zone
{
	if OF_UNLIKELY (zone != NULL) {
		[self doesNotRecognizeSelector: _cmd];
		abort();
	}

	return [(id)self copy];
}

- mutableCopyWithZone: (void*)zone
{
	if OF_UNLIKELY (zone != NULL) {
		[self doesNotRecognizeSelector: _cmd];
		abort();
	}

	return [(id)self mutableCopy];
}

/*
 * Those are needed as the root class is the superclass of the root class's
 * metaclass and thus instance methods can be sent to class objects as well.
 */
+ (void*)allocMemoryWithSize: (size_t)size
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (void*)allocMemoryWithSize: (size_t)size
		       count: (size_t)count
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (void*)resizeMemory: (void*)pointer
		 size: (size_t)size
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (void*)resizeMemory: (void*)pointer
		 size: (size_t)size
		count: (size_t)count
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (void)freeMemory: (void*)pointer
{
	OF_UNRECOGNIZED_SELECTOR
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
	OF_UNRECOGNIZED_SELECTOR
}

+ copy
{
	return self;
}

+ mutableCopyWithZone: (void*)zone
{
	OF_UNRECOGNIZED_SELECTOR
}
@end
