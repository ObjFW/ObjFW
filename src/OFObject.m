/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "unistd_wrapper.h"

#ifdef OF_APPLE_RUNTIME
# include <dlfcn.h>
#endif

#ifdef HAVE_GETRANDOM
# include <sys/random.h>
#endif

#import "OFObject.h"
#import "OFApplication.h"
#import "OFArray.h"
#import "OFLocale.h"
#import "OFMethodSignature.h"
#import "OFRunLoop.h"
#import "OFStdIOStream.h"
#import "OFString.h"
#import "OFThread.h"
#import "OFTimer.h"
#import "OFValue.h"

#import "OFAllocFailedException.h"
#import "OFEnumerationMutationException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
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
# define Class IntuitionClass
# define USE_INLINE_STDARG
# include <proto/exec.h>
# include <clib/debug_protos.h>
# define __NOLIBBASE_
# include <proto/intuition.h>
# undef __NOLIBBASE_
# undef Class
#endif

#ifdef OF_APPLE_RUNTIME
extern id _objc_rootRetain(id object);
extern uintptr_t _objc_rootRetainCount(id object);
extern void _objc_rootRelease(id object);
extern id _objc_rootAutorelease(id object);
#endif
#if defined(OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR)
extern id _OFForward(id, SEL, ...);
extern struct Stret _OFForward_stret(id, SEL, ...);
#else
# define _OFForward OFMethodNotFound
# define _OFForward_stret OFMethodNotFound_stret
#endif

#ifdef OF_WINDOWS
static BOOLEAN NTAPI (*RtlGenRandomFuncPtr)(PVOID, ULONG);
#endif

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
	if OF_UNLIKELY (count == 0 || size == 0) {
		free(pointer);
		return NULL;
	}

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

#if (!defined(HAVE_ARC4RANDOM) && !defined(HAVE_GETRANDOM)) || \
    defined(OF_WINDOWS)
static OFOnceControl randomOnceControl = OFOnceControlInitValue;

