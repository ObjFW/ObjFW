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

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#import "OFBlock.h"
#ifdef OF_HAVE_ATOMIC_OPS
# import "OFAtomic.h"
#endif
#ifdef OF_HAVE_THREADS
# import "OFPlainMutex.h"
#endif
#import "OFString.h"

#import "OFAllocFailedException.h"
#import "OFInitializationFailedException.h"

#if defined(OF_OBJFW_RUNTIME)
# import "runtime/private.h"
#endif

struct Block {
	Class isa;
	int flags;
	int reserved;
	void (*invoke)(void *block, ...);
	struct {
		unsigned long reserved;
		unsigned long size;
		void (*copyHelper)(void *dest, void *src);
		void (*disposeHelper)(void *src);
		const char *signature;
	} *descriptor;
};

struct Byref {
	Class isa;
	struct Byref *forwarding;
	int flags;
	int size;
	void (*keepByref)(void *dest, void *src);
	void (*disposeByref)(void *);
};

enum {
	OFBlockHasCopyDispose = (1 << 25),
	OFBlockHasCtor	      = (1 << 26),
	OFBlockIsGlobal	      = (1 << 28),
	OFBlockHasStret	      = (1 << 29),
	OFBlockHasSignature   = (1 << 30)
};
#define OFBlockRefCountMask 0xFFFF

enum {
	OFBlockFieldIsObject =   3,
	OFBlockFieldIsBlock  =   7,
	OFBlockFieldIsByref  =   8,
	OFBlockFieldIsWeak   =  16,
	OFBlockByrefCaller   = 128
};

@protocol RetainRelease
- (instancetype)retain;
- (void)release;
@end

#ifdef OF_OBJFW_RUNTIME
/* Begin of ObjC module */
static struct objc_class _NSConcreteStackBlock_metaclass = {
	Nil, Nil, "OFStackBlock", 8, _OBJC_CLASS_INFO_METACLASS,
	sizeof(_NSConcreteStackBlock_metaclass), NULL, NULL
};

struct objc_class _NSConcreteStackBlock = {
	&_NSConcreteStackBlock_metaclass, (Class)(void *)"OFBlock",
	"OFStackBlock", 8, _OBJC_CLASS_INFO_CLASS, sizeof(struct Block),
	NULL, NULL
};

static struct objc_class _NSConcreteGlobalBlock_metaclass = {
	Nil, Nil, "OFGlobalBlock", 8, _OBJC_CLASS_INFO_METACLASS,
	sizeof(_NSConcreteGlobalBlock_metaclass), NULL, NULL
};

struct objc_class _NSConcreteGlobalBlock = {
	&_NSConcreteGlobalBlock_metaclass, (Class)(void *)"OFBlock",
	"OFGlobalBlock", 8, _OBJC_CLASS_INFO_CLASS, sizeof(struct Block),
	NULL, NULL
};

static struct objc_class _NSConcreteMallocBlock_metaclass = {
	Nil, Nil, "OFMallocBlock", 8, _OBJC_CLASS_INFO_METACLASS,
	sizeof(_NSConcreteMallocBlock_metaclass), NULL, NULL
};

struct objc_class _NSConcreteMallocBlock = {
	&_NSConcreteMallocBlock_metaclass, (Class)(void *)"OFBlock",
	"OFMallocBlock", 8, _OBJC_CLASS_INFO_CLASS, sizeof(struct Block),
	NULL, NULL
};

static struct {
	unsigned long unknown;
	struct objc_selector *selectorRefs;
	uint16_t classDefsCount, categoryDefsCount;
	void *defs[4];
} symtab = {
	0, NULL, 3, 0,
	{
		&_NSConcreteStackBlock, &_NSConcreteGlobalBlock,
		&_NSConcreteMallocBlock, NULL
	}
};

static struct objc_module module = {
	8, sizeof(module), NULL, (struct objc_symtab *)&symtab
};

OF_CONSTRUCTOR()
{
	__objc_exec_class(&module);
}
/* End of ObjC module */
#elif defined(OF_APPLE_RUNTIME)
extern Class objc_initializeClassPair(Class, const char *, Class, Class);

struct class {
	struct class *isa, *superclass;
	const char *name;
	long version, info, instanceSize;
	struct ivar_list *iVars;
	struct method_list **methodList;
	struct cache *cache;
	struct protocol_list *protocols;
	const char *iVarLayout;
	struct class_ext *ext;
};

struct class _NSConcreteStackBlock;
struct class _NSConcreteGlobalBlock;
struct class _NSConcreteMallocBlock;
# if defined(__OBJC2__) && !defined(OF_POWERPC64)
struct class _NSConcreteStackBlock_metaclass;
struct class _NSConcreteGlobalBlock_metaclass;
struct class _NSConcreteMallocBlock_metaclass;
# endif
#endif

static struct {
	Class isa;
} allocFailedException;

