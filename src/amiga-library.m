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

#import "OFDNSResourceRecord.h"
#import "OFHTTPRequest.h"
#import "OFSocket.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "macros.h"

#import "amiga-library.h"
#import "amiga-library-glue.h"

#define Class IntuitionClass
#include <exec/libraries.h>
#include <exec/nodes.h>
#include <exec/resident.h>
#include <proto/exec.h>
#undef Class

#define CONCAT_VERSION2(major, minor) #major "." #minor
#define CONCAT_VERSION(major, minor) CONCAT_VERSION2(major, minor)
#define VERSION_STRING CONCAT_VERSION(OBJFW_LIB_MAJOR, OBJFW_LIB_MINOR)

#define DATA_OFFSET 0x8000

/* This always needs to be the first thing in the file. */
int
_start(void)
{
	return -1;
}

struct ObjFWBase {
	struct Library library;
	void *segList;
	struct ObjFWBase *parent;
	char *dataSeg;
	bool initialized;
};

const ULONG __abox__ = 1;
struct ExecBase *SysBase;
struct OFLibC libC;
struct Library *ObjFWRTBase;

/* All __saveds functions in this file need to use the M68K ABI */
__asm__ (
    ".section .text\n"
    ".align 2\n"
    "__restore_r13:\n"
    "	lwz	%r13, 56(%r2)\n"
    "	lwz	%r13, 44(%r13)\n"
    "	blr\n"
);

static OF_INLINE char *
getDataSeg(void)
{
	char *dataSeg;

	__asm__ (
	    "lis	%0, __r13_init@ha\n\t"
	    "la		%0, __r13_init@l(%0)"
	    : "=r"(dataSeg)
	);

	return dataSeg;
}

static OF_INLINE size_t
getDataSize(void)
{
	size_t dataSize;

	__asm__ (
	    "lis	%0, __sdata_size@ha\n\t"
	    "la		%0, __sdata_size@l(%0)\n\t"
	    "lis	%%r9, __sbss_size@ha\n\t"
	    "la		%%r9, __sbss_size@l(%%r9)\n\t"
	    "add	%0, %0, %%r9"
	    : "=r"(dataSize)
	    :: "r9"
	);

	return dataSize;
}

static OF_INLINE size_t *
getDataDataRelocs(void)
{
	size_t *dataDataRelocs;

	__asm__ (
	    "lis	%0, __datadata_relocs@ha\n\t"
	    "la		%0, __datadata_relocs@l(%0)\n\t"
	    : "=r"(dataDataRelocs)
	);

	return dataDataRelocs;
}

static struct Library *
libInit(struct ObjFWBase *base, void *segList, struct ExecBase *sysBase)
{
	__asm__ __volatile__ (
	    "lis	%%r9, SysBase@ha\n\t"
	    "stw	%0, SysBase@l(%%r9)"
	    :: "r"(sysBase) : "r9"
	);

	base->segList = segList;
	base->parent = NULL;
	base->dataSeg = getDataSeg();

	return &base->library;
}

struct Library *__saveds
libOpen(void)
{
	OF_M68K_ARG(struct ObjFWBase *, base, a6)

	struct ObjFWBase *child;
	size_t dataSize, *dataDataRelocs;
	ptrdiff_t displacement;

	if (base->parent != NULL)
		return NULL;

	base->library.lib_OpenCnt++;
	base->library.lib_Flags &= ~LIBF_DELEXP;

	/*
	 * We cannot use malloc here, as that depends on the libC passed from
	 * the application.
	 */
	if ((child = AllocMem(base->library.lib_NegSize +
	    base->library.lib_PosSize, MEMF_ANY)) == NULL) {
		base->library.lib_OpenCnt--;
		return NULL;
	}

	memcpy(child, (char *)base - base->library.lib_NegSize,
	    base->library.lib_NegSize + base->library.lib_PosSize);

	child = (struct ObjFWBase *)((char *)child + base->library.lib_NegSize);
	child->library.lib_OpenCnt = 1;
	child->parent = base;

	dataSize = getDataSize();

	if ((child->dataSeg = AllocMem(dataSize, MEMF_ANY)) == NULL) {
		FreeMem((char *)child - child->library.lib_NegSize,
		    child->library.lib_NegSize + child->library.lib_PosSize);
		base->library.lib_OpenCnt--;
		return NULL;
	}

	memcpy(child->dataSeg, base->dataSeg - DATA_OFFSET, dataSize);

	dataDataRelocs = getDataDataRelocs();
	displacement = child->dataSeg - (base->dataSeg - DATA_OFFSET);

	for (size_t i = 1; i <= dataDataRelocs[0]; i++)
		*(long *)(child->dataSeg + dataDataRelocs[i]) += displacement;

	child->dataSeg += DATA_OFFSET;

	return &child->library;
}

