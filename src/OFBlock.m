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

#import "OFBlock.h"
#import "OFAutoreleasePool.h"

struct objc_abi_class {
	struct objc_abi_class *metaclass;
	const char *superclass, *name;
	unsigned long version, info, instance_size;
	void *ivars, *methodlist, *dtable, *subclass_list, *sibling_class;
	void *protocols, *gc_object_type;
	long abi_version;
	void *ivar_offsets, *properties;
};

enum objc_abi_class_info {
	OBJC_CLASS_INFO_CLASS	  = 0x01,
	OBJC_CLASS_INFO_METACLASS = 0x02
};

extern void __objc_exec_class(void*);

/* Begin of ObjC module */
static struct objc_abi_class _NSConcreteStackBlock_metaclass = {
	&_NSConcreteStackBlock_metaclass, "OFBlock", "_NSConcreteStackBlock", 8,
	OBJC_CLASS_INFO_METACLASS, sizeof(struct objc_class), NULL, NULL
};

struct objc_abi_class _NSConcreteStackBlock = {
	&_NSConcreteStackBlock_metaclass, "OFBlock", "_NSConcreteStackBlock", 8,
	OBJC_CLASS_INFO_CLASS, sizeof(of_block_literal_t), NULL, NULL
};

static struct objc_abi_class _NSConcreteGlobalBlock_metaclass = {
	&_NSConcreteGlobalBlock_metaclass, "OFBlock", "_NSConcreteGlobalBlock",
	8, OBJC_CLASS_INFO_METACLASS, sizeof(struct objc_class), NULL, NULL
};

struct objc_abi_class _NSConcreteGlobalBlock = {
	&_NSConcreteGlobalBlock_metaclass, "OFBlock", "_NSConcreteGlobalBlock",
	8, OBJC_CLASS_INFO_CLASS, sizeof(of_block_literal_t), NULL, NULL
};

static struct objc_abi_class _NSConcreteMallocBlock_metaclass = {
	&_NSConcreteMallocBlock_metaclass, "OFBlock", "_NSConcreteMallocBlock",
	8, OBJC_CLASS_INFO_METACLASS, sizeof(struct objc_class), NULL, NULL
};

struct objc_abi_class _NSConcreteMallocBlock = {
	&_NSConcreteMallocBlock_metaclass, "OFBlock", "_NSConcreteMallocBlock",
	8, OBJC_CLASS_INFO_CLASS, sizeof(of_block_literal_t), NULL, NULL
};

static struct {
	unsigned int unknown;
	struct objc_abi_selector *sel_refs;
	uint16_t cls_def_cnt, cat_def_cnt;
	void *defs[4];
} symtab = { 0, NULL, 3, 0, {
	&_NSConcreteStackBlock, &_NSConcreteGlobalBlock,
	&_NSConcreteMallocBlock, NULL
}};

static struct {
	unsigned long version, size;
	const char *name;
	void *symtab;
} module = { 8, sizeof(module), NULL, &symtab };

static void __attribute__((constructor))
__objc_gnu_init()
{
	__objc_exec_class(&module);
}
/* Emd of ObjC module */

of_block_literal_t*
Block_copy(of_block_literal_t *block)
{
	if (block->isa == (Class)&_NSConcreteStackBlock) {
		of_block_literal_t *copy;

		if ((copy = malloc(block->descriptor->size)) == NULL) {
			fputs("Not enough memory to copy block!\n", stderr);
			exit(1);
		}
		memcpy(copy, block, block->descriptor->size);

		copy->isa = (Class)&_NSConcreteMallocBlock;
		copy->reserved++;

		if (block->flags & OF_BLOCK_HAS_COPY_DISPOSE)
			block->descriptor->copy_helper(copy, block);

		return copy;
	}

	if (block->isa == (Class)&_NSConcreteMallocBlock)
		block->reserved++;

	return block;
}

void
Block_release(of_block_literal_t *block)
{
	if (block->isa != (Class)&_NSConcreteMallocBlock)
		return;

	if (--block->reserved == 0) {
		if (block->flags & OF_BLOCK_HAS_COPY_DISPOSE)
			block->descriptor->dispose_helper(block);

		free(block);
	}
}

void
_Block_object_assign(void *dst, void *src, int flags)
{
	flags &= OF_BLOCK_FIELD_IS_BLOCK | OF_BLOCK_FIELD_IS_OBJECT |
	    OF_BLOCK_FIELD_IS_BYREF;

	switch (flags) {
	case OF_BLOCK_FIELD_IS_BLOCK:
		*(of_block_literal_t**)dst = Block_copy(src);
		break;
	case OF_BLOCK_FIELD_IS_OBJECT:
		*(id*)dst = [(id)src retain];
		break;
	case OF_BLOCK_FIELD_IS_BYREF:;
		of_block_byref_t *src_ = src;
		of_block_byref_t **dst_ = dst;

		if ((src_->flags & ~OF_BLOCK_HAS_COPY_DISPOSE) == 0) {
			if ((*dst_ = malloc(src_->size)) == NULL) {
				fputs("Not enough memory for block "
				    "variables!\n", stderr);
				exit(1);
			}

			if (src_->forwarding == src)
				src_->forwarding = *dst_;

			memcpy(*dst_, src_, src_->size);

			if (src_->size >= sizeof(of_block_byref_t))
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
	flags &= OF_BLOCK_FIELD_IS_BLOCK | OF_BLOCK_FIELD_IS_OBJECT |
	    OF_BLOCK_FIELD_IS_BYREF;

	switch (flags) {
	case OF_BLOCK_FIELD_IS_BLOCK:
		Block_release(obj);
		break;
	case OF_BLOCK_FIELD_IS_OBJECT:
		[(id)obj release];
		break;
	case OF_BLOCK_FIELD_IS_BYREF:;
		of_block_byref_t *obj_ = obj;

		if ((--obj_->flags & ~OF_BLOCK_HAS_COPY_DISPOSE) == 0) {
			if (obj_->size >= sizeof(of_block_byref_t))
				obj_->byref_dispose(obj_);

			free(obj_);
		}
		break;
	}
}

static Class autoreleasepool = Nil;

@implementation OFBlock
- copy
{
	return (id)Block_copy((of_block_literal_t*)self);
}

- (void)release
{
	Block_release((of_block_literal_t*)self);
}

- autorelease
{
	/*
	 * Cache OFAutoreleasePool since class lookups are expensive with the
	 * GNU runtime.
	 */
	if (autoreleasepool == Nil)
		autoreleasepool = [OFAutoreleasePool class];

	[autoreleasepool addObject: self];

	return self;
}
@end