static void
initRandom(void)
{
	struct timeval tv;

# ifdef OF_WINDOWS
	HANDLE handle;

	if ((handle = GetModuleHandleA("advapi32.dll")) != NULL &&
	    (RtlGenRandomFuncPtr = (BOOLEAN NTAPI (*)(PVOID, ULONG))
	    GetProcAddress(handle, "SystemFunction036")) != NULL)
		return;
# endif

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
	OFOnce(&randomOnceControl, initRandom);

# ifdef OF_WINDOWS
	if (RtlGenRandomFuncPtr != NULL) {
		uint16_t buffer;
		OFEnsure(RtlGenRandomFuncPtr(&buffer, sizeof(buffer)));
		return buffer;
	}
# endif

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
# ifdef OF_WINDOWS
	OFOnce(&randomOnceControl, initRandom);

	if (RtlGenRandomFuncPtr != NULL) {
		uint32_t buffer;
		OFEnsure(RtlGenRandomFuncPtr(&buffer, sizeof(buffer)));
		return buffer;
	}
# endif

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
# ifdef OF_WINDOWS
	OFOnce(&randomOnceControl, initRandom);

	if (RtlGenRandomFuncPtr != NULL) {
		uint64_t buffer;
		OFEnsure(RtlGenRandomFuncPtr(&buffer, sizeof(buffer)));
		return buffer;
	}
# endif

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
# ifdef OF_AMIGAOS
#  ifdef OF_HAVE_FILES
	const char *programName = [OFApplication sharedApplication].programName
	    .lastPathComponent.UTF8String;
#  else
	const char *programName = [OFApplication sharedApplication].programName
	    .UTF8String;
#  endif
# endif
	OFArray OF_GENERIC(OFValue *) *stackTraceAddresses = nil;
	OFArray OF_GENERIC(OFString *) *stackTraceSymbols = nil;
	OFStringEncoding encoding = [OFLocale encoding];

# ifdef OF_AMIGAOS
	kprintf("%s: Runtime error: Unhandled exception:\n", programName);
	kprintf("%s: %s\n", programName, [[exception description] UTF8String]);
# else
	OFLog(@"Runtime error: Unhandled exception:");
	OFLog(@"%@", exception);
# endif

	if ([exception respondsToSelector: @selector(stackTraceAddresses)])
		stackTraceAddresses = [exception stackTraceAddresses];

	if (stackTraceAddresses != nil) {
		size_t count = stackTraceAddresses.count;

		if ([exception respondsToSelector:
		    @selector(stackTraceSymbols)])
			stackTraceSymbols = [exception stackTraceSymbols];

		if (stackTraceSymbols.count != count)
			stackTraceSymbols = nil;

# ifdef OF_AMIGAOS
		kprintf("%s:\n", programName);
		kprintf("%s: Stack trace:\n", programName);
# else
		OFLog(@"");
		OFLog(@"Stack trace:");
# endif

		if (stackTraceSymbols != nil) {
			for (size_t i = 0; i < count; i++) {
				void *address = [[stackTraceAddresses
				    objectAtIndex: i] pointerValue];
				const char *symbol = [[stackTraceSymbols
				    objectAtIndex: i]
				    cStringWithEncoding: encoding];

# ifdef OF_AMIGAOS
				kprintf("%s:   %p  %s\n", programName,
				    address, symbol);
# else
				OFLog(@"  %p  %s", address, symbol);
# endif
			}
		} else {
			for (size_t i = 0; i < count; i++) {
				void *address = [[stackTraceAddresses
				    objectAtIndex: i] pointerValue];

# ifdef OF_AMIGAOS
				kprintf("%s:   %p\n", programName, address);
# else
				OFLog(@"  %p", address);
# endif
			}
		}
	}

# ifdef OF_AMIGAOS
	struct Library *IntuitionBase;
#  ifdef OF_AMIGAOS4
	struct IntuitionIFace *IIntuition;
#  endif
	struct EasyStruct easy;

	if ((IntuitionBase = OpenLibrary("intuition.library", 0)) == NULL)
		abort();

#  ifdef OF_AMIGAOS4
	if ((IIntuition = (struct IntuitionIFace *)GetInterface(IntuitionBase,
	    "main", 1, NULL)) == NULL)
		abort();
#  endif

	easy.es_StructSize = sizeof(easy);
	easy.es_Flags = 0;
	easy.es_Title = (void *)programName;
	easy.es_TextFormat = (void *)"%s";
	easy.es_GadgetFormat = (void *)"OK";

	EasyRequest(NULL, &easy, NULL, (ULONG)[[OFString stringWithFormat:
	    @"Runtime error: Unhandled exception:\n%@", exception] UTF8String]);

#  ifdef OF_AMIGAOS4
	DropInterface((struct Interface *)IIntuition);
#  endif

	CloseLibrary(IntuitionBase);

	exit(1);
# else
	abort();
# endif
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
		extraAlignment = OFRoundUpToPowerOf2(extraAlignment,
		    instanceSize) - instanceSize;

	instance = class_createInstance(class, extraAlignment + extraSize);

	if OF_UNLIKELY (instance == nil) {
		object_setClass((id)&allocFailedException,
		    [OFAllocFailedException class]);
		@throw (id)&allocFailedException;
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
void OF_VISIBILITY_INTERNAL
_references_to_categories_of_OFObject(void)
{
	_OFObject_KeyValueCoding_reference = 1;
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
		objc_setForwardHandler((void *)&_OFForward,
		    (void *)&_OFForward_stret);
#else
	objc_setForwardHandler((IMP)&_OFForward, (IMP)&_OFForward_stret);
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
	return class_createInstance(self, 0);
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
	for (Class iter = self; iter != Nil; iter = class_getSuperclass(iter))
		if (class_conformsToProtocol(iter, protocol))
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
	return false;
}

+ (bool)resolveInstanceMethod: (SEL)selector
{
	return false;
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
		OFHashAddByte(&hash, ptr & 0xFF);
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

- (void)_usesRuntimeRR
{
}

- (instancetype)retain
{
	return _objc_rootRetain(self);
}

- (unsigned int)retainCount
{
	return (unsigned int)_objc_rootRetainCount(self);
}

- (void)release
{
	_objc_rootRelease(self);
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
	object_dispose(self);
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
