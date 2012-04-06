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

#include <stdio.h>
#include <stdlib.h>

#import "runtime.h"
#import "runtime-private.h"
#import "macros.h"

static IMP not_found_handler(id, SEL);
IMP (*objc_forward_handler)(id, SEL) = not_found_handler;

static IMP
not_found_handler(id obj, SEL sel)
{
	ERROR("Selector %s is not implemented for class %s!",
	    sel_getName(sel), obj->isa->name);
}

BOOL
class_respondsToSelector(Class cls, SEL sel)
{
	if (cls == Nil)
		return NO;

	return (objc_sparsearray_get(cls->dtable, sel->uid) != NULL ? YES : NO);
}

#if !defined(__ELF__) || (!defined(OF_X86_ASM) && !defined(OF_AMD64_ASM))
static id
nil_method(id self, SEL _cmd)
{
	return nil;
}

IMP
objc_msg_lookup(id obj, SEL sel)
{
	IMP imp;

	if (obj == nil)
		return (IMP)nil_method;

	if ((imp = objc_sparsearray_get(obj->isa->dtable, sel->uid)) == NULL)
		return objc_forward_handler(obj, sel);

	return imp;
}

IMP
objc_msg_lookup_super(struct objc_super *super, SEL sel)
{
	IMP imp;

	if (super->self == nil)
		return (IMP)nil_method;

	imp = objc_sparsearray_get(super->class->dtable, sel->uid);

	if (imp == NULL)
		return objc_forward_handler(super->self, sel);

	return imp;
}
#endif
