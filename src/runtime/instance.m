/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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
# import <objc/objc.h>
#endif

#import "pre_ivar.h"

#ifdef OF_APPLE_RUNTIME
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
	_objc_zeroWeakReferences(object);
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
	instance = __mingw_aligned_malloc(_OBJC_PRE_IVARS_ALIGNED +
	    instanceSize + extraBytes, OF_BIGGEST_ALIGNMENT);
#elif defined(OF_DJGPP)
	instance = alignedAlloc(_OBJC_PRE_IVARS_ALIGNED +
	    instanceSize + extraBytes, OF_BIGGEST_ALIGNMENT, &offset);
#elif defined(OF_SOLARIS)
	if (posix_memalign((void **)&instance, OF_BIGGEST_ALIGNMENT,
	    _OBJC_PRE_IVARS_ALIGNED + instanceSize + extraBytes) != 0)
		instance = NULL;
#else
	instance = malloc(_OBJC_PRE_IVARS_ALIGNED + instanceSize + extraBytes);
#endif

	if OF_UNLIKELY (instance == nil)
		return nil;

#ifdef OF_DJGPP
	((struct objc_pre_ivars *)instance)->offset = offset;
#endif
	((struct objc_pre_ivars *)instance)->retainCount = 1;
	((struct objc_pre_ivars *)instance)->info = 0;

#if !defined(OF_HAVE_ATOMIC_OPS) && !defined(OF_AMIGAOS)
	if OF_UNLIKELY (OFSpinlockNew(
	    &((struct objc_pre_ivars *)instance)->retainCountSpinlock) != 0) {
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

	instance = (id)(void *)((char *)instance + _OBJC_PRE_IVARS_ALIGNED);
	memset(instance, 0, instanceSize + extraBytes);

	if (!objc_constructInstance(class, instance)) {
#if !defined(OF_HAVE_ATOMIC_OPS) && !defined(OF_AMIGAOS)
		OFSpinlockFree(&_OBJC_PRE_IVARS(instance)->retainCountSpinlock);
#endif
#if defined(OF_WINDOWS)
		__mingw_aligned_free(
		    (char *)instance - _OBJC_PRE_IVARS_ALIGNED);
#elif defined(OF_DJGPP)
		alignedFree((char *)instance - _OBJC_PRE_IVARS_ALIGNED, offset);
#else
		free((char *)instance - _OBJC_PRE_IVARS_ALIGNED);
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
	OFSpinlockFree(&_OBJC_PRE_IVARS(object)->retainCountSpinlock);
#endif

#if defined(OF_WINDOWS)
	__mingw_aligned_free((char *)object - _OBJC_PRE_IVARS_ALIGNED);
#elif defined(OF_DJGPP)
	alignedFree((char *)object - _OBJC_PRE_IVARS_ALIGNED,
	    _OBJC_PRE_IVARS(object)->offset);
#else
	free((char *)object - _OBJC_PRE_IVARS_ALIGNED);
#endif

	return nil;
}

id
_objc_rootRetain(id object)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	OFAtomicIntIncrease(&_OBJC_PRE_IVARS(object)->retainCount);
#elif defined(OF_AMIGAOS)
	/*
	 * On AmigaOS, we can only have one CPU. As increasing a variable is a
	 * single instruction on M68K, we don't need Forbid() / Permit() on
	 * M68K.
	 */
# ifndef OF_AMIGAOS_M68K
	Forbid();
# endif
	_OBJC_PRE_IVARS(object)->retainCount++;
# ifndef OF_AMIGAOS_M68K
	Permit();
# endif
#else
	if (OFSpinlockLock(&_OBJC_PRE_IVARS(object)->retainCountSpinlock) != 0)
		_OBJC_ERROR("Failed to lock spinlock!");

	_OBJC_PRE_IVARS->retainCount++;

	if (OFSpinlockUnlock(
	    &_OBJC_PRE_IVARS(object)->retainCountSpinlock) != 0)
		_OBJC_ERROR("Failed to unlock spinlock!");
#endif

	return object;
}

unsigned int
_objc_rootRetainCount(id object)
{
	return _OBJC_PRE_IVARS(object)->retainCount;
}

void
_objc_rootRelease(id object)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	OFReleaseMemoryBarrier();

	if (OFAtomicIntDecrease(&_OBJC_PRE_IVARS(object)->retainCount) <= 0) {
		OFAcquireMemoryBarrier();

		[object dealloc];
	}
#elif defined(OF_AMIGAOS)
	int retainCount;

	Forbid();
	retainCount = --_OBJC_PRE_IVARS(object)->retainCount;
	Permit();

	if (retainCount == 0)
		[object dealloc];
#else
	int retainCount;

	if (OFSpinlockLock(&_OBJC_PRE_IVARS(object)->retainCountSpinlock) != 0)
		_OBJC_ERROR("Failed to lock spinlock!");

	retainCount = --_OBJC_PRE_IVARS(object)->retainCount;

	if (OFSpinlockUnlock(
	    &_OBJC_PRE_IVARS(object)->retainCountSpinlock) != 0)
		_OBJC_ERROR("Failed to unlock spinlock!");

	if (retainCount == 0)
		[object dealloc];
#endif
}
