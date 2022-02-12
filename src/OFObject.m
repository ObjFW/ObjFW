/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
#include "unistd_wrapper.h"

#include <assert.h>

#ifdef OF_APPLE_RUNTIME
# include <dlfcn.h>
#endif

#ifdef HAVE_GETRANDOM
# include <sys/random.h>
#endif

#import "OFObject.h"
#import "OFArray.h"
#ifdef OF_HAVE_ATOMIC_OPS
# import "OFAtomic.h"
#endif
#import "OFLocale.h"
#import "OFMethodSignature.h"
#import "OFRunLoop.h"
#if !defined(OF_HAVE_ATOMIC_OPS) && defined(OF_HAVE_THREADS)
# import "OFPlainMutex.h"	/* For OFSpinlock */
#endif
#import "OFString.h"
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

#ifdef OF_AMIGAOS
# include <proto/exec.h>
#endif

#ifdef OF_APPLE_RUNTIME
extern id _Nullable _objc_rootAutorelease(id _Nullable object);
#endif
#if defined(OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR)
extern id OFForward(id, SEL, ...);
extern struct Stret OFForward_stret(id, SEL, ...);
#else
# define OFForward OFMethodNotFound
# define OFForward_stret OFMethodNotFound_stret
#endif

struct PreIvars {
	int retainCount;
#if !defined(OF_HAVE_ATOMIC_OPS) && !defined(OF_AMIGAOS)
	OFSpinlock retainCountSpinlock;
#endif
};

#define PRE_IVARS_ALIGN ((sizeof(struct PreIvars) + \
    (OF_BIGGEST_ALIGNMENT - 1)) & ~(OF_BIGGEST_ALIGNMENT - 1))
#define PRE_IVARS ((struct PreIvars *)(void *)((char *)self - PRE_IVARS_ALIGN))

static struct {
	Class isa;
} allocFailedException;

unsigned long OFHashSeed;

