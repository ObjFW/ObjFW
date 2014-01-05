/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#include "config.h"

#include <stdio.h>
#include <stdlib.h>

#import "runtime.h"
#import "runtime-private.h"
#import "macros.h"

static void *forward_handler = NULL;
static void *forward_handler_stret = NULL;

static IMP
common_method_not_found(id obj, SEL sel, IMP (*lookup)(id, SEL), void *forward)
{
	/*
	 * obj might be a dummy object (see class_getMethodImplementation), so
	 * don't access obj directly unless it's a class!
	 */

	bool is_class = object_getClass(obj)->info & OBJC_CLASS_INFO_METACLASS;

	if (!(object_getClass(obj)->info & OBJC_CLASS_INFO_INITIALIZED)) {
		Class cls = (is_class ? (Class)obj : object_getClass(obj));

		objc_initialize_class(cls);

		if (!(cls->info & OBJC_CLASS_INFO_SETUP)) {
			if (is_class)
				return lookup(nil, sel);
			else
				OBJC_ERROR("Could not dispatch message for "
				    "incomplete class %s!", cls->name);
		}

		/*
		 * We don't need to handle the case that super was called.
		 * The reason for this is that a call to super is not possible
		 * before a message to the class has been sent and it thus has
		 * been initialized together with its superclasses.
		 */
		return lookup(obj, sel);
	}

	/* Try resolveClassMethod:/resolveInstanceMethod: */
	if (class_isMetaClass(object_getClass(obj))) {
		Class cls = object_getClass(obj);

		if (class_respondsToSelector(cls,
		    @selector(resolveClassMethod:)) &&
		    [obj resolveClassMethod: sel]) {
			if (!class_respondsToSelector(cls, sel))
				OBJC_ERROR("[%s resolveClassMethod: %s] "
				    "returned true without adding the method!",
				    class_getName(obj), sel_getName(sel));

			return lookup(obj, sel);
		}
	} else {
		Class cls = object_getClass(obj);
		Class metacls = object_getClass(cls);

		if (class_respondsToSelector(metacls,
		    @selector(resolveInstanceMethod:)) &&
		    [cls resolveInstanceMethod: sel]) {
			if (!class_respondsToSelector(cls, sel))
				OBJC_ERROR("[%s resolveInstanceMethod: %s] "
				    "returned true without adding the method!",
				    class_getName(object_getClass(obj)),
				    sel_getName(sel));

			return lookup(obj, sel);
		}
	}

	if (forward != NULL)
		return forward;

	OBJC_ERROR("Selector %c[%s] is not implemented for class %s!",
	    (is_class ? '+' : '-'), sel_getName(sel), object_getClassName(obj));
}

IMP
objc_method_not_found(id obj, SEL sel)
{
	return common_method_not_found(obj, sel, objc_msg_lookup,
	    forward_handler);
}

IMP
objc_method_not_found_stret(id obj, SEL sel)
{
	return common_method_not_found(obj, sel, objc_msg_lookup_stret,
	    forward_handler_stret);
}

void
objc_setForwardHandler(void *forward, void *forward_stret)
{
	forward_handler = forward;
	forward_handler_stret = forward_stret;
}

bool
class_respondsToSelector(Class cls, SEL sel)
{
	if (cls == Nil)
		return false;

	return (objc_sparsearray_get(cls->dtable, (uint32_t)sel->uid) != NULL);
}

#ifndef OF_ASM_LOOKUP
static id
nil_method(id self, SEL _cmd)
{
	return nil;
}

static OF_INLINE IMP
common_lookup(id obj, SEL sel, IMP (*not_found)(id, SEL))
{
	IMP imp;

	if (obj == nil)
		return (IMP)nil_method;

	imp = objc_sparsearray_get(object_getClass(obj)->dtable,
	    (uint32_t)sel->uid);

	if (imp == NULL)
		return not_found(obj, sel);

	return imp;
}

IMP
objc_msg_lookup(id obj, SEL sel)
{
	return common_lookup(obj, sel, objc_method_not_found);
}

IMP
objc_msg_lookup_stret(id obj, SEL sel)
{
	return common_lookup(obj, sel, objc_method_not_found_stret);
}

static OF_INLINE IMP
common_lookup_super(struct objc_super *super, SEL sel,
    IMP (*not_found)(id, SEL))
{
	IMP imp;

	if (super->self == nil)
		return (IMP)nil_method;

	imp = objc_sparsearray_get(super->cls->dtable, (uint32_t)sel->uid);

	if (imp == NULL)
		return not_found(super->self, sel);

	return imp;
}

IMP
objc_msg_lookup_super(struct objc_super *super, SEL sel)
{
	return common_lookup_super(super, sel, objc_method_not_found);
}

IMP
objc_msg_lookup_super_stret(struct objc_super *super, SEL sel)
{
	return common_lookup_super(super, sel, objc_method_not_found_stret);
}
#endif
