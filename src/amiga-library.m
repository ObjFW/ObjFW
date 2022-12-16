/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFDNSResourceRecord.h"
#import "OFHTTPRequest.h"
#import "OFSocket.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "macros.h"

#import "amiga-glue.h"
#import "amiga-library.h"

#include <exec/libraries.h>
#include <exec/nodes.h>
#include <exec/resident.h>
#include <proto/exec.h>

#define CONCAT_VERSION2(major, minor) #major "." #minor
#define CONCAT_VERSION(major, minor) CONCAT_VERSION2(major, minor)
#define VERSION_STRING CONCAT_VERSION(OBJFW_LIB_MAJOR, OBJFW_LIB_MINOR)

#if defined(OF_AMIGAOS_M68K)
# define DATA_OFFSET 0x7FFE
#elif defined(OF_MORPHOS)
# define DATA_OFFSET 0x8000
#endif

#ifdef OF_AMIGAOS_M68K
# define OF_M68K_REG(reg) __asm__(#reg)
#else
# define OF_M68K_REG(reg)
#endif

/* This always needs to be the first thing in the file. */
int
_start(void)
{
	return -1;
}

#ifdef OF_AMIGAOS_M68K
void
__init_eh(void)
{
	/* Taken care of by OFInit() */
}
#endif

struct ObjFWBase {
	struct Library library;
	void *segList;
	struct ObjFWBase *parent;
	char *dataSeg;
	bool initialized;
};

#ifdef OF_AMIGAOS_M68K
extern uintptr_t __CTOR_LIST__[];
extern const void *_EH_FRAME_BEGINS__;
extern void *_EH_FRAME_OBJECTS__;
#endif

#ifdef OF_MORPHOS
const ULONG __abox__ = 1;
#endif
struct ExecBase *SysBase;
struct OFLibC libC;
struct Library *ObjFWRTBase;

#if defined(OF_AMIGAOS_M68K)
__asm__ (
    ".text\n"
    ".globl ___restore_a4\n"
    ".align 1\n"
    "___restore_a4:\n"
    "	movea.l	42(a6), a4\n"
    "	rts"
);
#elif defined(OF_MORPHOS)
/* All __saveds functions in this file need to use the M68K ABI */
__asm__ (
    ".section .text\n"
    ".align 2\n"
    "__restore_r13:\n"
    "	lwz	%r13, 56(%r2)\n"
    "	lwz	%r13, 44(%r13)\n"
    "	blr\n"
);
#endif

static OF_INLINE char *
getDataSeg(void)
{
	char *dataSeg;

#if defined(OF_AMIGAOS_M68K)
	__asm__ (
	    "move.l	#___a4_init, %0"
	    : "=r"(dataSeg)
	);
#elif defined(OF_MORPHOS)
	__asm__ (
	    "lis	%0, __r13_init@ha\n\t"
	    "la		%0, __r13_init@l(%0)"
	    : "=r"(dataSeg)
	);
#endif

	return dataSeg;
}

static OF_INLINE size_t
getDataSize(void)
{
	size_t dataSize;

#if defined(OF_AMIGAOS_M68K)
	__asm__ (
	    "move.l	#___data_size, %0\n\t"
	    "add.l	#___bss_size, %0"
	    : "=r"(dataSize)
	);
#elif defined(OF_MORPHOS)
	__asm__ (
	    "lis	%0, __sdata_size@ha\n\t"
	    "la		%0, __sdata_size@l(%0)\n\t"
	    "lis	%%r9, __sbss_size@ha\n\t"
	    "la		%%r9, __sbss_size@l(%%r9)\n\t"
	    "add	%0, %0, %%r9"
	    : "=r"(dataSize)
	    :: "r9"
	);
#endif

	return dataSize;
}

static OF_INLINE size_t *
getDataDataRelocs(void)
{
	size_t *dataDataRelocs;

#if defined(OF_AMIGAOS_M68K)
	__asm__ (
	    "move.l	#___datadata_relocs, %0"
	    : "=r"(dataDataRelocs)
	);
#elif defined(OF_MORPHOS)
	__asm__ (
	    "lis	%0, __datadata_relocs@ha\n\t"
	    "la		%0, __datadata_relocs@l(%0)\n\t"
	    : "=r"(dataDataRelocs)
	);
#endif

	return dataDataRelocs;
}

static struct Library *
libInit(struct ObjFWBase *base OF_M68K_REG(d0),
    void *segList OF_M68K_REG(a0), struct ExecBase *sysBase OF_M68K_REG(a6))
{
#if defined(OF_AMIGAOS_M68K)
	__asm__ __volatile__ (
	    "move.l	a6, _SysBase"
	    :: "a"(sysBase)
	);
#elif defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "lis	%%r9, SysBase@ha\n\t"
	    "stw	%0, SysBase@l(%%r9)"
	    :: "r"(sysBase) : "r9"
	);
#endif

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

#ifdef OF_AMIGAOS_M68K
		if (base->initialized)
			for (void *const *frame = _EH_FRAME_BEGINS__;
			    *frame != NULL;)
				libC.__deregister_frame_info(*frame++);
#endif

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
#ifdef OF_AMIGAOS_M68K
	OF_M68K_ARG(struct ObjFWBase *, base, a6)
#else
	register struct ObjFWBase *r12 __asm__("r12");
	struct ObjFWBase *base = r12;