static void *
expunge(struct ObjFWBase *base, struct ExecBase *sysBase)
{
#define SysBase sysBase
	void *segList;

	if (base->parent != NULL) {
		base->parent->library.lib_Flags |= LIBF_DELEXP;
		return 0;
	}

	if (base->library.lib_OpenCnt > 0) {
		base->library.lib_Flags |= LIBF_DELEXP;
		return 0;
	}

	segList = base->segList;

	Remove(&base->library.lib_Node);
	FreeMem((char *)base - base->library.lib_NegSize,
	    base->library.lib_NegSize + base->library.lib_PosSize);

	return segList;
#undef SysBase
}

static void *__saveds
libExpunge(void)
{
	OF_M68K_ARG(struct ObjFWBase *, base, a6)

	return expunge(base, SysBase);
}

static void *__saveds
libClose(void)
{
	/*
	 * SysBase becomes invalid during this function, so we store it in
	 * sysBase and add a define to make the inlines use the right one.
	 */
	struct ExecBase *sysBase = SysBase;
#define SysBase sysBase

	OF_M68K_ARG(struct ObjFWBase *, base, a6)

	if (base->parent != NULL) {
		struct ObjFWBase *parent;

		parent = base->parent;

		FreeMem(base->dataSeg - DATA_OFFSET, getDataSize());
		FreeMem((char *)base - base->library.lib_NegSize,
		    base->library.lib_NegSize + base->library.lib_PosSize);

		base = parent;
	}

	if (--base->library.lib_OpenCnt == 0 &&
	    (base->library.lib_Flags & LIBF_DELEXP))
		return expunge(base, sysBase);

	return NULL;
#undef SysBase
}

static void *
libNull(void)
{
	return NULL;
}

static void __saveds
OFInitPart2(uintptr_t *iter0, struct Library *RTBase)
{
	uintptr_t *iter;

	ObjFWRTBase = RTBase;

	for (iter = iter0; *iter != 0; iter++);

	while (iter > iter0) {
		void (*ctor)(void) = (void (*)(void))*--iter;
		ctor();
	}
}

bool
OFInit(unsigned int version, struct OFLibC *libC_, struct Library *RTBase)
{
	register struct ObjFWBase *r12 __asm__("r12");
	struct ObjFWBase *base = r12;
	void *frame;
	uintptr_t *iter0;

	if (version > 1)
		return false;

	if (base->initialized)
		return true;

	memcpy(&libC, libC_, sizeof(libC));

	__asm__ (
	    "lis	%0, __EH_FRAME_BEGIN__@ha\n\t"
	    "la		%0, __EH_FRAME_BEGIN__@l(%0)\n\t"
	    "lis	%1, __CTOR_LIST__@ha\n\t"
	    "la		%1, __CTOR_LIST__@l(%1)\n\t"
	    : "=r"(frame), "=r"(iter0)
	);

	libC.__register_frame(frame);

	OFInitPart2(iter0, RTBase);

	base->initialized = true;

	return true;
}

void *
malloc(size_t size)
{
	return libC.malloc(size);
}

void *
calloc(size_t count, size_t size)
{
	return libC.calloc(count, size);
}

void *
realloc(void *ptr, size_t size)
{
	return libC.realloc(ptr, size);
}

void
free(void *ptr)
{
	libC.free(ptr);
}

void
abort(void)
{
	libC.abort();

	OF_UNREACHABLE
}

int
_Unwind_RaiseException(void *ex)
{
	return libC._Unwind_RaiseException(ex);
}

void
_Unwind_DeleteException(void *ex)
{
	libC._Unwind_DeleteException(ex);
}

void *
_Unwind_GetLanguageSpecificData(void *ctx)
{
	return libC._Unwind_GetLanguageSpecificData(ctx);
}

uintptr_t
_Unwind_GetRegionStart(void *ctx)
{
	return libC._Unwind_GetRegionStart(ctx);
}

uintptr_t
_Unwind_GetDataRelBase(void *ctx)
{
	return libC._Unwind_GetDataRelBase(ctx);
}

uintptr_t
_Unwind_GetTextRelBase(void *ctx)
{
	return libC._Unwind_GetTextRelBase(ctx);
}

uintptr_t
_Unwind_GetIP(void *ctx)
{
	return libC._Unwind_GetIP(ctx);
}

uintptr_t
_Unwind_GetGR(void *ctx, int gr)
{
	return libC._Unwind_GetGR(ctx, gr);
}

void
_Unwind_SetIP(void *ctx, uintptr_t ip)
{
	libC._Unwind_SetIP(ctx, ip);
}

void
_Unwind_SetGR(void *ctx, int gr, uintptr_t value)
{
	libC._Unwind_SetGR(ctx, gr, value);
}

