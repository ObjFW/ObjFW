/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#ifdef OF_APPLE_RUNTIME
# include <dlfcn.h>
#endif

#import "OFObject.h"
#import "OFArray.h"
#import "OFLocale.h"
#import "OFMethodSignature.h"
#import "OFRunLoop.h"
#import "OFThread.h"
#import "OFTimer.h"

#import "OFAllocFailedException.h"
#import "OFEnumerationMutationException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFMemoryNotPartOfObjectException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#if defined(OF_APPLE_RUNTIME) && __OBJC2__
# import <objc/objc-exception.h>
#elif defined(OF_OBJFW_RUNTIME)
# import "ObjFWRT.h"
#endif

#ifdef OF_WINDOWS
# include <windows.h>
#endif

#import "OFString.h"

#import "instance.h"
#if defined(OF_HAVE_ATOMIC_OPS)
# import "atomic.h"
#elif defined(OF_HAVE_THREADS)
# import "mutex.h"
#endif

#if defined(OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR)
extern id of_forward(id, SEL, ...);
extern struct stret of_forward_stret(id, SEL, ...);
#else
# define of_forward of_method_not_found
# define of_forward_stret of_method_not_found_stret
#endif

struct pre_ivar {
	int retainCount;
#if !defined(OF_HAVE_ATOMIC_OPS) && defined(OF_HAVE_THREADS)
	of_spinlock_t retainCountSpinlock;
#endif
	struct pre_mem *firstMem, *lastMem;
};

struct pre_mem {
	struct pre_mem *prev, *next;
	id owner;
};

#define PRE_IVARS_ALIGN ((sizeof(struct pre_ivar) + \
    (OF_BIGGEST_ALIGNMENT - 1)) & ~(OF_BIGGEST_ALIGNMENT - 1))
#define PRE_IVARS ((struct pre_ivar *)(void *)((char *)self - PRE_IVARS_ALIGN))

#define PRE_MEM_ALIGN ((sizeof(struct pre_mem) + \
    (OF_BIGGEST_ALIGNMENT - 1)) & ~(OF_BIGGEST_ALIGNMENT - 1))
#define PRE_MEM(mem) ((struct pre_mem *)(void *)((char *)mem - PRE_MEM_ALIGN))

static struct {
	Class isa;
} allocFailedException;

uint32_t of_hash_seed;

static const char *
typeEncodingForSelector(Class class, SEL selector)
{
#if defined(OF_OBJFW_RUNTIME)
	return class_getMethodTypeEncoding(class, selector);
#elif defined(OF_APPLE_RUNTIME)
	Method m;

	if ((m = class_getInstanceMethod(class, selector)) == NULL)
		return NULL;

	return method_getTypeEncoding(m);
#endif
}

#if !defined(OF_APPLE_RUNTIME) || defined(__OBJC2__)
static void
uncaughtExceptionHandler(id exception)
{
	OFString *description = [exception description];
	OFArray *backtrace = nil;
	of_string_encoding_t encoding = [OFLocale encoding];

	fprintf(stderr, "\nRuntime error: Unhandled exception:\n%s\n",
	    [description cStringWithEncoding: encoding]);

	if ([exception respondsToSelector: @selector(backtrace)])
		backtrace = [exception backtrace];

	if (backtrace != nil) {
		OFString *s = [backtrace componentsJoinedByString: @"\n  "];
		fprintf(stderr, "\nBacktrace:\n  %s\n\n",
		    [s cStringWithEncoding: encoding]);
	}

	abort();
}
#endif

static void
enumerationMutationHandler(id object)
{
	@throw [OFEnumerationMutationException exceptionWithObject: object];
}

void OF_NO_RETURN_FUNC
of_method_not_found(id object, SEL selector)
{
	[object doesNotRecognizeSelector: selector];

	/*
	 * Just in case doesNotRecognizeSelector: returned, even though it must
	 * never return.
	 */
	abort();

	OF_UNREACHABLE
}

void OF_NO_RETURN_FUNC
of_method_not_found_stret(void *stret, id object, SEL selector)
{
	of_method_not_found(object, selector);
}

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

	instance = calloc(1, PRE_IVARS_ALIGN + instanceSize +
	    extraAlignment + extraSize);

	if OF_UNLIKELY (instance == nil) {
		allocFailedException.isa = [OFAllocFailedException class];
		@throw (id)&allocFailedException;
	}

	((struct pre_ivar *)instance)->retainCount = 1;

