/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

/*
 * This file replaces NSAutoreleasePool with OFAutoreleasePool when it is
 * linked.
 * This is done so there is no conflict because OFBlocks are used (blocks are
 * OFBlocks as soon as ObjFW is linked). An application expecting an NSBlock,
 * but getting an OFBlock because ObjFW is linked, would fail to autorelease
 * the block otherwise, as the block would be in an OFAutoreleasePool. By
 * replacing NSAutoreleasePool with OFAutoreleasePool, the application will
 * still properly free the autoreleased block.
 * With autorelease pools now being part of the runtime, this is not really
 * necessary anymore, as both, ObjFW and Foundation, use the runtime's pools if
 * available. However, this is kept for compatibility with older versions of
 * OS X, which don't ship with a runtime with autorelease pools.
 */

#include "config.h"

#import <objc/runtime.h>

#import "OFAutoreleasePool.h"

static id
alloc(Class self, SEL _cmd)
{
	return [OFAutoreleasePool alloc];
}

static void
addObject(Class self, SEL _cmd, id obj)
{
	[OFAutoreleasePool addObject: obj];
}

static id
autorelease(id self, SEL _cmd)
{
	[OFAutoreleasePool addObject: self];

	return self;
}

static void __attribute__((constructor))
init(void)
{
	Class NSAutoreleasePool = objc_getClass("NSAutoreleasePool");
	Class NSObject = objc_getClass("NSObject");
	Method allocMethod;
	Method addObjectMethod;
	Method autoreleaseMethod;

	if (NSAutoreleasePool == Nil || NSObject == Nil)
		return;

	allocMethod = class_getClassMethod(NSAutoreleasePool,
	    @selector(alloc));
	addObjectMethod = class_getClassMethod(NSAutoreleasePool,
	    @selector(addObject:));
	autoreleaseMethod = class_getInstanceMethod(NSObject,
	    @selector(autorelease));

	if (allocMethod == NULL || addObjectMethod == NULL ||
	    autoreleaseMethod == NULL)
		return;

	class_replaceMethod(object_getClass(NSAutoreleasePool),
	    @selector(alloc), (IMP)alloc, method_getTypeEncoding(allocMethod));
	class_replaceMethod(object_getClass(NSAutoreleasePool),
	    @selector(addObject:), (IMP)addObject,
	    method_getTypeEncoding(addObjectMethod));
	class_replaceMethod(NSObject, @selector(autorelease),
	    (IMP)autorelease, method_getTypeEncoding(autoreleaseMethod));
}