void
_Unwind_Resume(void *ex)
{
	libC._Unwind_Resume(ex);
}

void __register_frame(void *frame)
{
	libC.__register_frame(frame);
}

void __deregister_frame(void *frame)
{
	libC.__deregister_frame(frame);
}

int *
OFErrNo(void)
{
	return libC.errNo();
}

int
vasprintf(char **restrict strp, const char *restrict fmt, va_list args)
{
	return libC.vasprintf(strp, fmt, args);
}

int
asprintf(char **restrict strp, const char *restrict fmt, ...)
{
	va_list args;
	int ret;

	va_start(args, fmt);
	ret = vasprintf(strp, fmt, args);
	va_end(args);

	return ret;
}

float
strtof(const char *str, char **endptr)
{
	return libC.strtof(str, endptr);
}

double
strtod(const char *str, char **endptr)
{
	return libC.strtod(str, endptr);
}

struct tm *
gmtime_r(const time_t *time, struct tm *tm)
{
	return libC.gmtime_r(time, tm);
}

struct tm *
localtime_r(const time_t *time, struct tm *tm)
{
	return libC.localtime_r(time, tm);
}

int
gettimeofday(struct timeval *tv, struct timezone *tz)
{
	return libC.gettimeofday(tv, tz);
}

time_t
mktime(struct tm *tm)
{
	return libC.mktime(tm);
}

size_t
strftime(char *str, size_t len, const char *fmt, const struct tm *tm)
{
	return libC.strftime(str, len, fmt, tm);
}

void
exit(int status)
{
	libC.exit(status);

	OF_UNREACHABLE
}

int
atexit(void (*function)(void))
{
	return libC.atexit(function);
}

OFSignalHandler
signal(int sig, OFSignalHandler func)
{
	return libC.signal(sig, func);
}

char *
setlocale(int category, const char *locale)
{
	return libC.setlocale(category, locale);
}

int
_Unwind_Backtrace(int (*callback)(void *, void *), void *data)
{
	return libC._Unwind_Backtrace(callback, data);
}

int
setjmp(jmp_buf env)
{
	return libC.setjmp(env);
}

void
longjmp(jmp_buf env, int val)
{
	libC.longjmp(env, val);
}

void
OFPBKDF2Wrapper(const OFPBKDF2Parameters *parameters)
{
	OFPBKDF2(*parameters);
}

void
OFScryptWrapper(const OFScryptParameters *parameters)
{
	OFScrypt(*parameters);
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
static CONST_APTR functionTable[] = {
	(CONST_APTR)FUNCARRAY_BEGIN,
	(CONST_APTR)FUNCARRAY_32BIT_NATIVE,
	(CONST_APTR)libOpen,
	(CONST_APTR)libClose,
	(CONST_APTR)libExpunge,
	(CONST_APTR)libNull,
	(CONST_APTR)-1,
	(CONST_APTR)FUNCARRAY_32BIT_SYSTEMV,
#include "amiga-library-funcarray.inc"
	(CONST_APTR)-1,
	(CONST_APTR)FUNCARRAY_END
};
#pragma GCC diagnostic pop

static struct {
	ULONG dataSize;
	CONST_APTR *functionTable;
	ULONG *dataTable;
	struct Library *(*initFunc)(struct ObjFWBase *base, void *segList,
	    struct ExecBase *execBase);
} init_table = {
	sizeof(struct ObjFWBase),
	functionTable,
	NULL,
	libInit
};

struct Resident resident = {
	.rt_MatchWord = RTC_MATCHWORD,
	.rt_MatchTag = &resident,
	.rt_EndSkip = &resident + 1,
	.rt_Flags = RTF_AUTOINIT | RTF_PPC | RTF_EXTENDED,
	.rt_Version = OBJFW_LIB_MAJOR,
	.rt_Type = NT_LIBRARY,
	.rt_Pri = 0,
	.rt_Name = (char *)OBJFW_AMIGA_LIB,
	.rt_IdString = (char *)"ObjFW " VERSION_STRING
	    " \xA9 2008-2023 Jonathan Schleifer",
	.rt_Init = &init_table,
	.rt_Revision = OBJFW_LIB_MINOR,
	.rt_Tags = NULL,
};

__asm__ (
    ".section .eh_frame, \"aw\"\n"
    ".globl __EH_FRAME_BEGIN__\n"
    ".type __EH_FRAME_BEGIN__, @object\n"
    "__EH_FRAME_BEGIN__:\n"
    ".section .ctors, \"aw\"\n"
    ".globl __CTOR_LIST__\n"
    ".type __CTOR_LIST__, @object\n"
    "__CTOR_LIST__:\n"
    ".section .text"
);
