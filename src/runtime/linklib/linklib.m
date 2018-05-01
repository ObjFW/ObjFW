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

#include <proto/exec.h>
#include <stdio.h>
#include <stdlib.h>

struct Library *ObjFWRTBase;

static void __attribute__((__constructor__))
init(void)
{
	static bool initialized = false;
	static struct objc_libc libc;

	if (initialized)
		return;

	if ((ObjFWRTBase = OpenLibrary("objfw_rt.library", 0)) == NULL) {
		fputs("Failed to open objfw_rt.library!\n", stderr);
		abort();
	}

	libc = (struct objc_libc){
		.malloc = malloc,
		.calloc = calloc,
		.realloc = realloc,
		.free = free,
		.vfprintf = vfprintf,
		.fputs = fputs,
		.exit = exit,
		.abort = abort,
		.stdout_ = stdout,
		.stderr_ = stderr
	};
	objc_init(&libc);

	initialized = true;
}

OF_DESTRUCTOR()
{
	CloseLibrary(ObjFWRTBase);
}

void
__objc_exec_class(void *module)
{
	/*
	 * The compiler generates constructors that call into this, so it is
	 * possible that we are not set up yet when we get called.
	 */
	init();

	glue___objc_exec_class(module);
}

IMP
objc_msg_lookup(id obj, SEL sel)
{
	return glue_objc_msg_lookup(obj, sel);
}

IMP
objc_msg_lookup_stret(id obj, SEL sel)
{
	return glue_objc_msg_lookup_stret(obj, sel);
}

IMP
objc_msg_lookup_super(struct objc_super *super, SEL sel)
{
	return glue_objc_msg_lookup_super(super, sel);
}

IMP
objc_msg_lookup_super_stret(struct objc_super *super, SEL sel)
{
	return glue_objc_msg_lookup_super_stret(super, sel);
}

id
objc_lookUpClass(const char *name)
{
	return glue_objc_lookUpClass(name);
}

id
objc_getClass(const char *name)
{
	return glue_objc_getClass(name);
}

id
objc_getRequiredClass(const char *name)
{
	return glue_objc_getRequiredClass(name);
}

Class
objc_lookup_class(const char *name)
{
	return glue_objc_lookup_class(name);
}

Class
objc_get_class(const char *name)
{
	return glue_objc_get_class(name);
}

void
objc_exception_throw(id object)
{
	glue_objc_exception_throw(object);

	OF_UNREACHABLE
}

int
objc_sync_enter(id object)
{
	return glue_objc_sync_enter(object);
}

int
objc_sync_exit(id object)
{
	return glue_objc_sync_exit(object);
}

id
objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, bool atomic)
{
	return glue_objc_getProperty(self, _cmd, offset, atomic);
}

void
objc_setProperty(id self, SEL _cmd, ptrdiff_t offset, id value, bool atomic,
    signed char copy)
{
	glue_objc_setProperty(self, _cmd, offset, value, atomic, copy);
}

void
objc_getPropertyStruct(void *dest, const void *src, ptrdiff_t size, bool atomic,
    bool strong)
{
	glue_objc_getPropertyStruct(dest, src, size, atomic, strong);
}

void
objc_setPropertyStruct(void *dest, const void *src, ptrdiff_t size, bool atomic,
    bool strong)
{
	glue_objc_setPropertyStruct(dest, src, size, atomic, strong);
}

void
objc_enumerationMutation(id obj)
{
	glue_objc_enumerationMutation(obj);
}
