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

/*
 * This file replaces NSAutoreleasePool with OFAutoreleasePool when it is
 * linked. This is done so there is no conflict because OFBlocks are used
 * (blocks are OFBlocks as soon as ObjFW is linked). An application expecting
 * an NSBlock, but getting an OFBlock because ObjFW is linked, would fail to
 * autorelease the block otherwise, as the block would be in an
 * OFAutoreleasePool. By replacing NSAutoreleasePool with OFAutoreleasePool,
 * the application will still properly free the autoreleased block.
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
init()
{
	Class NSAutoreleasePool = objc_getClass("NSAutoreleasePool");
	Class NSObject = objc_getClass("NSObject");
	Method alloc_method;
	Method addObject_method;
	Method autorelease_method;

	if (NSAutoreleasePool == Nil || NSObject == Nil)
		return;

	alloc_method = class_getClassMethod(NSAutoreleasePool,
	    @selector(alloc));
	addObject_method = class_getClassMethod(NSAutoreleasePool,
	    @selector(addObject:));
	autorelease_method = class_getInstanceMethod(NSObject,
	    @selector(autorelease));

	if (alloc_method == NULL || addObject_method == NULL ||
	    autorelease_method == NULL)
		return;

	class_replaceMethod(NSAutoreleasePool->isa, @selector(alloc),
	    (IMP)alloc, method_getTypeEncoding(alloc_method));
	class_replaceMethod(NSAutoreleasePool->isa, @selector(addObject:),
	    (IMP)addObject, method_getTypeEncoding(addObject_method));
	class_replaceMethod(NSObject, @selector(autorelease),
	    (IMP)autorelease, method_getTypeEncoding(autorelease_method));
}
