/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import <objc/objc.h>

#import "OFExceptions.h"

id
objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, BOOL atomic)
{
	if (atomic) {
		@synchronized (self) {
			id ptr = *(id*)((char*)self + offset);
			return [[ptr retain] autorelease];
		}
	}

	return [[*(id*)((char*)self + offset) retain] autorelease];
}

void
objc_setProperty(id self, SEL _cmd, ptrdiff_t offset, id value, BOOL atomic,
    BOOL copy)
{
	if (atomic) {
		@synchronized ((atomic ? self : nil)) {
			id *ptr = (id*)((char*)self + offset);
			id old = *ptr;

			*ptr = (copy ? [value copy] : [value retain]);
			[old release];
		}
	}

	id *ptr = (id*)((char*)self + offset);
	id old = *ptr;

	*ptr = (copy ? [value copy] : [value retain]);
	[old release];
}
