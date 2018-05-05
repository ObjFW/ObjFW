/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "ObjFW_RT.h"
#import "private.h"
#import "macros.h"

void
glue___objc_exec_class(void *module OBJC_M68K_REG("a0"))
{
	__objc_exec_class(module);
}

IMP
glue_objc_msg_lookup(id obj OBJC_M68K_REG("a0"), SEL sel OBJC_M68K_REG("a1"))
{
	return objc_msg_lookup(obj, sel);
}

IMP
glue_objc_msg_lookup_stret(id obj OBJC_M68K_REG("a0"),
    SEL sel OBJC_M68K_REG("a1"))
{
	return objc_msg_lookup_stret(obj, sel);
}

IMP
glue_objc_msg_lookup_super(struct objc_super *super OBJC_M68K_REG("a0"),
    SEL sel OBJC_M68K_REG("a1"))
{
	return objc_msg_lookup_super(super, sel);
}

IMP
glue_objc_msg_lookup_super_stret(struct objc_super *super OBJC_M68K_REG("a0"),
    SEL sel OBJC_M68K_REG("a1"))
{
	return objc_msg_lookup_super_stret(super, sel);
}

Class
glue_objc_lookUpClass(const char *name OBJC_M68K_REG("a0"))
{
	return objc_lookUpClass(name);
}

Class
glue_objc_getClass(const char *name OBJC_M68K_REG("a0"))
{
	return objc_getClass(name);
}

Class
glue_objc_getRequiredClass(const char *name OBJC_M68K_REG("a0"))
{
	return objc_getRequiredClass(name);
}

Class
glue_objc_lookup_class(const char *name OBJC_M68K_REG("a0"))
{
	return objc_lookup_class(name);
}

Class
glue_objc_get_class(const char *name OBJC_M68K_REG("a0"))
{
	return objc_get_class(name);
}

void
glue_objc_exception_throw(id object OBJC_M68K_REG("a0"))
{
	objc_exception_throw(object);

	OF_UNREACHABLE
}

int
glue_objc_sync_enter(id object OBJC_M68K_REG("a0"))
{
	return objc_sync_enter(object);
}

int
glue_objc_sync_exit(id object OBJC_M68K_REG("a0"))
{
	return objc_sync_exit(object);
}

id
glue_objc_getProperty(id self OBJC_M68K_REG("a0"), SEL _cmd OBJC_M68K_REG("a1"),
    ptrdiff_t offset OBJC_M68K_REG("d0"), bool atomic OBJC_M68K_REG("d1"))
{
	return objc_getProperty(self, _cmd, offset, atomic);
}

void
glue_objc_setProperty(id self OBJC_M68K_REG("a0"), SEL _cmd OBJC_M68K_REG("a1"),
    ptrdiff_t offset OBJC_M68K_REG("d0"), id value OBJC_M68K_REG("a2"),
    bool atomic OBJC_M68K_REG("d1"), signed char copy OBJC_M68K_REG("d2"))
{
	objc_setProperty(self, _cmd, offset, value, atomic, copy);
}

void
glue_objc_getPropertyStruct(void *dest OBJC_M68K_REG("a0"),
    const void *src OBJC_M68K_REG("a1"), ptrdiff_t size OBJC_M68K_REG("d0"),
    bool atomic OBJC_M68K_REG("d1"), bool strong OBJC_M68K_REG("d2"))
{
	objc_getPropertyStruct(dest, src, size, atomic, strong);
}

void
glue_objc_setPropertyStruct(void *dest OBJC_M68K_REG("a0"),
    const void *src OBJC_M68K_REG("a1"), ptrdiff_t size OBJC_M68K_REG("d0"),
    bool atomic OBJC_M68K_REG("d1"), bool strong OBJC_M68K_REG("d2"))
{
	objc_setPropertyStruct(dest, src, size, atomic, strong);
}

void
glue_objc_enumerationMutation(id obj OBJC_M68K_REG("a0"))
{
	objc_enumerationMutation(obj);
}

int
glue___gnu_objc_personality_v0(int version OBJC_M68K_REG("d0"),
    int actions OBJC_M68K_REG("d1"), uint64_t *ex_class OBJC_M68K_REG("d2"),
    void *ex OBJC_M68K_REG("a0"), void *ctx OBJC_M68K_REG("a1"))
{
	return __gnu_objc_personality_v0(version, actions, *ex_class, ex, ctx);
}