#endif
#ifdef OF_MORPHOS
	void *frame;
#endif
	uintptr_t *iter0;

	if (version > 1)
		return false;

	if (base->initialized)
		return true;

	memcpy(&libC, libC_, sizeof(libC));

#ifdef OF_AMIGAOS_M68K
	for (void *const *frame = _EH_FRAME_BEGINS__,
	    **object = _EH_FRAME_OBJECTS__; *frame != NULL;)
		libC.__register_frame_info(*frame++, *object++);

	iter0 = &__CTOR_LIST__[1];
#elif defined(OF_MORPHOS)
	__asm__ (
	    "lis	%0, __EH_FRAME_BEGIN__@ha\n\t"
	    "la		%0, __EH_FRAME_BEGIN__@l(%0)\n\t"
	    "lis	%1, __CTOR_LIST__@ha\n\t"
	    "la		%1, __CTOR_LIST__@l(%1)\n\t"
	    : "=r"(frame), "=r"(iter0)
	);

	libC.__register_frame(frame);
#endif

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

#ifdef HAVE_SJLJ_EXCEPTIONS
int
_Unwind_SjLj_RaiseException(void *ex)
{
	return libC._Unwind_SjLj_RaiseException(ex);
}
#else
int
_Unwind_RaiseException(void *ex)
{
	return libC._Unwind_RaiseException(ex);
}
#endif

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

#ifdef HAVE_SJLJ_EXCEPTIONS
void
_Unwind_SjLj_Resume(void *ex)
{
	libC._Unwind_SjLj_Resume(ex);
}
#else
void
_Unwind_Resume(void *ex)
{
	libC._Unwind_Resume(ex);
}
#endif

#ifdef OF_AMIGAOS_M68K
void
__register_frame_info(const void *begin, void *object)
{
	libC.__register_frame_info(begin, object);
}

void
*__deregister_frame_info(const void *begin)
{
	return libC.__deregister_frame_info(begin);
}
#endif

#ifdef OF_MORPHOS
void __register_frame(void *frame)
{
	libC.__register_frame(frame);
}

void __deregister_frame(void *frame)
{
	libC.__deregister_frame(frame);
}
#endif

int *
OFErrNo(void)
{
	return libC.errNo();
}

#ifdef OF_MORPHOS
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
#else
int
vsnprintf(char *restrict str, size_t size, const char *restrict fmt,
    va_list args)
{
	return libC.vsnprintf(str, size, fmt, args);
}
#endif

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

#ifdef OF_MORPHOS
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
#endif

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

#ifdef OF_MORPHOS
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
#endif

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
#ifdef OF_MORPHOS
	(CONST_APTR)FUNCARRAY_BEGIN,
	(CONST_APTR)FUNCARRAY_32BIT_NATIVE,
#endif
	(CONST_APTR)libOpen,
	(CONST_APTR)libClose,
	(CONST_APTR)libExpunge,
	(CONST_APTR)libNull,
#ifdef OF_MORPHOS
	(CONST_APTR)-1,
	(CONST_APTR)FUNCARRAY_32BIT_SYSTEMV,
#endif
#include "amiga-funcarray.inc"
	(CONST_APTR)-1,
#ifdef OF_MORPHOS
	(CONST_APTR)FUNCARRAY_END
#endif
};
#pragma GCC diagnostic pop

static struct {
	ULONG dataSize;
	CONST_APTR *functionTable;
	ULONG *dataTable;
	struct Library *(*initFunc)(
	    struct ObjFWBase *base OF_M68K_REG(d0),
	    void *segList OF_M68K_REG(a0),
	    struct ExecBase *execBase OF_M68K_REG(a6));
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
	.rt_Flags = RTF_AUTOINIT
#ifdef OF_MORPHOS
	    | RTF_PPC | RTF_EXTENDED
#endif
	    ,
	.rt_Version = OBJFW_LIB_MAJOR,
	.rt_Type = NT_LIBRARY,
	.rt_Pri = 0,
	.rt_Name = (char *)OBJFW_AMIGA_LIB,
	.rt_IdString = (char *)"ObjFW " VERSION_STRING
	    " \xA9 2008-2022 Jonathan Schleifer",
	.rt_Init = &init_table,
#ifdef OF_MORPHOS
	.rt_Revision = OBJFW_LIB_MINOR,
	.rt_Tags = NULL,
#endif
};

#if defined(OF_MORPHOS)
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
#elif defined(OF_AMIGAOS_M68K)
__asm__ (
    ".section .list___EH_FRAME_BEGINS__, \"aw\"\n"
    ".globl __EH_FRAME_BEGIN__\n"
    ".type __EH_FRAME_BEGIN__, @object\n"
    "__EH_FRAME_BEGINS__:\n"
    ".section .dlist___EH_FRAME_OBJECTS__, \"aw\"\n"
    ".globl __EH_FRAME_OBJECTS__\n"
    ".type __EH_FRAME_OBJECTS__, @object\n"
    "__EH_FRAME_OBJECTS__:\n"
    ".section .list___CTOR_LIST__, \"aw\"\n"
    ".globl ___CTOR_LIST__\n"
    ".type ___CTOR_LIST__, @object\n"
    "___CTOR_LIST__:\n"
    ".section .text"
);
#endif