#ifndef OF_HAVE_ATOMIC_OPS
# define numSpinlocks 8	/* needs to be a power of 2 */
# define SPINLOCK_HASH(p) ((uintptr_t)p >> 4) & (numSpinlocks - 1)
static OFSpinlock blockSpinlocks[numSpinlocks];
static OFSpinlock byrefSpinlocks[numSpinlocks];
#endif

void *
_Block_copy(const void *block_)
{
	struct Block *block = (struct Block *)block_;

	if ([(id)block isMemberOfClass: (Class)&_NSConcreteStackBlock]) {
		struct Block *copy;

		if ((copy = malloc(block->descriptor->size)) == NULL) {
			object_setClass((id)&allocFailedException,
			    [OFAllocFailedException class]);
			@throw (OFAllocFailedException *)&allocFailedException;
		}
		memcpy(copy, block, block->descriptor->size);

		object_setClass((id)copy, (Class)&_NSConcreteMallocBlock);
		copy->flags++;

		if (block->flags & OFBlockHasCopyDispose)
			block->descriptor->copyHelper(copy, block);

		return copy;
	}

	if ([(id)block isMemberOfClass: (Class)&_NSConcreteMallocBlock]) {
#ifdef OF_HAVE_ATOMIC_OPS
		OFAtomicIntIncrease(&block->flags);
#else
		unsigned hash = SPINLOCK_HASH(block);

		OFEnsure(OFSpinlockLock(&blockSpinlocks[hash]) == 0);
		block->flags++;
		OFEnsure(OFSpinlockUnlock(&blockSpinlocks[hash]) == 0);
#endif
	}

	return block;
}

void
_Block_release(const void *block_)
{
	struct Block *block = (struct Block *)block_;

	if (object_getClass((id)block) != (Class)&_NSConcreteMallocBlock)
		return;

#ifdef OF_HAVE_ATOMIC_OPS
	if ((OFAtomicIntDecrease(&block->flags) & OFBlockRefCountMask) == 0) {
		if (block->flags & OFBlockHasCopyDispose)
			block->descriptor->disposeHelper(block);

		free(block);
	}
#else
	unsigned hash = SPINLOCK_HASH(block);

	OFEnsure(OFSpinlockLock(&blockSpinlocks[hash]) == 0);
	if ((--block->flags & OFBlockRefCountMask) == 0) {
		OFEnsure(OFSpinlockUnlock(&blockSpinlocks[hash]) == 0);

		if (block->flags & OFBlockHasCopyDispose)
			block->descriptor->disposeHelper(block);

		free(block);

		return;
	}
	OFEnsure(OFSpinlockUnlock(&blockSpinlocks[hash]) == 0);
#endif
}

void
_Block_object_assign(void *dst_, const void *src_, const int flags_)
{
	int flags = flags_ & (OFBlockFieldIsBlock | OFBlockFieldIsObject |
	    OFBlockFieldIsByref);

	if (src_ == NULL)
		return;

	switch (flags) {
	case OFBlockFieldIsBlock:
		*(struct Block **)dst_ = _Block_copy(src_);
		break;
	case OFBlockFieldIsObject:
		if (!(flags_ & OFBlockByrefCaller))
			*(id *)dst_ = objc_retain((id)src_);
		break;
	case OFBlockFieldIsByref:;
		struct Byref *src = (struct Byref *)src_;
		struct Byref **dst = (struct Byref **)dst_;

		src = src->forwarding;

		if ((src->flags & OFBlockRefCountMask) == 0) {
			if ((*dst = malloc(src->size)) == NULL) {
				object_setClass((id)&allocFailedException,
				    [OFAllocFailedException class]);
				@throw (OFAllocFailedException *)
				    &allocFailedException;
			}

			memcpy(*dst, src, src->size);
			(*dst)->flags =
			    ((*dst)->flags & ~OFBlockRefCountMask) | 1;
			(*dst)->forwarding = *dst;

			if (src->flags & OFBlockHasCopyDispose)
				src->keepByref(*dst, src);

#ifdef OF_HAVE_ATOMIC_OPS
			if (!OFAtomicPointerCompareAndSwap(
			    (void **)&src->forwarding, src, *dst)) {
				src->disposeByref(*dst);
				free(*dst);

				*dst = src->forwarding;
			}
#else
			unsigned hash = SPINLOCK_HASH(src);

			OFEnsure(OFSpinlockLock(&byrefSpinlocks[hash]) == 0);
			if (src->forwarding == src)
				src->forwarding = *dst;
			else {
				src->disposeByref(*dst);
				free(*dst);

				*dst = src->forwarding;
			}
			OFEnsure(OFSpinlockUnlock(&byrefSpinlocks[hash]) == 0);
#endif
		} else
			*dst = src;

#ifdef OF_HAVE_ATOMIC_OPS
		OFAtomicIntIncrease(&(*dst)->flags);
#else
		unsigned hash = SPINLOCK_HASH(*dst);

		OFEnsure(OFSpinlockLock(&byrefSpinlocks[hash]) == 0);
		(*dst)->flags++;
		OFEnsure(OFSpinlockUnlock(&byrefSpinlocks[hash]) == 0);
#endif
		break;
	}
}