#if !defined(OF_HAVE_ATOMIC_OPS) && defined(OF_HAVE_THREADS)
	if OF_UNLIKELY (!of_spinlock_new(
	    &((struct pre_ivar *)instance)->retainCountSpinlock)) {
		free(instance);
		@throw [OFInitializationFailedException
		    exceptionWithClass: class];
	}
#endif

	instance = (OFObject *)(void *)((char *)instance + PRE_IVARS_ALIGN);

	if (!objc_constructInstance(class, instance)) {
		free((char *)instance - PRE_IVARS_ALIGN);
		@throw [OFInitializationFailedException
		    exceptionWithClass: class];
	}

	if OF_UNLIKELY (extra != NULL)
		*extra = (char *)instance + instanceSize + extraAlignment;

	return instance;
}

const char *
_NSPrintForDebugger(id object)
{
	return [[object description] cStringWithEncoding: [OFLocale encoding]];
}

/* References for static linking */
void
_references_to_categories_of_OFObject(void)
{
	_OFObject_KeyValueCoding_reference = 1;
	_OFObject_Serialization_reference = 1;
}

@implementation OFObject
+ (void)load
{
#if !defined(OF_APPLE_RUNTIME) || defined(__OBJC2__)
	objc_setUncaughtExceptionHandler(uncaughtExceptionHandler);
#endif

#if defined(OF_APPLE_RUNTIME)
	/*
	 * If the NSFoundationVersionNumber symbol is defined, we are linked
	 * against Foundation. Since CoreFoundation sets its own forward
	 * handler on load, we should not set ours, as this will break
	 * Foundation.
	 *
	 * Unfortunately, there is no way to check if a forward handler has
	 * already been set, so this is the best we can do.
	 */
	if (dlsym(RTLD_DEFAULT, "NSFoundationVersionNumber") == NULL)
		objc_setForwardHandler((void *)&of_forward,
		    (void *)&of_forward_stret);
#else
	objc_setForwardHandler((IMP)&of_forward, (IMP)&of_forward_stret);
#endif

	objc_setEnumerationMutationHandler(enumerationMutationHandler);

	do {
		of_hash_seed = of_random();
	} while (of_hash_seed == 0);
}

+ (void)unload
{
}

+ (void)initialize
{
}

+ (instancetype)alloc
{
	return of_alloc_object(self, 0, 0, NULL);
}

+ (instancetype)new
{
	return [[self alloc] init];
}

+ (Class)class
{
	return self;
}

+ (OFString *)className
{
	return [OFString stringWithCString: class_getName(self)
				  encoding: OF_STRING_ENCODING_ASCII];
}

