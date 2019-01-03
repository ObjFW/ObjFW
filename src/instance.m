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

#import "OFObject.h"

static SEL constructSel = NULL;
static SEL destructSel = NULL;

static bool
callConstructors(Class cls, id obj)
{
	Class super = class_getSuperclass(cls);
	id (*construct)(id, SEL);
	id (*last)(id, SEL);

	if (super != nil)
		if (!callConstructors(super, obj))
			return false;

	if (constructSel == NULL)
		constructSel = sel_registerName(".cxx_construct");

	if (!class_respondsToSelector(cls, constructSel))
		return true;

	construct = (id (*)(id, SEL))
	    class_getMethodImplementation(cls, constructSel);
	last = (id (*)(id, SEL))
	    class_getMethodImplementation(super, constructSel);

	if (construct == last)
		return true;

	return (construct(obj, constructSel) != nil);
}

id
objc_constructInstance(Class cls, void *bytes)
{
	id obj = (id)bytes;

	if (cls == Nil || bytes == NULL)
		return nil;

	object_setClass(obj, cls);

	if (!callConstructors(cls, obj))
		return nil;

	return obj;
}

void *
objc_destructInstance(id obj)
{
	Class cls;
	void (*last)(id, SEL) = NULL;

	if (obj == nil)
		return NULL;

#ifdef OF_OBJFW_RUNTIME
	objc_zero_weak_references(obj);
#endif

	if (destructSel == NULL)
		destructSel = sel_registerName(".cxx_destruct");

	for (cls = object_getClass(obj); cls != Nil;
	    cls = class_getSuperclass(cls)) {
		void (*destruct)(id, SEL);

		if (class_respondsToSelector(cls, destructSel)) {
			if ((destruct = (void (*)(id, SEL))
			    class_getMethodImplementation(cls,
			    destructSel)) != last)
				destruct(obj, destructSel);

			last = destruct;
		} else
			break;
	}

	return obj;
}
