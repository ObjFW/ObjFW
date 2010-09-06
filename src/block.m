/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef OF_OBJFW_RUNTIME
# import <objfw-rt.h>
#else
# import <objc/objc.h>
# ifdef OF_APPLE_RUNTIME
#  import <objc/runtime.h>
# endif
#endif

@interface RetainRelease
- retain;
- (void)release;
@end

struct block_literal {
	void *isa;
	int flags;
	int reserved;
	void (*invoke)(void *, ...);
	struct block_descriptor {
		unsigned long reserved;
		unsigned long size;
		void (*copy_helper)(void *dest, void *src);
		void (*dispose_helper)(void *src);
		const char *signature;
	} *descriptor;
};

struct block_byref {
	void *isa;
	struct block_byref *forwarding;
	int flags;
	int size;
	void (*byref_keep)(void *dest, void *src);
	void (*byref_dispose)(void*);
};

enum {
	BLOCK_HAS_COPY_DISPOSE = (1 << 25),
	BLOCK_HAS_CTOR	       = (1 << 26),
	BLOCK_IS_GLOBAL	       = (1 << 28),
	BLOCK_HAS_STRET	       = (1 << 29),
	BLOCK_HAS_SIGNATURE    = (1 << 30),
};

enum {
	BLOCK_FIELD_IS_OBJECT =   3,
	BLOCK_FIELD_IS_BLOCK  =   7,
	BLOCK_FIELD_IS_BYREF  =   8,
	BLOCK_FIELD_IS_WEAK   =  16,
	BLOCK_BYREF_CALLER    = 128,
};

#ifndef __OBJC2__
struct objc_class _NSConcreteStackBlock;
struct objc_class _NSConcreteGlobalBlock;
struct objc_class _NSConcreteMallocBlock;
#endif

struct block_literal*
Block_copy(struct block_literal *block)
{
	if (block->isa == &_NSConcreteStackBlock) {
		struct block_literal *copy;

		if ((copy = malloc(block->descriptor->size)) == NULL) {
			fputs("Not enough memory to copy block!\n", stderr);
			exit(1);
		}
		memcpy(copy, block, block->descriptor->size);

		copy->isa = &_NSConcreteMallocBlock;
		copy->reserved++;

		if (block->flags & BLOCK_HAS_COPY_DISPOSE)
			block->descriptor->copy_helper(copy, block);

		return copy;
	}

	if (block->isa == &_NSConcreteMallocBlock)
		block->reserved++;

	return block;
}

void
Block_release(struct block_literal *block)
{
	if (block->isa != &_NSConcreteMallocBlock)
		return;

	if (--block->reserved == 0) {
		if (block->flags & BLOCK_HAS_COPY_DISPOSE)
			block->descriptor->dispose_helper(block);

		free(block);
	}
}

void
_Block_object_assign(void *dst, void *src, int flags)
{
	flags &= BLOCK_FIELD_IS_BLOCK | BLOCK_FIELD_IS_OBJECT |
	    BLOCK_FIELD_IS_BYREF;

	switch (flags) {
	case BLOCK_FIELD_IS_BLOCK:
		*(struct block_literal**)dst = Block_copy(src);
		break;
	case BLOCK_FIELD_IS_OBJECT:
		*(id*)dst = [(id)src retain];
		break;
	case BLOCK_FIELD_IS_BYREF:;
		struct block_byref *src_ = src;
		struct block_byref **dst_ = dst;

		if ((src_->flags & ~BLOCK_HAS_COPY_DISPOSE) == 0) {
			if ((*dst_ = malloc(src_->size)) == NULL) {
				fputs("Not enough memory for block "
				    "variables!\n", stderr);
				exit(1);
			}

			if (src_->forwarding == src)
				src_->forwarding = *dst_;

			memcpy(*dst_, src_, src_->size);

			if (src_->size >= sizeof(struct block_byref))
				src_->byref_keep(*dst_, src_);
		} else
			*dst_ = src_;

		(*dst_)->flags++;
		break;
	}
}

void
_Block_object_dispose(void *obj, int flags)
{
	flags &= BLOCK_FIELD_IS_BLOCK | BLOCK_FIELD_IS_OBJECT |
	    BLOCK_FIELD_IS_BYREF;

	switch (flags) {
	case BLOCK_FIELD_IS_BLOCK:
		Block_release(obj);
		break;
	case BLOCK_FIELD_IS_OBJECT:
		[(id)obj release];
		break;
	case BLOCK_FIELD_IS_BYREF:;
		struct block_byref *obj_ = obj;

		if ((--obj_->flags & ~BLOCK_HAS_COPY_DISPOSE) == 0) {
			if (obj_->size >= sizeof(struct block_byref))
				obj_->byref_dispose(obj_);

			free(obj_);
		}
		break;
	}
}