+ (bool)isSubclassOfClass: (Class)class
{
	for (Class iter = self; iter != Nil; iter = class_getSuperclass(iter))
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

+ (bool)conformsToProtocol: (Protocol *)protocol
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

+ (OFMethodSignature *)instanceMethodSignatureForSelector: (SEL)selector
{
	const char *typeEncoding = typeEncodingForSelector(self, selector);

	if (typeEncoding == NULL)
		return nil;

	return [OFMethodSignature signatureWithObjCTypes: typeEncoding];
}

+ (OFString *)description
{
	return [self className];
}

+ (IMP)replaceClassMethod: (SEL)selector
      withMethodFromClass: (Class)class
{
	IMP method = [class methodForSelector: selector];

	if (method == NULL)
		@throw [OFInvalidArgumentException exception];

	return class_replaceMethod(object_getClass(self), selector, method,
	    typeEncodingForSelector(object_getClass(class), selector));
}

+ (IMP)replaceInstanceMethod: (SEL)selector
	 withMethodFromClass: (Class)class
{
	IMP method = [class instanceMethodForSelector: selector];

	if (method == NULL)
		@throw [OFInvalidArgumentException exception];

	return class_replaceMethod(self, selector, method,
	    typeEncodingForSelector(class, selector));
}

+ (void)inheritMethodsFromClass: (Class)class
{
	Class superclass = [self superclass];

	if ([self isSubclassOfClass: class])
		return;

#if defined(OF_OBJFW_RUNTIME)
	for (struct objc_method_list *methodList =
	    object_getClass(class)->methodList;
	    methodList != NULL; methodList = methodList->next) {
		for (unsigned int i = 0; i < methodList->count; i++) {
			SEL selector = (SEL)&methodList->methods[i].selector;

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

	for (struct objc_method_list *methodList = class->methodList;
	    methodList != NULL; methodList = methodList->next) {
		for (unsigned int i = 0; i < methodList->count; i++) {
			SEL selector = (SEL)&methodList->methods[i].selector;

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
	unsigned int count;

	methodList = class_copyMethodList(object_getClass(class), &count);
	@try {
		for (unsigned int i = 0; i < count; i++) {
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
		for (unsigned int i = 0; i < count; i++) {
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

	[self inheritMethodsFromClass: superclass];
}

+ (bool)resolveClassMethod: (SEL)selector
{
	return NO;
}

+ (bool)resolveInstanceMethod: (SEL)selector
{
	return NO;
}

- (instancetype)init
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

- (OFString *)className
{
	return [OFString stringWithCString: object_getClassName(self)
				  encoding: OF_STRING_ENCODING_ASCII];
}

- (bool)isKindOfClass: (Class)class
{
	for (Class iter = object_getClass(self); iter != Nil;
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

- (bool)conformsToProtocol: (Protocol *)protocol
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
	id (*imp)(id, SEL) = (id (*)(id, SEL))objc_msg_lookup(self, selector);
#elif defined(OF_APPLE_RUNTIME)
	id (*imp)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
#endif

	return imp(self, selector);
}

- (id)performSelector: (SEL)selector
	   withObject: (id)object
{
#if defined(OF_OBJFW_RUNTIME)
	id (*imp)(id, SEL, id) =
	    (id (*)(id, SEL, id))objc_msg_lookup(self, selector);
#elif defined(OF_APPLE_RUNTIME)
	id (*imp)(id, SEL, id) = (id (*)(id, SEL, id))objc_msgSend;
#endif

	return imp(self, selector, object);
}

- (id)performSelector: (SEL)selector
	   withObject: (id)object1
	   withObject: (id)object2
{
#if defined(OF_OBJFW_RUNTIME)
	id (*imp)(id, SEL, id, id) =
	    (id (*)(id, SEL, id, id))objc_msg_lookup(self, selector);
#elif defined(OF_APPLE_RUNTIME)
	id (*imp)(id, SEL, id, id) = (id (*)(id, SEL, id, id))objc_msgSend;
#endif

	return imp(self, selector, object1, object2);
}

- (id)performSelector: (SEL)selector
	   withObject: (id)object1
	   withObject: (id)object2
	   withObject: (id)object3
{
#if defined(OF_OBJFW_RUNTIME)
	id (*imp)(id, SEL, id, id, id) =
	    (id (*)(id, SEL, id, id, id))objc_msg_lookup(self, selector);
#elif defined(OF_APPLE_RUNTIME)
	id (*imp)(id, SEL, id, id, id) =
	    (id (*)(id, SEL, id, id, id))objc_msgSend;
#endif

	return imp(self, selector, object1, object2, object3);
}

- (id)performSelector: (SEL)selector
	   withObject: (id)object1
	   withObject: (id)object2
	   withObject: (id)object3
	   withObject: (id)object4
{
#if defined(OF_OBJFW_RUNTIME)
	id (*imp)(id, SEL, id, id, id, id) =
	    (id (*)(id, SEL, id, id, id, id))objc_msg_lookup(self, selector);
#elif defined(OF_APPLE_RUNTIME)
	id (*imp)(id, SEL, id, id, id, id) =
	    (id (*)(id, SEL, id, id, id, id))objc_msgSend;
#endif

	return imp(self, selector, object1, object2, object3, object4);
}

- (void)performSelector: (SEL)selector
	     afterDelay: (of_time_interval_t)delay
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
	     afterDelay: (of_time_interval_t)delay
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
	     afterDelay: (of_time_interval_t)delay
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

- (void)performSelector: (SEL)selector
	     withObject: (id)object1
	     withObject: (id)object2
	     withObject: (id)object3
	     afterDelay: (of_time_interval_t)delay
{
	void *pool = objc_autoreleasePoolPush();

	[OFTimer scheduledTimerWithTimeInterval: delay
					 target: self
				       selector: selector
					 object: object1
					 object: object2
					 object: object3
					repeats: false];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	     withObject: (id)object1
	     withObject: (id)object2
	     withObject: (id)object3
	     withObject: (id)object4
	     afterDelay: (of_time_interval_t)delay
{
	void *pool = objc_autoreleasePoolPush();

	[OFTimer scheduledTimerWithTimeInterval: delay
					 target: self
				       selector: selector
					 object: object1
					 object: object2
					 object: object3
					 object: object4
					repeats: false];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_THREADS
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	  waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						repeats: false];
	[thread.runLoop addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (id)object
	  waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						 object: object
						repeats: false];
	[thread.runLoop addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
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
	[thread.runLoop addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (id)object1
	     withObject: (id)object2
	     withObject: (id)object3
	  waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						 object: object1
						 object: object2
						 object: object3
						repeats: false];
	[thread.runLoop addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (id)object1
	     withObject: (id)object2
	     withObject: (id)object3
	     withObject: (id)object4
	  waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						 object: object1
						 object: object2
						 object: object3
						 object: object4
						repeats: false];
	[thread.runLoop addTimer: timer];

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

- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (id)object1
			 withObject: (id)object2
			 withObject: (id)object3
		      waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						 object: object1
						 object: object2
						 object: object3
						repeats: false];
	[[OFRunLoop mainRunLoop] addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (id)object1
			 withObject: (id)object2
			 withObject: (id)object3
			 withObject: (id)object4
		      waitUntilDone: (bool)waitUntilDone
{
	void *pool = objc_autoreleasePoolPush();
	OFTimer *timer = [OFTimer timerWithTimeInterval: 0
						 target: self
					       selector: selector
						 object: object1
						 object: object2
						 object: object3
						 object: object4
						repeats: false];
	[[OFRunLoop mainRunLoop] addTimer: timer];

	if (waitUntilDone)
		[timer waitUntilDone];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     afterDelay: (of_time_interval_t)delay
{
	void *pool = objc_autoreleasePoolPush();

	[thread.runLoop addTimer: [OFTimer timerWithTimeInterval: delay
							  target: self
							selector: selector
							 repeats: false]];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (id)object
	     afterDelay: (of_time_interval_t)delay
{
	void *pool = objc_autoreleasePoolPush();

	[thread.runLoop addTimer: [OFTimer timerWithTimeInterval: delay
							  target: self
							selector: selector
							  object: object
							 repeats: false]];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (id)object1
	     withObject: (id)object2
	     afterDelay: (of_time_interval_t)delay
{
	void *pool = objc_autoreleasePoolPush();

	[thread.runLoop addTimer: [OFTimer timerWithTimeInterval: delay
							  target: self
							selector: selector
							  object: object1
							  object: object2
							 repeats: false]];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (id)object1
	     withObject: (id)object2
	     withObject: (id)object3
	     afterDelay: (of_time_interval_t)delay
{
	void *pool = objc_autoreleasePoolPush();

	[thread.runLoop addTimer: [OFTimer timerWithTimeInterval: delay
							  target: self
							selector: selector
							  object: object1
							  object: object2
							  object: object3
							 repeats: false]];

	objc_autoreleasePoolPop(pool);
}

- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (id)object1
	     withObject: (id)object2
	     withObject: (id)object3
	     withObject: (id)object4
	     afterDelay: (of_time_interval_t)delay
{
	void *pool = objc_autoreleasePoolPush();

	[thread.runLoop addTimer: [OFTimer timerWithTimeInterval: delay
							  target: self
							selector: selector
							  object: object1
							  object: object2
							  object: object3
							  object: object4
							 repeats: false]];

	objc_autoreleasePoolPop(pool);
}
#endif

- (OFMethodSignature *)methodSignatureForSelector: (SEL)selector
{
	const char *typeEncoding =
	    typeEncodingForSelector(object_getClass(self), selector);

	if (typeEncoding == NULL)
		return nil;

	return [OFMethodSignature signatureWithObjCTypes: typeEncoding];
}

- (bool)isEqual: (id)object
{
	return (object == self);
}

- (uint32_t)hash
{
	uintptr_t ptr = (uintptr_t)self;
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (size_t i = 0; i < sizeof(ptr); i++) {
		OF_HASH_ADD(hash, ptr & 0xFF);
		ptr >>= 8;
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)description
{
	/* Classes containing data should reimplement this! */

	return [OFString stringWithFormat: @"<%@>", self.className];
}

- (void *)allocMemoryWithSize: (size_t)size
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

	return (char *)pointer + PRE_MEM_ALIGN;
}

- (void *)allocMemoryWithSize: (size_t)size
			count: (size_t)count
{
	if OF_UNLIKELY (count > SIZE_MAX / size)
		@throw [OFOutOfRangeException exception];

	return [self allocMemoryWithSize: size * count];
}

- (void *)allocZeroedMemoryWithSize: (size_t)size
{
	void *pointer;
	struct pre_mem *preMem;

	if OF_UNLIKELY (size == 0)
		return NULL;

	if OF_UNLIKELY (size > SIZE_MAX - PRE_IVARS_ALIGN)
		@throw [OFOutOfRangeException exception];

	if OF_UNLIKELY ((pointer = calloc(1, PRE_MEM_ALIGN + size)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: size];

	preMem = pointer;
	preMem->owner = self;
	preMem->prev = PRE_IVARS->lastMem;

	if OF_LIKELY (PRE_IVARS->lastMem != NULL)
		PRE_IVARS->lastMem->next = preMem;

	if OF_UNLIKELY (PRE_IVARS->firstMem == NULL)
		PRE_IVARS->firstMem = preMem;

	PRE_IVARS->lastMem = preMem;

	return (char *)pointer + PRE_MEM_ALIGN;
}

- (void *)allocZeroedMemoryWithSize: (size_t)size
			      count: (size_t)count
{
	if OF_UNLIKELY (count > SIZE_MAX / size)
		@throw [OFOutOfRangeException exception];

	return [self allocZeroedMemoryWithSize: size * count];
}

- (void *)resizeMemory: (void *)pointer
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

	return (char *)new + PRE_MEM_ALIGN;
}

- (void *)resizeMemory: (void *)pointer
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

- (void)freeMemory: (void *)pointer
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

- (instancetype)retain
{
#if defined(OF_HAVE_ATOMIC_OPS)
	of_atomic_int_inc(&PRE_IVARS->retainCount);
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
	of_memory_barrier_release();

	if (of_atomic_int_dec(&PRE_IVARS->retainCount) <= 0) {
		of_memory_barrier_acquire();

		[self dealloc];
	}
#else
	size_t c;

	OF_ENSURE(of_spinlock_lock(&PRE_IVARS->retainCountSpinlock));
	c = --PRE_IVARS->retainCount;
	OF_ENSURE(of_spinlock_unlock(&PRE_IVARS->retainCountSpinlock));

	if (c == 0)
		[self dealloc];
#endif
}

- (instancetype)autorelease
{
	return _objc_rootAutorelease(self);
}

- (instancetype)self
{
	return self;
}

- (bool)isProxy
{
	return false;
}

- (bool)allowsWeakReference
{
	return true;
}

- (bool)retainWeakReference
{
	[self retain];

	return true;
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

	free((char *)self - PRE_IVARS_ALIGN);
}

/* Required to use properties with the Apple runtime */
- (id)copyWithZone: (void *)zone
{
	if OF_UNLIKELY (zone != NULL) {
		[self doesNotRecognizeSelector: _cmd];
		abort();
	}

	return [(id)self copy];
}

- (id)mutableCopyWithZone: (void *)zone
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
+ (void *)allocMemoryWithSize: (size_t)size
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (void *)allocMemoryWithSize: (size_t)size
		       count: (size_t)count
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (void *)resizeMemory: (void *)pointer
		  size: (size_t)size
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (void *)resizeMemory: (void *)pointer
		  size: (size_t)size
		 count: (size_t)count
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (void)freeMemory: (void *)pointer
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (id)retain
{
	return self;
}

+ (id)autorelease
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

+ (id)copy
{
	return self;
}

+ (id)mutableCopyWithZone: (void *)zone
{
	OF_UNRECOGNIZED_SELECTOR
}

/* Required to use ObjFW from Swift */
+ (instancetype)allocWithZone: (void *)zone
{
	if OF_UNLIKELY (zone != NULL) {
		[self doesNotRecognizeSelector: _cmd];
		abort();
	}

	return [self alloc];
}
@end
