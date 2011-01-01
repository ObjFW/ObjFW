/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFObject.h"

typedef struct of_block_literal_t {
	Class isa;
	int flags;
	int reserved;
	void (*invoke)(void *, ...);
	struct of_block_descriptor_t {
		unsigned long reserved;
		unsigned long size;
		void (*copy_helper)(void *dest, void *src);
		void (*dispose_helper)(void *src);
		const char *signature;
	} *descriptor;
} of_block_literal_t;

typedef struct of_block_byref_t of_block_byref_t;
struct of_block_byref_t {
	Class isa;
	of_block_byref_t *forwarding;
	int flags;
	int size;
	void (*byref_keep)(void *dest, void *src);
	void (*byref_dispose)(void*);
};

enum {
	OF_BLOCK_HAS_COPY_DISPOSE = (1 << 25),
	OF_BLOCK_HAS_CTOR	  = (1 << 26),
	OF_BLOCK_IS_GLOBAL	  = (1 << 28),
	OF_BLOCK_HAS_STRET	  = (1 << 29),
	OF_BLOCK_HAS_SIGNATURE	  = (1 << 30),
};
#define OF_BLOCK_REFCOUNT_MASK \
	~(OF_BLOCK_HAS_COPY_DISPOSE | OF_BLOCK_HAS_CTOR | OF_BLOCK_IS_GLOBAL | \
	OF_BLOCK_HAS_STRET | OF_BLOCK_HAS_SIGNATURE)

enum {
	OF_BLOCK_FIELD_IS_OBJECT =   3,
	OF_BLOCK_FIELD_IS_BLOCK	 =   7,
	OF_BLOCK_FIELD_IS_BYREF	 =   8,
	OF_BLOCK_FIELD_IS_WEAK	 =  16,
	OF_BLOCK_BYREF_CALLER	 = 128,
};

extern void* _Block_copy(const void*);
extern void _Block_release(const void*);

#ifndef Block_copy
# define Block_copy(x) ((__typeof__(x))_Block_copy((const void*)(x)))
#endif
#ifndef Block_release
# define Block_release(x) _Block_release((const void*)(x))
#endif

@interface OFBlock: OFObject
@end

@interface OFStackBlock: OFBlock
@end

@interface OFGlobalBlock: OFBlock
@end

@interface OFMallocBlock: OFBlock
@end
