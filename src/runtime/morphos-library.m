/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "macros.h"

#define BOOL EXEC_BOOL
#include <dos/dos.h>
#include <emul/emulregs.h>
#include <exec/execbase.h>
#include <exec/nodes.h>
#include <exec/resident.h>
#include <exec/types.h>
#include <proto/exec.h>
#undef BOOL

struct ObjFWRTBase {
	struct Library library;
	BPTR seg_list;
};

/* Forward declarations for all functions in the func_table */
static struct Library *lib_init(struct ObjFWRTBase *base, BPTR seg_list,
    struct ExecBase *exec_base);
static struct Library *lib_open(void);
static BPTR lib_close(void);
static BPTR lib_expunge(void);
static void lib_null(void);
void objc_set_exit(void OF_NO_RETURN_FUNC (*exit_fn_)(int status));

static ULONG func_table[] = {
	FUNCARRAY_BEGIN,
	FUNCARRAY_32BIT_NATIVE,
	(ULONG)lib_open,
	(ULONG)lib_close,
	(ULONG)lib_expunge,
	(ULONG)lib_null,
	-1,
	FUNCARRAY_32BIT_SYSTEMV,
	(ULONG)objc_set_exit,
	-1,
	FUNCARRAY_END
};

static struct Library *lib_init(struct ObjFWRTBase *base, BPTR seg_list,
    struct ExecBase *exec_base);

static struct {
	LONG struct_size;
	ULONG *func_table;
	void *data_table;
	struct Library *(*init_func)(struct ObjFWRTBase *base, BPTR seg_list,
	    struct ExecBase *exec_base);
} init_table = {
	.struct_size = sizeof(struct ObjFWRTBase),
	func_table,
	NULL,
	lib_init
};

static struct Resident resident = {
	.rt_MatchWord = RTC_MATCHWORD,
	.rt_MatchTag = &resident,
	.rt_EndSkip = &resident + 1,
	.rt_Flags = RTF_AUTOINIT | RTF_PPC,
	.rt_Version = OBJFW_RT_LIB_MAJOR * 10 + OBJFW_RT_LIB_MINOR,
	.rt_Type = NT_LIBRARY,
	.rt_Pri = 0,
	.rt_Name = (char *)"objfw-rt.library",
	.rt_IdString = (char *)"ObjFW-RT " PACKAGE_VERSION
	    " \xA9 2008-2017 Jonathan Schleifer",
	.rt_Init = &init_table
};

/* Magic required to make this a MorphOS binary */
const ULONG __abox__ = 1;

/* Global variables needed by libnix */
int ThisRequiresConstructorHandling;
struct ExecBase *SysBase;
void *libnix_mempool;

/* Functions passed in from the glue linklib */
static void OF_NO_RETURN_FUNC (*exit_fn)(int status);

void OF_NO_RETURN_FUNC
exit(int status)
{
	exit_fn(status);
}

void
objc_set_exit(void OF_NO_RETURN_FUNC (*exit_fn_)(int status))
{
	exit_fn = exit_fn_;
}

/* Standard library functions */
static struct Library *lib_init(struct ObjFWRTBase *base, BPTR seg_list,
    struct ExecBase *exec_base)
{
	SysBase = exec_base;

	base->seg_list = seg_list;

	return &base->library;
}

static struct Library *
lib_open(void)
{
	struct ObjFWRTBase *base = (struct ObjFWRTBase *)REG_A6;

	base->library.lib_OpenCnt++;
	base->library.lib_Flags &= ~LIBF_DELEXP;

	return &base->library;
}

static BPTR
expunge(struct ObjFWRTBase *base)
{
	/* Still in use - set delayed expunge flag and refuse to expunge */
	if (base->library.lib_OpenCnt > 0) {
		base->library.lib_Flags |= LIBF_DELEXP;
		return 0;
	}

	Remove(&base->library.lib_Node);
	FreeMem((char *)base - base->library.lib_NegSize,
	    base->library.lib_NegSize + base->library.lib_PosSize);

	return base->seg_list;
}

static BPTR
lib_close(void)
{
	struct ObjFWRTBase *base = (struct ObjFWRTBase *)REG_A6;

	/* Not used anymore and delayed expunge flag set -> expunge */
	if (--base->library.lib_OpenCnt == 0 &&
	    (base->library.lib_Flags & LIBF_DELEXP))
		return expunge(base);

	return 0;
}

static BPTR
lib_expunge(void)
{
	return expunge((struct ObjFWRTBase *)REG_A6);
}

static void
lib_null(void)
{
}
