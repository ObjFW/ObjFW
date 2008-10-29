/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import <objc/Object.h>

struct __ofobject_allocated_mem {
	void				*ptr;
	struct __ofobject_allocated_mem *prev;
	struct __ofobject_allocated_mem *next;
};

@interface OFObject: Object
{
	struct __ofobject_allocated_mem *__mem_pool;
}

- init;
- (void*)getMemWithSize: (size_t)size;
- (void*)getMemForNItems: (size_t)nitems
		withSize: (size_t)size;
- (void*)resizeMem: (void*)ptr
	    toSize: (size_t)size;
- (void*)resizeMem: (void*)ptr
	  toNItems: (size_t)nitems
	    ofSize: (size_t)size;
- freeMem: (void*)ptr;
- free;
@end
