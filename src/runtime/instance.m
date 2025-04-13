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

#include <stdbool.h>

#ifdef OF_OBJFW_RUNTIME
# import "ObjFWRT.h"
# import "private.h"
#else
# ifdef OF_MACOS
#  import <objc/objc-runtime.h>
# else
#  import <objc/runtime.h>
# endif

@interface DummyObject
- (void)dealloc;
@end
#endif

#ifdef OF_HAVE_ATOMIC_OPS
# import "OFAtomic.h"
#endif
#if !defined(OF_HAVE_ATOMIC_OPS) && defined(OF_HAVE_THREADS)
# import "OFPlainMutex.h"	/* For OFSpinlock */
#endif

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# include <proto/exec.h>
# undef Class
#endif

struct PreIvars {
#ifdef OF_MSDOS
	ptrdiff_t offset;
#endif
	int retainCount;
#if !defined(OF_HAVE_ATOMIC_OPS) && !defined(OF_AMIGAOS)
	OFSpinlock retainCountSpinlock;
#endif
};

#define PRE_IVARS_ALIGNED \
	OFRoundUpToPowerOf2(sizeof(struct PreIvars), OF_BIGGEST_ALIGNMENT)
#define PRE_IVARS(obj) \
	((struct PreIvars *)(void *)((char *)obj - PRE_IVARS_ALIGNED))

#ifndef OF_OBJFW_RUNTIME
extern void objc_removeAssociatedObjects(id object);
#endif

#ifdef OF_DJGPP
/* Unfortunately, DJGPP's memalign() is broken. */

static void *
alignedAlloc(size_t size, size_t alignment, ptrdiff_t *offset)
{
	char *ptr, *aligned;

	if ((ptr = malloc(size + alignment)) == NULL)
		return NULL;

	aligned = (char *)OFRoundUpToPowerOf2(alignment, (uintptr_t)ptr);
	*offset = aligned - ptr;

	return aligned;
}

static void
alignedFree(void *ptr, ptrdiff_t offset)
{
	if (ptr == NULL)
		return;

	free((void *)((uintptr_t)ptr - offset));
}
#endif

static SEL constructSelector = NULL;
static SEL destructSelector = NULL;

static bool
callConstructors(Class class, id object)
{
	Class super = class_getSuperclass(class);
	id (*construct)(id, SEL);
	id (*last)(id, SEL);

	if (super != nil)
		if (!callConstructors(super, object))
			return false;

	if (constructSelector == NULL)
		constructSelector = sel_registerName(".cxx_construct");

	if (!class_respondsToSelector(class, constructSelector))
		return true;

	construct = (id (*)(id, SEL))
	    class_getMethodImplementation(class, constructSelector);
	last = (id (*)(id, SEL))
	    class_getMethodImplementation(super, constructSelector);

	if (construct == last)
		return true;

	return (construct(object, constructSelector) != nil);
}

id
objc_constructInstance(Class class, void *bytes)
{
	id object = (id)bytes;

	if (class == Nil || bytes == NULL)
		return nil;

	object_setClass(object, class);

	if (!callConstructors(class, object))
		return nil;

	return object;
}

void *
objc_destructInstance(id object)
{
	Class class;
	void (*last)(id, SEL) = NULL;

	if (object == nil)
		return NULL;

#ifdef OF_OBJFW_RUNTIME
	objc_zeroWeakReferences(object);
#endif

	if (destructSelector == NULL)
		destructSelector = sel_registerName(".cxx_destruct");

	for (class = object_getClass(object); class != Nil;
	    class = class_getSuperclass(class)) {
		void (*destruct)(id, SEL);

		if (class_respondsToSelector(class, destructSelector)) {
			if ((destruct = (void (*)(id, SEL))
			    class_getMethodImplementation(class,
			    destructSelector)) != last)
				destruct(object, destructSelector);

			last = destruct;
		} else
			break;
	}

	objc_removeAssociatedObjects(object);

	return object;
}