void
_Block_object_dispose(const void *object_, const int flags_)
{
	const int flags = flags_ & (OFBlockFieldIsBlock | OFBlockFieldIsObject |
	    OFBlockFieldIsByref);

	if (object_ == NULL)
		return;

	switch (flags) {
	case OFBlockFieldIsBlock:
		_Block_release(object_);
		break;
	case OFBlockFieldIsObject:
		if (!(flags_ & OFBlockByrefCaller))
			objc_release((id)object_);
		break;
	case OFBlockFieldIsByref:;
		struct Byref *object = (struct Byref *)object_;

		object = object->forwarding;

#ifdef OF_HAVE_ATOMIC_OPS
		if ((OFAtomicIntDecrease(&object->flags) &
		    OFBlockRefCountMask) == 0) {
			if (object->flags & OFBlockHasCopyDispose)
				object->disposeByref(object);

			free(object);
		}
#else
		unsigned hash = SPINLOCK_HASH(object);

		OFEnsure(OFSpinlockLock(&byrefSpinlocks[hash]) == 0);
		if ((--object->flags & OFBlockRefCountMask) == 0) {
			OFEnsure(OFSpinlockUnlock(&byrefSpinlocks[hash]) == 0);

			if (object->flags & OFBlockHasCopyDispose)
				object->disposeByref(object);

			free(object);
		}
		OFEnsure(OFSpinlockUnlock(&byrefSpinlocks[hash]) == 0);
#endif
		break;
	}
}

@implementation OFBlock
+ (void)load
{
#ifndef OF_HAVE_ATOMIC_OPS
	for (size_t i = 0; i < numSpinlocks; i++)
		if (OFSpinlockNew(&blockSpinlocks[i]) != 0 ||
		    OFSpinlockNew(&byrefSpinlocks[i]) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self];
#endif

#ifdef OF_APPLE_RUNTIME
	Class tmp;

# if defined(__OBJC2__) && !defined(OF_POWERPC64)
	tmp = objc_initializeClassPair(self, "OFStackBlock",
	    (Class)&_NSConcreteStackBlock,
	    (Class)&_NSConcreteStackBlock_metaclass);
	if (tmp == Nil)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	objc_registerClassPair(tmp);

	tmp = objc_initializeClassPair(self, "OFGlobalBlock",
	    (Class)&_NSConcreteGlobalBlock,
	    (Class)&_NSConcreteGlobalBlock_metaclass);
	if (tmp == Nil)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	objc_registerClassPair(tmp);

	tmp = objc_initializeClassPair([OFBlock class], "OFMallocBlock",
	    (Class)&_NSConcreteMallocBlock,
	    (Class)&_NSConcreteMallocBlock_metaclass);
	if (tmp == Nil)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	objc_registerClassPair(tmp);
# else
	/*
	 * There is no objc_initializeClassPair in 10.5.
	 * However, objc_allocateClassPair does not register the new class with
	 * the subclass in the ObjC1 runtime like the ObjC2 runtime does, so
	 * this workaround should be fine.
	 */
	if ((tmp = objc_allocateClassPair(self, "OFStackBlock", 0)) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	memcpy(&_NSConcreteStackBlock, tmp, sizeof(_NSConcreteStackBlock));
	free(tmp);
	objc_registerClassPair((Class)&_NSConcreteStackBlock);

	if ((tmp = objc_allocateClassPair(self, "OFGlobalBlock", 0)) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	memcpy(&_NSConcreteGlobalBlock, tmp, sizeof(_NSConcreteGlobalBlock));
	free(tmp);
	objc_registerClassPair((Class)&_NSConcreteGlobalBlock);

	if ((tmp = objc_allocateClassPair(self, "OFMallocBlock", 0)) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	memcpy(&_NSConcreteMallocBlock, tmp, sizeof(_NSConcreteMallocBlock));
	free(tmp);
	objc_registerClassPair((Class)&_NSConcreteMallocBlock);
# endif
#endif
}

+ (instancetype)alloc
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)retain
{
	if ([self isMemberOfClass: (Class)&_NSConcreteMallocBlock])
		return Block_copy(self);

	return self;
}

- (id)copy
{
	return Block_copy(self);
}

- (instancetype)autorelease
{
	if ([self isMemberOfClass: (Class)&_NSConcreteMallocBlock])
		return [super autorelease];

	return self;
}

- (unsigned int)retainCount
{
	if ([self isMemberOfClass: (Class)&_NSConcreteMallocBlock])
		return ((struct Block *)self)->flags & OFBlockRefCountMask;

	return OFMaxRetainCount;
}

- (void)release
{
	if ([self isMemberOfClass: (Class)&_NSConcreteMallocBlock])
		Block_release(self);
}

- (void)dealloc
{
	OF_DEALLOC_UNSUPPORTED
}
@end
