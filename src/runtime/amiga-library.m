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
	bool initialized;
};

struct ExecBase *SysBase;
#ifdef OF_MORPHOS
const ULONG __abox__ = 1;
#endif
struct WBStartup *_WBenchMsg;
struct objc_libc *libc;
FILE *stdout;
FILE *stderr;
extern uintptr_t __CTOR_LIST__[];
extern uintptr_t __DTOR_LIST__[];

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

	if (base->initialized) {
		for (uintptr_t *iter = &__DTOR_LIST__[1]; *iter != 0; iter++) {
			void (*dtor)(void) = (void (*)(void))*iter++;
			dtor();
		}
	}

	return 0;
}

static BPTR
lib_null(void)
{
	return 0;
}

static void
objc_init(struct ObjFWRTBase *base OBJC_M68K_REG("a6"),
    struct objc_libc *libc_ OBJC_M68K_REG("a0"))
{
	uintptr_t *iter, *iter0;

	libc = libc_;

	stdout = libc->stdout_;
	stderr = libc->stderr_;

	iter0 = &__CTOR_LIST__[1];
	for (iter = iter0; *iter != 0; iter++);

	while (iter > iter0) {
		void (*ctor)(void) = (void (*)(void))*--iter;
		ctor();
	}

	base->initialized = true;
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

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
static CONST_APTR function_table[] = {
	(CONST_APTR)lib_open,
	(CONST_APTR)lib_close,
	(CONST_APTR)lib_expunge,
	(CONST_APTR)lib_null,
#include "amiga-library-functable.inc"
	(CONST_APTR)-1,
};
#pragma GCC diagnostic pop

static struct {
	ULONG data_size;
	CONST_APTR *function_table;
	ULONG *data_table;
	struct Library *(*init_func)(
	    struct ExecBase *exec_base OBJC_M68K_REG("a6"),
	    BPTR seg_list OBJC_M68K_REG("a0"),
	    struct ObjFWRTBase *base OBJC_M68K_REG("d0"));
} init_table = {
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
	.rt_Init = &init_table
};