id
class_createInstance(Class class, size_t extraBytes)
{
	id instance;
	size_t instanceSize;
#ifdef OF_DJGPP
	ptrdiff_t offset;
#endif

	if (class == Nil)
		return nil;

	instanceSize = class_getInstanceSize(class);

#if defined(OF_WINDOWS)
	instance = __mingw_aligned_malloc(PRE_IVARS_ALIGNED + instanceSize +
	    extraBytes, OF_BIGGEST_ALIGNMENT);
#elif defined(OF_DJGPP)
	instance = alignedAlloc(PRE_IVARS_ALIGNED + instanceSize + extraBytes,
	    OF_BIGGEST_ALIGNMENT, &offset);
#elif defined(OF_SOLARIS)
	if (posix_memalign((void **)&instance, OF_BIGGEST_ALIGNMENT,
	    PRE_IVARS_ALIGNED + instanceSize + extraBytes) != 0)
		instance = NULL;
#else
	instance = malloc(PRE_IVARS_ALIGNED + instanceSize + extraBytes);
#endif

	if OF_UNLIKELY (instance == nil)
		return nil;

#ifdef OF_DJGPP
	((struct PreIvars *)instance)->offset = offset;
#endif
	((struct PreIvars *)instance)->retainCount = 1;

#if !defined(OF_HAVE_ATOMIC_OPS) && !defined(OF_AMIGAOS)
	if OF_UNLIKELY (OFSpinlockNew(
	    &((struct PreIvars *)instance)->retainCountSpinlock) != 0) {
# if defined(OF_WINDOWS)
		__mingw_alaigned_free(instance);
# elif defined(OF_DJGPP)
		alignedFree(instance, offset);
# else
		free(instance);
# endif
		return nil;
	}
#endif

	instance = (id)(void *)((char *)instance + PRE_IVARS_ALIGNED);
	memset(instance, 0, instanceSize + extraBytes);

	if (!objc_constructInstance(class, instance)) {
#if !defined(OF_HAVE_ATOMIC_OPS) && !defined(OF_AMIGAOS)
		OFSpinlockFree(&PRE_IVARS(instance)->retainCountSpinlock);
#endif
#if defined(OF_WINDOWS)
		__mingw_aligned_free((char *)instance - PRE_IVARS_ALIGNED);
#elif defined(OF_DJGPP)
		alignedFree((char *)instance - PRE_IVARS_ALIGNED, offset);
#else
		free((char *)instance - PRE_IVARS_ALIGNED);
#endif
		return nil;
	}

	return instance;
}

id
object_dispose(id object)
{
	objc_destructInstance(object);

#if !defined(OF_HAVE_ATOMIC_OPS) && !defined(OF_AMIGAOS)
	OFSpinlockFree(&PRE_IVARS(object)->retainCountSpinlock);
#endif

#if defined(OF_WINDOWS)
	__mingw_aligned_free((char *)object - PRE_IVARS_ALIGNED);
#elif defined(OF_DJGPP)
	alignedFree((char *)object - PRE_IVARS_ALIGNED,
	    PRE_IVARS(object)->offset);
#else
	free((char *)object - PRE_IVARS_ALIGNED);
#endif

	return nil;
}

id
_objc_rootRetain(id object)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	OFAtomicIntIncrease(&PRE_IVARS(object)->retainCount);
#elif defined(OF_AMIGAOS)
	/*
	 * On AmigaOS, we can only have one CPU. As increasing a variable is a
	 * single instruction on M68K, we don't need Forbid() / Permit() on
	 * M68K.
	 */
# ifndef OF_AMIGAOS_M68K
	Forbid();
# endif
	PRE_IVARS(object)->retainCount++;
# ifndef OF_AMIGAOS_M68K
	Permit();
# endif
#else
	if (OFSpinlockLock(&PRE_IVARS(object)->retainCountSpinlock) != 0)
		OBJC_ERROR("Failed to lock spinlock!");

	PRE_IVARS->retainCount++;

	if (OFSpinlockUnlock(&PRE_IVARS(object)->retainCountSpinlock) != 0)
		OBJC_ERROR("Failed to unlock spinlock!");
#endif

	return object;
}

unsigned int
_objc_rootRetainCount(id object)
{
	return PRE_IVARS(object)->retainCount;
}

void
_objc_rootRelease(id object)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	OFReleaseMemoryBarrier();

	if (OFAtomicIntDecrease(&PRE_IVARS(object)->retainCount) <= 0) {
		OFAcquireMemoryBarrier();

		[object dealloc];
	}
#elif defined(OF_AMIGAOS)
	int retainCount;

	Forbid();
	retainCount = --PRE_IVARS(object)->retainCount;
	Permit();

	if (retainCount == 0)
		[object dealloc];
#else
	int retainCount;

	if (OFSpinlockLock(&PRE_IVARS(object)->retainCountSpinlock) != 0)
		OBJC_ERROR("Failed to lock spinlock!");

	retainCount = --PRE_IVARS(object)->retainCount;

	if (OFSpinlockUnlock(&PRE_IVARS(object)->retainCountSpinlock) != 0)
		OBJC_ERROR("Failed to unlock spinlock!");

	if (retainCount == 0)
		[object dealloc];
#endif
}
