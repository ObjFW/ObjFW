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
#import "platform.h"

#ifdef OF_AMIGAOS3
# define INTUITION_CLASSES_H
#endif

#include <exec/libraries.h>
#include <exec/nodes.h>
#include <exec/resident.h>
#include <proto/exec.h>

#define CONCAT_VERSION2(major, minor) #major "." #minor
#define CONCAT_VERSION(major, minor) CONCAT_VERSION2(major, minor)
#define VERSION_STRING CONCAT_VERSION(OBJFW_RT_LIB_MAJOR, OBJFW_RT_LIB_MINOR)

/* This always needs to be the first thing in the file. */
int
_start()
{
	return -1;
}

struct ObjFWRTBase {
	struct Library library;
	BPTR seg_list;
};

struct ExecBase *SysBase;
#ifdef OF_MORPHOS
const ULONG __abox__ = 1;
#endif
struct WBStartup *_WBenchMsg;
struct objc_libc *libc;
FILE *stdout;
FILE *stderr;

static struct Library *
lib_init(struct ExecBase *exec_base OBJC_M68K_REG("a6"),
    BPTR seg_list OBJC_M68K_REG("a0"),
    struct ObjFWRTBase *base OBJC_M68K_REG("d0"))
{
	SysBase = exec_base;

	base->seg_list = seg_list;

	return &base->library;
}

static struct Library *
OBJC_M68K_FUNC(lib_open, struct ObjFWRTBase *base OBJC_M68K_REG("a6"))
{
	OBJC_M68K_ARG(struct ObjFWRTBase *, base, REG_A6)

	base->library.lib_OpenCnt++;
	base->library.lib_Flags &= ~LIBF_DELEXP;

	return &base->library;
}

static BPTR
expunge(struct ObjFWRTBase *base)
{
	BPTR seg_list;

	if (base->library.lib_OpenCnt > 0) {
		base->library.lib_Flags |= LIBF_DELEXP;
		return 0;
	}

	seg_list = base->seg_list;

	Remove(&base->library.lib_Node);
	FreeMem((char *)base - base->library.lib_NegSize,
	    base->library.lib_NegSize + base->library.lib_PosSize);

	return seg_list;
}

static BPTR
OBJC_M68K_FUNC(lib_expunge, struct ObjFWRTBase *base OBJC_M68K_REG("a6"))
{
	OBJC_M68K_ARG(struct ObjFWRTBase *, base, REG_A6)

	return expunge(base);
}

static BPTR
OBJC_M68K_FUNC(lib_close, struct ObjFWRTBase *base OBJC_M68K_REG("a6"))
{
	OBJC_M68K_ARG(struct ObjFWRTBase *, base, REG_A6)

	if (--base->library.lib_OpenCnt == 0 &&
	    (base->library.lib_Flags & LIBF_DELEXP))
		return expunge(base);

	return 0;
}

static BPTR
lib_null(void)
{
	return 0;
}

static void
objc_set_libc(struct objc_libc *libc_ OBJC_M68K_REG("a0"))
{
	libc = libc_;

	stdout = libc->stdout;
	stderr = libc->stderr;
}

void *
malloc(size_t size)
{
	return libc->malloc(size);
}

void *
calloc(size_t count, size_t size)
{
	return libc->calloc(count, size);
}

void *
realloc(void *ptr, size_t size)
{
	return libc->realloc(ptr, size);
}

void
free(void *ptr)
{
	libc->free(ptr);
}

int
fprintf(FILE *restrict stream, const char *restrict fmt, ...)
{
	int ret;
	va_list args;

	va_start(args, fmt);
	ret = libc->vfprintf(stream, fmt, args);
	va_end(args);

	return ret;
}

int
fputs(const char *restrict s, FILE *restrict stream)
{
	return libc->fputs(s, stream);
}

void
exit(int status)
{
	libc->exit(status);
}

void
abort(void)
{
	libc->abort();
}

static ULONG function_table[] = {
	(ULONG)lib_open,
	(ULONG)lib_close,
	(ULONG)lib_expunge,
	(ULONG)lib_null,
	/* Functions for the linklib */
	(ULONG)objc_set_libc,
	/* Used by the compiler - these need glue code */
	(ULONG)glue___objc_exec_class,
	(ULONG)glue_objc_msg_lookup,
	(ULONG)glue_objc_msg_lookup_stret,
	(ULONG)glue_objc_msg_lookup_super,
	(ULONG)glue_objc_msg_lookup_super_stret,
	(ULONG)glue_objc_lookUpClass,
	(ULONG)glue_objc_getClass,
	(ULONG)glue_objc_getRequiredClass,
	(ULONG)glue_objc_exception_throw,
	(ULONG)glue_objc_sync_enter,
	(ULONG)glue_objc_sync_exit,
	(ULONG)glue_objc_getProperty,
	(ULONG)glue_objc_setProperty,
	(ULONG)glue_objc_getPropertyStruct,
	(ULONG)glue_objc_setPropertyStruct,
	(ULONG)glue_objc_enumerationMutation,
	/* Functions declared in ObjFW_RT.h */
	(ULONG)sel_registerName,
	(ULONG)sel_getName,
	(ULONG)sel_isEqual,
	(ULONG)objc_allocateClassPair,
	(ULONG)objc_registerClassPair,
	(ULONG)objc_getClassList,
	(ULONG)objc_copyClassList,
	(ULONG)class_isMetaClass,
	(ULONG)class_getName,
	(ULONG)class_getSuperclass,
	(ULONG)class_getInstanceSize,
	(ULONG)class_respondsToSelector,
	(ULONG)class_conformsToProtocol,
	(ULONG)class_getMethodImplementation,
	(ULONG)class_getMethodImplementation_stret,
	(ULONG)class_getMethodTypeEncoding,
	(ULONG)class_addMethod,
	(ULONG)class_replaceMethod,
	(ULONG)object_getClass,
	(ULONG)object_setClass,
	(ULONG)object_getClassName,
	(ULONG)protocol_getName,
	(ULONG)protocol_isEqual,
	(ULONG)protocol_conformsToProtocol,
	(ULONG)objc_exit,
	(ULONG)objc_setUncaughtExceptionHandler,
	(ULONG)objc_setForwardHandler,
	(ULONG)objc_setEnumerationMutationHandler,
	(ULONG)objc_zero_weak_references,
	-1,
};

static struct {
	ULONG data_size;
	ULONG *function_table;
	ULONG *data_table;
	struct Library *(*init_func)(
	    struct ExecBase *exec_base OBJC_M68K_REG("a6"),
	    BPTR seg_list OBJC_M68K_REG("a0"),
	    struct ObjFWRTBase *base OBJC_M68K_REG("d0"));
} initTable = {
	sizeof(struct ObjFWRTBase),
	function_table,
	NULL,
	lib_init
};

static struct Resident resident = {
	.rt_MatchWord = RTC_MATCHWORD,
	.rt_MatchTag = &resident,
	.rt_EndSkip = &resident + 1,
	.rt_Flags = RTF_AUTOINIT
#ifndef OF_AMIGAOS3
	    | RTF_PPC
#endif
	    ,
	.rt_Version = OBJFW_RT_LIB_MAJOR,
	.rt_Type = NT_LIBRARY,
	.rt_Pri = 0,
	.rt_Name = (char *)"objfw_rt.library",
	.rt_IdString = (char *)"ObjFW_RT " VERSION_STRING
	    " \xA9 2008-2018 Jonathan Schleifer",
	.rt_Init = &initTable
};