void *
OFAllocMemory(size_t count, size_t size)
{
	void *pointer;

	if OF_UNLIKELY (count == 0 || size == 0)
		return NULL;

	if OF_UNLIKELY (count > SIZE_MAX / size)
		@throw [OFOutOfRangeException exception];

	if OF_UNLIKELY ((pointer = malloc(count * size)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: size];

	return pointer;
}

void *
OFAllocZeroedMemory(size_t count, size_t size)
{
	void *pointer;

	if OF_UNLIKELY (count == 0 || size == 0)
		return NULL;

	/* Not all calloc implementations check for overflow. */
	if OF_UNLIKELY (count > SIZE_MAX / size)
		@throw [OFOutOfRangeException exception];

	if OF_UNLIKELY ((pointer = calloc(count, size)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: size];

	return pointer;
}

void *
OFResizeMemory(void *pointer, size_t count, size_t size)
{
	if OF_UNLIKELY (count == 0 || size == 0)
		return NULL;

	if OF_UNLIKELY (count > SIZE_MAX / size)
		@throw [OFOutOfRangeException exception];

	if OF_UNLIKELY ((pointer = realloc(pointer, count * size)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: size];

	return pointer;
}

void
OFFreeMemory(void *pointer)
{
	free(pointer);
}

#if !defined(HAVE_ARC4RANDOM) && !defined(HAVE_GETRANDOM)
static void
initRandom(void)
{
	struct timeval tv;

# ifdef HAVE_RANDOM
	gettimeofday(&tv, NULL);
	srandom((unsigned)(tv.tv_sec ^ tv.tv_usec));
# else
	gettimeofday(&tv, NULL);
	srand((unsigned)(tv.tv_sec ^ tv.tv_usec));
# endif
}
#endif

uint16_t
OFRandom16(void)
{
#if defined(HAVE_ARC4RANDOM)
	return arc4random();
#elif defined(HAVE_GETRANDOM)
	uint16_t buffer;

	OFEnsure(getrandom(&buffer, sizeof(buffer), 0) == sizeof(buffer));

	return buffer;
#else
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initRandom);
# ifdef HAVE_RANDOM
	return random() & 0xFFFF;
# else
	return rand() & 0xFFFF;
# endif
#endif
}

uint32_t
OFRandom32(void)
{
#if defined(HAVE_ARC4RANDOM)
	return arc4random();
#elif defined(HAVE_GETRANDOM)
	uint32_t buffer;

	OFEnsure(getrandom(&buffer, sizeof(buffer), 0) == sizeof(buffer));

	return buffer;
#else
	return ((uint32_t)OFRandom16() << 16) | OFRandom16();
#endif
}

uint64_t
OFRandom64(void)
{
#if defined(HAVE_ARC4RANDOM_BUF)
	uint64_t buffer;

	arc4random_buf(&buffer, sizeof(buffer));

	return buffer;
#elif defined(HAVE_GETRANDOM)
	uint64_t buffer;

	OFEnsure(getrandom(&buffer, sizeof(buffer), 0) == sizeof(buffer));

	return buffer;
#else
	return ((uint64_t)OFRandom32() << 32) | OFRandom32();
#endif
}

void
OFHashInit(unsigned long *hash)
{
	*hash = OFHashSeed;
}

static const char *
typeEncodingForSelector(Class class, SEL selector)
{
	Method method;

	if ((method = class_getInstanceMethod(class, selector)) == NULL)
		return NULL;

	return method_getTypeEncoding(method);
}

#if !defined(OF_APPLE_RUNTIME) || defined(__OBJC2__)
static void
uncaughtExceptionHandler(id exception)
{
	OFString *description = [exception description];
	OFArray *backtrace = nil;
	OFStringEncoding encoding = [OFLocale encoding];

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
OFMethodNotFound(id object, SEL selector)
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
OFMethodNotFound_stret(void *stret, id object, SEL selector)
{
	OFMethodNotFound(object, selector);
}

id
OFAllocObject(Class class, size_t extraSize, size_t extraAlignment,
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

	((struct PreIvars *)instance)->retainCount = 1;

#if !defined(OF_HAVE_ATOMIC_OPS) && !defined(OF_AMIGAOS)
	if OF_UNLIKELY (OFSpinlockNew(
	    &((struct PreIvars *)instance)->retainCountSpinlock) != 0) {
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
		objc_setForwardHandler((void *)&OFForward,
		    (void *)&OFForward_stret);
#else
	objc_setForwardHandler((IMP)&OFForward, (IMP)&OFForward_stret);
#endif

	objc_setEnumerationMutationHandler(enumerationMutationHandler);

	do {
		OFHashSeed = OFRandom32();
	} while (OFHashSeed == 0);

#ifdef OF_OBJFW_RUNTIME
	objc_setTaggedPointerSecret(sizeof(uintptr_t) == 4
	    ? (uintptr_t)OFRandom32() : (uintptr_t)OFRandom64());
#endif
}

+ (void)unload
{
}

+ (void)initialize
{
}

+ (instancetype)alloc
{
	return OFAllocObject(self, 0, 0, NULL);
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
				  encoding: OFStringEncodingASCII];
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

+ (IMP)replaceClassMethod: (SEL)selector withMethodFromClass: (Class)class
{
	IMP method = [class methodForSelector: selector];

	if (method == NULL)
		@throw [OFInvalidArgumentException exception];

	return class_replaceMethod(object_getClass(self), selector, method,
	    typeEncodingForSelector(object_getClass(class), selector));
}

+ (IMP)replaceInstanceMethod: (SEL)selector withMethodFromClass: (Class)class
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
	Method *methodList;
	unsigned int count;

	if ([self isSubclassOfClass: class])
		return;

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
				  encoding: OFStringEncodingASCII];
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

- (id)performSelector: (SEL)selector withObject: (id)object
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

- (void)performSelector: (SEL)selector afterDelay: (OFTimeInterval)delay
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
	     afterDelay: (OFTimeInterval)delay
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
	     afterDelay: (OFTimeInterval)delay
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
	     afterDelay: (OFTimeInterval)delay
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
	     afterDelay: (OFTimeInterval)delay
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
	     afterDelay: (OFTimeInterval)delay
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
	     afterDelay: (OFTimeInterval)delay
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
	     afterDelay: (OFTimeInterval)delay
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
	     afterDelay: (OFTimeInterval)delay
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
	     afterDelay: (OFTimeInterval)delay
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

- (unsigned long)hash
{
	uintptr_t ptr = (uintptr_t)self;
	unsigned long hash;

	OFHashInit(&hash);

	for (size_t i = 0; i < sizeof(ptr); i++) {
		OFHashAdd(&hash, ptr & 0xFF);
		ptr >>= 8;
	}

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	/* Classes containing data should reimplement this! */

	return [OFString stringWithFormat: @"<%@>", self.className];
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
	OFAtomicIntIncrease(&PRE_IVARS->retainCount);
#elif defined(OF_AMIGAOS)
	/*
	 * On AmigaOS, we can only have one CPU. As increasing a variable is a
	 * single instruction on M68K, we don't need Forbid() / Permit() on
	 * M68K.
	 */
# ifndef OF_AMIGAOS_M68K
	Forbid();
# endif
	PRE_IVARS->retainCount++;
# ifndef OF_AMIGAOS_M68K
	Permit();
# endif
#else
	OFEnsure(OFSpinlockLock(&PRE_IVARS->retainCountSpinlock) == 0);
	PRE_IVARS->retainCount++;
	OFEnsure(OFSpinlockUnlock(&PRE_IVARS->retainCountSpinlock) == 0);
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
	OFReleaseMemoryBarrier();

	if (OFAtomicIntDecrease(&PRE_IVARS->retainCount) <= 0) {
		OFAcquireMemoryBarrier();

		[self dealloc];
	}
#elif defined(OF_AMIGAOS)
	int retainCount;

	Forbid();
	retainCount = --PRE_IVARS->retainCount;
	Permit();

	if (retainCount == 0)
		[self dealloc];
#else
	int retainCount;

	OFEnsure(OFSpinlockLock(&PRE_IVARS->retainCountSpinlock) == 0);
	retainCount = --PRE_IVARS->retainCount;
	OFEnsure(OFSpinlockUnlock(&PRE_IVARS->retainCountSpinlock) == 0);

	if (retainCount == 0)
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
	objc_destructInstance(self);

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
 * The following are needed as the root class is the superclass of the root
 * class's metaclass and thus instance methods can be sent to class objects as
 * well.
 */

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
	return OFMaxRetainCount;
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
