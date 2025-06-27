/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
	    object_getClass(object)->info & _OBJC_CLASS_INFO_METACLASS;

	if (!(object_getClass(object)->info & _OBJC_CLASS_INFO_INITIALIZED)) {
		Class class = (isClass
		    ? (Class)object : object_getClass(object));

		_objc_initializeClass(class);

		if (!(class->info & _OBJC_CLASS_INFO_SETUP))
			_OBJC_ERROR("Could not dispatch message %s for "
			    "incomplete class %s!",
			    sel_getName(selector), class_getName(class));

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
				_OBJC_ERROR("+[%s resolveClassMethod: %s] "
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
				_OBJC_ERROR("+[%s resolveInstanceMethod: %s] "
				    "returned true without adding the method!",
				    class_getName(object_getClass(object)),
				    sel_getName(selector));

			return lookup(object, selector);
		}
	}

	if (forward != (IMP)0)
		return forward;

	_OBJC_ERROR("Selector %c[%s] is not implemented for class %s!",
	    (isClass ? '+' : '-'), sel_getName(selector),
	    object_getClassName(object));
}

IMP
_objc_methodNotFound(id object, SEL selector)
{
	return commonMethodNotFound(object, selector, objc_msg_lookup,
	    forwardHandler);
}

IMP
_objc_methodNotFound_stret(id object, SEL selector)
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

	return (_objc_dtable_get(class->dTable,
	    (uint32_t)selector->UID) != (IMP)0);
}

#ifndef OF_ASM_LOOKUP
static id
nilMethod(id self, SEL _cmd)
{
	return nil;
}

static OF_INLINE IMP
# if __has_attribute(__hot__) || OF_GCC_VERSION >= 403
__attribute__((__hot__))
# endif
commonLookup(id object, SEL selector, IMP (*notFound)(id, SEL))
{
	IMP imp;

	if (object == nil)
		return (IMP)nilMethod;

	imp = _objc_dtable_get(object_getClass(object)->dTable,
	    (uint32_t)selector->UID);

	if (imp == (IMP)0)
		return notFound(object, selector);

	return imp;
}

IMP
objc_msg_lookup(id object, SEL selector)
{
	return commonLookup(object, selector, _objc_methodNotFound);
}

IMP
objc_msg_lookup_stret(id object, SEL selector)
{
	return commonLookup(object, selector, _objc_methodNotFound_stret);
}

static OF_INLINE IMP
commonSuperLookup(struct objc_super *super, SEL selector,
    IMP (*notFound)(id, SEL))
{
	IMP imp;

	if (super->self == nil)
		return (IMP)nilMethod;

	imp = _objc_dtable_get(super->class->dTable, (uint32_t)selector->UID);

	if (imp == (IMP)0)
		return notFound(super->self, selector);

	return imp;
}

IMP
objc_msg_lookup_super(struct objc_super *super, SEL selector)
{
	return commonSuperLookup(super, selector, _objc_methodNotFound);
}

IMP
objc_msg_lookup_super_stret(struct objc_super *super, SEL selector)
{
	return commonSuperLookup(super, selector, _objc_methodNotFound_stret);
}
#endif
