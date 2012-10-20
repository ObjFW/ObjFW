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

#include "config.h"

#import "OFObject.h"

static SEL cxx_construct = NULL;
static SEL cxx_destruct = NULL;

static BOOL
call_ctors(Class cls, id obj)
{
	Class super = class_getSuperclass(cls);
	id (*ctor)(id, SEL);
	id (*last)(id, SEL);

	if (super != nil)
		if (!call_ctors(super, obj))
			return NO;

	if (cxx_construct == NULL)
		cxx_construct = sel_registerName(".cxx_construct");

	if (!class_respondsToSelector(cls, cxx_construct))
		return YES;

	ctor = (id(*)(id, SEL))
	    class_getMethodImplementation(cls, cxx_construct);
	last = (id(*)(id, SEL))
	    class_getMethodImplementation(super, cxx_construct);

	if (ctor == last)
		return YES;

	return (ctor(obj, cxx_construct) != nil ? YES : NO);
}

id
objc_constructInstance(Class cls, void *bytes)
{
	id obj = (id)bytes;

	if (cls == Nil || bytes == NULL)
		return nil;

	object_setClass(obj, cls);

	if (!call_ctors(cls, obj))
		return nil;

	return obj;
}

void*
objc_destructInstance(id obj)
{
	Class cls;
	void (*last)(id, SEL) = NULL;

	if (cxx_destruct == NULL)
		cxx_destruct = sel_registerName(".cxx_destruct");

	for (cls = object_getClass(obj); cls != Nil;
	    cls = class_getSuperclass(cls)) {
		void (*dtor)(id, SEL);

		if (class_respondsToSelector(cls, cxx_destruct)) {
			if ((dtor = (void(*)(id, SEL))
			    class_getMethodImplementation(cls,
			    cxx_destruct)) != last)
				dtor(obj, cxx_destruct);

			last = dtor;
		} else
			break;
	}

	return obj;
}
