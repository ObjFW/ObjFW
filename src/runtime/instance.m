/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include <stdbool.h>

#ifdef OF_OBJFW_RUNTIME
# import "ObjFWRT.h"
# import "private.h"
#else
# import <objc/runtime.h>
#endif

static SEL constructSelector = NULL;
static SEL destructSelector = NULL;

static bool
callConstructors(Class class, id object)
{
	Class super = class_getSuperclass(class);
	id (*construct)(id, SEL);
	id (*last)(id, SEL);

	if (super != nil)
		if (!callConstructors(super, object))
			return false;

	if (constructSelector == NULL)
		constructSelector = sel_registerName(".cxx_construct");

	if (!class_respondsToSelector(class, constructSelector))
		return true;

	construct = (id (*)(id, SEL))
	    class_getMethodImplementation(class, constructSelector);
	last = (id (*)(id, SEL))
	    class_getMethodImplementation(super, constructSelector);

	if (construct == last)
		return true;

	return (construct(object, constructSelector) != nil);
}

id
objc_constructInstance(Class class, void *bytes)
{
	id object = (id)bytes;

	if (class == Nil || bytes == NULL)
		return nil;

	object_setClass(object, class);

	if (!callConstructors(class, object))
		return nil;

	return object;
}

void *
objc_destructInstance(id object)
{
	Class class;
	void (*last)(id, SEL) = NULL;

	if (object == nil)
		return NULL;

#ifdef OF_OBJFW_RUNTIME
	objc_zeroWeakReferences(object);
#endif

	if (destructSelector == NULL)
		destructSelector = sel_registerName(".cxx_destruct");

	for (class = object_getClass(object); class != Nil;
	    class = class_getSuperclass(class)) {
		void (*destruct)(id, SEL);

		if (class_respondsToSelector(class, destructSelector)) {
			if ((destruct = (void (*)(id, SEL))
			    class_getMethodImplementation(class,
			    destructSelector)) != last)
				destruct(object, destructSelector);

			last = destruct;
		} else
			break;
	}

	objc_removeAssociatedObjects(object);

	return object;
}
