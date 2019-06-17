/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#include "config.h"

#include <stdio.h>
#include <stdlib.h>

#import "ObjFWRT.h"
#import "private.h"
#import "macros.h"

static IMP forwardHandler = (IMP)0;
static IMP stretForwardHandler = (IMP)0;

static IMP
commonMethodNotFound(id object, SEL selector, IMP (*lookup)(id, SEL),
    IMP forward)
{
	/*
	 * object might be a dummy object (see class_getMethodImplementation),
	 * so don't access object directly unless it's a class!
	 */

	bool isClass =
	    object_getClass(object)->info & OBJC_CLASS_INFO_METACLASS;

	if (!(object_getClass(object)->info & OBJC_CLASS_INFO_INITIALIZED)) {
		Class class = (isClass
		    ? (Class)object : object_getClass(object));

		objc_initialize_class(class);

		if (!(class->info & OBJC_CLASS_INFO_SETUP))
			OBJC_ERROR("Could not dispatch message for incomplete "
			    "class %s!", class_getName(class));

		/*
		 * We don't need to handle the case that super was called.
		 * The reason for this is that a call to super is not possible
		 * before a message to the class has been sent and it thus has
		 * been initialized together with its superclasses.
		 */
		return lookup(object, selector);
	}

	/* Try resolveClassMethod: / resolveInstanceMethod: */
	if (class_isMetaClass(object_getClass(object))) {
		Class class = object_getClass(object);

		if (class_respondsToSelector(class,
		    @selector(resolveClassMethod:)) &&
		    [object resolveClassMethod: selector]) {
			if (!class_respondsToSelector(class, selector))
				OBJC_ERROR("+[%s resolveClassMethod: %s] "
				    "returned true without adding the method!",
				    class_getName(object),
				    sel_getName(selector));

			return lookup(object, selector);
		}
	} else {
		Class class = object_getClass(object);
		Class metaclass = object_getClass(class);

		if (class_respondsToSelector(metaclass,
		    @selector(resolveInstanceMethod:)) &&
		    [class resolveInstanceMethod: selector]) {
			if (!class_respondsToSelector(class, selector))
				OBJC_ERROR("+[%s resolveInstanceMethod: %s] "
				    "returned true without adding the method!",
				    class_getName(object_getClass(object)),
				    sel_getName(selector));

			return lookup(object, selector);
		}
	}

	if (forward != (IMP)0)
		return forward;

	OBJC_ERROR("Selector %c[%s] is not implemented for class %s!",
	    (isClass ? '+' : '-'), sel_getName(selector),
	    object_getClassName(object));
}

IMP
objc_method_not_found(id object, SEL selector)
{
	return commonMethodNotFound(object, selector, objc_msg_lookup,
	    forwardHandler);
}

IMP
objc_method_not_found_stret(id object, SEL selector)
{
	return commonMethodNotFound(object, selector, objc_msg_lookup_stret,
	    stretForwardHandler);
}

void
objc_setForwardHandler(IMP forward, IMP stretForward)
{
	forwardHandler = forward;
	stretForwardHandler = stretForward;
}

bool
class_respondsToSelector(Class class, SEL selector)
{
	if (class == Nil)
		return false;

	return (objc_dtable_get(class->DTable,
	    (uint32_t)selector->UID) != (IMP)0);
}

#ifndef OF_ASM_LOOKUP
static id
nilMethod(id self, SEL _cmd)
{
	return nil;
}

static OF_INLINE IMP
commonLookup(id object, SEL selector, IMP (*notFound)(id, SEL))
{
	IMP imp;

	if (object == nil)
		return (IMP)nilMethod;

	imp = objc_dtable_get(object_getClass(object)->DTable,
	    (uint32_t)selector->UID);

	if (imp == (IMP)0)
		return notFound(object, selector);

	return imp;
}

IMP
objc_msg_lookup(id object, SEL selector)
{
	return commonLookup(object, selector, objc_method_not_found);
}

IMP
objc_msg_lookup_stret(id object, SEL selector)
{
	return commonLookup(object, selector, objc_method_not_found_stret);
}

static OF_INLINE IMP
commonSuperLookup(struct objc_super *super, SEL selector,
    IMP (*notFound)(id, SEL))
{
	IMP imp;

	if (super->self == nil)
		return (IMP)nilMethod;

	imp = objc_dtable_get(super->class->DTable, (uint32_t)selector->UID);

	if (imp == (IMP)0)
		return notFound(super->self, selector);

	return imp;
}

IMP
objc_msg_lookup_super(struct objc_super *super, SEL selector)
{
	return commonSuperLookup(super, selector, objc_method_not_found);
}

IMP
objc_msg_lookup_super_stret(struct objc_super *super, SEL selector)
{
	return commonSuperLookup(super, selector, objc_method_not_found_stret);
}
#endif
