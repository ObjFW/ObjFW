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

#import "ObjFWRT.h"
#import "private.h"

#import "amiga-glue.h"

#define Class IntuitionClass
#include <exec/libraries.h>
#include <exec/nodes.h>
#include <exec/resident.h>
#include <proto/exec.h>
#undef Class

#if defined(OF_MORPHOS)
# define OBJC_M68K_REG(reg)
# define DATA_OFFSET 0x8000
#elif defined(OF_AMIGAOS_M68K)
# define OBJC_M68K_REG(reg) __asm__(#reg)
# define DATA_OFFSET 0x7FFE
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
	/* Taken care of by objc_init() */
}
#endif

struct ObjFWRTBase {
	struct Library library;
	void *segList;
	struct ObjFWRTBase *parent;
	char *dataSeg;
	bool initialized;
};

#ifdef OF_MORPHOS
const ULONG __abox__ = 1;
#endif

#ifdef OF_AMIGAOS_M68K
extern uintptr_t __CTOR_LIST__[];
extern const void *_EH_FRAME_BEGINS__;
extern void *_EH_FRAME_OBJECTS__;
#endif

struct ExecBase *SysBase;
static struct objc_linklib_context linklibCtx;

#ifdef OF_MORPHOS
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

#ifdef OF_AMIGAOS_M68K
__asm__ (
    ".text\n"
    ".globl ___restore_a4\n"
    ".align 1\n"
    "___restore_a4:\n"
    "	movea.l	42(a6), a4\n"
    "	rts"
);
#endif

static OF_INLINE char *
getDataSeg(void)
{
	char *dataSeg;

#if defined(OF_MORPHOS)
	__asm__ (
	    "lis	%0, __r13_init@ha\n\t"
	    "la		%0, __r13_init@l(%0)"
	    : "=r"(dataSeg)
	);
#elif defined(OF_AMIGAOS_M68K)
	__asm__ (
	    "move.l	#___a4_init, %0"
	    : "=r"(dataSeg)
	);
#endif

	return dataSeg;
}

static OF_INLINE size_t
getDataSize(void)
{
	size_t dataSize;

#if defined(OF_MORPHOS)
	__asm__ (
	    "lis	%0, __sdata_size@ha\n\t"
	    "la		%0, __sdata_size@l(%0)\n\t"
	    "lis	%%r9, __sbss_size@ha\n\t"
	    "la		%%r9, __sbss_size@l(%%r9)\n\t"
	    "add	%0, %0, %%r9"
	    : "=r"(dataSize)
	    :: "r9"
	);
#elif defined(OF_AMIGAOS_M68K)
	__asm__ (
	    "move.l	#___data_size, %0\n\t"
	    "add.l	#___bss_size, %0"
	    : "=r"(dataSize)
	);
#endif

	return dataSize;
}

static OF_INLINE size_t *
getDataDataRelocs(void)
{
	size_t *dataDataRelocs;

#ifdef OF_MORPHOS
	__asm__ (
	    "lis	%0, __datadata_relocs@ha\n\t"
	    "la		%0, __datadata_relocs@l(%0)\n\t"
	    : "=r"(dataDataRelocs)
	);
#elif defined(OF_AMIGAOS_M68K)
	__asm__ (
	    "move.l	#___datadata_relocs, %0"
	    : "=r"(dataDataRelocs)
	);
#endif

	return dataDataRelocs;
}

static struct Library *
libInit(struct ObjFWRTBase *base, void *segList, struct ExecBase *sysBase)
{
#if defined(OF_MORPHOS)
	__asm__ __volatile__ (
	    "lis	%%r9, SysBase@ha\n\t"
	    "stw	%0, SysBase@l(%%r9)"
	    :: "r"(sysBase) : "r9"
	);
#elif defined(OF_AMIGAOS_M68K)
	__asm__ __volatile__ (
	    "move.l	a6, _SysBase"
	    :: "a"(sysBase)
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
	OBJC_M68K_ARG(struct ObjFWRTBase *, base, a6)

	struct ObjFWRTBase *child;
	size_t dataSize, *dataDataRelocs;
	ptrdiff_t displacement;

	if (base->parent != NULL)
		return NULL;

	base->library.lib_OpenCnt++;
	base->library.lib_Flags &= ~LIBF_DELEXP;

	/*
	 * We cannot use malloc here, as that depends on the linklib context
	 * passed from the application.
	 */
	if ((child = AllocMem(base->library.lib_NegSize +
	    base->library.lib_PosSize, MEMF_ANY)) == NULL) {
		base->library.lib_OpenCnt--;
		return NULL;
	}

	CopyMem((char *)base - base->library.lib_NegSize, child,
	    base->library.lib_NegSize + base->library.lib_PosSize);

	child = (struct ObjFWRTBase *)
	    ((char *)child + base->library.lib_NegSize);
	child->library.lib_OpenCnt = 1;
	child->parent = base;

	dataSize = getDataSize();

	if ((child->dataSeg = AllocMem(dataSize, MEMF_ANY)) == NULL) {
		FreeMem((char *)child - child->library.lib_NegSize,
		    child->library.lib_NegSize + child->library.lib_PosSize);
		base->library.lib_OpenCnt--;
		return NULL;
	}

	CopyMem(base->dataSeg - DATA_OFFSET, child->dataSeg, dataSize);

	dataDataRelocs = getDataDataRelocs();
	displacement = child->dataSeg - (base->dataSeg - DATA_OFFSET);

	for (size_t i = 1; i <= dataDataRelocs[0]; i++)
		*(long *)(child->dataSeg + dataDataRelocs[i]) += displacement;

	child->dataSeg += DATA_OFFSET;

	return &child->library;
}

static void *
expunge(struct ObjFWRTBase *base, struct ExecBase *sysBase)
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
	OBJC_M68K_ARG(struct ObjFWRTBase *, base, a6)

	return expunge(base, SysBase);
}

static void *__saveds
libClose(void)
{
	OBJC_M68K_ARG(struct ObjFWRTBase *, base, a6)

	/*
	 * SysBase becomes invalid during this function, so we store it in
	 * sysBase and add a define to make the inlines use the right one.
	 */
	struct ExecBase *sysBase = SysBase;
#define SysBase sysBase

	if (base->parent != NULL) {
		struct ObjFWRTBase *parent;

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

bool
objc_init(struct objc_linklib_context *ctx)
{
#if defined(OF_MORPHOS)
	register struct ObjFWRTBase *r12 __asm__("r12");
	struct ObjFWRTBase *base = r12;
#elif defined(OF_AMIGAOS_M68K)
	OBJC_M68K_ARG(struct ObjFWRTBase *, base, a6)
#endif
	void *frame;
	uintptr_t *iter, *iter0;

	if (ctx->version > 1)
		return false;

	if (base->initialized)
		return true;

	memcpy(&linklibCtx, ctx, sizeof(linklibCtx));

#if defined(OF_MORPHOS)
	__asm__ (
	    "lis	%0, __EH_FRAME_BEGIN__@ha\n\t"
	    "la		%0, __EH_FRAME_BEGIN__@l(%0)\n\t"
	    "lis	%1, __CTOR_LIST__@ha\n\t"
	    "la		%1, __CTOR_LIST__@l(%1)\n\t"
	    : "=r"(frame), "=r"(iter0)
	);

	linklibCtx.__register_frame(frame);
#elif defined(OF_AMIGAOS_M68K)
	for (void *const *frame = _EH_FRAME_BEGINS__,
	    **object = _EH_FRAME_OBJECTS__; *frame != NULL;)
		linklibCtx.__register_frame_info(*frame++, *object++);

	iter0 = &__CTOR_LIST__[1];
#endif

	for (iter = iter0; *iter != 0; iter++);

	while (iter > iter0) {
		void (*ctor)(void) = (void (*)(void))*--iter;
		ctor();
	}

	base->initialized = true;

	return true;
}

void *
malloc(size_t size)
{
	return linklibCtx.malloc(size);
}

void *
calloc(size_t count, size_t size)
{
	return linklibCtx.calloc(count, size);
}

void *
realloc(void *ptr, size_t size)
{
	return linklibCtx.realloc(ptr, size);
}

void
free(void *ptr)
{
	linklibCtx.free(ptr);
}

#ifdef OF_MORPHOS
int
_Unwind_RaiseException(void *ex)
{
	return linklibCtx._Unwind_RaiseException(ex);
}
#else
int
_Unwind_SjLj_RaiseException(void *ex)
{
	return linklibCtx._Unwind_SjLj_RaiseException(ex);
}
#endif

void
_Unwind_DeleteException(void *ex)
{
	linklibCtx._Unwind_DeleteException(ex);
}

void *
_Unwind_GetLanguageSpecificData(void *ctx)
{
	return linklibCtx._Unwind_GetLanguageSpecificData(ctx);
}

uintptr_t
_Unwind_GetRegionStart(void *ctx)
{
	return linklibCtx._Unwind_GetRegionStart(ctx);
}

uintptr_t
_Unwind_GetDataRelBase(void *ctx)
{
	return linklibCtx._Unwind_GetDataRelBase(ctx);
}

uintptr_t
_Unwind_GetTextRelBase(void *ctx)
{
	return linklibCtx._Unwind_GetTextRelBase(ctx);
}

uintptr_t
_Unwind_GetIP(void *ctx)
{
	return linklibCtx._Unwind_GetIP(ctx);
}

uintptr_t
_Unwind_GetGR(void *ctx, int gr)
{
	return linklibCtx._Unwind_GetGR(ctx, gr);
}

void
_Unwind_SetIP(void *ctx, uintptr_t ip)
{
	linklibCtx._Unwind_SetIP(ctx, ip);
}

void
_Unwind_SetGR(void *ctx, int gr, uintptr_t value)
{
	linklibCtx._Unwind_SetGR(ctx, gr, value);
}

#ifdef OF_MORPHOS
void
_Unwind_Resume(void *ex)
{
	linklibCtx._Unwind_Resume(ex);
}

void __register_frame(void *frame)
{
	linklibCtx.__register_frame(frame);
}

void __deregister_frame(void *frame)
{
	linklibCtx.__deregister_frame(frame);
}
#else
void
_Unwind_SjLj_Resume(void *ex)
{
	linklibCtx._Unwind_SjLj_Resume(ex);
}

void
__register_frame_info(const void *begin, void *object)
{
	linklibCtx.__register_frame_info(begin, object);
}

void
*__deregister_frame_info(const void *begin)
{
	return linklibCtx.__deregister_frame_info(begin);
}
#endif

int
atexit(void (*function)(void))
{
	return linklibCtx.atexit(function);
}

void
exit(int status)
{
	linklibCtx.exit(status);

	OF_UNREACHABLE
}

#ifdef OF_AMIGAOS_M68K
int
snprintf(char *restrict str, size_t size, const char *restrict fmt, ...)
{
	va_list args;
	int ret;

	va_start(args, fmt);
	ret = vsnprintf(str, size, fmt, args);
	va_end(args);

	return ret;
}

int
vsnprintf(char *restrict str, size_t size, const char *restrict fmt,
    va_list args)
{
	return linklibCtx.vsnprintf(str, size, fmt, args);
}

int
__gnu_objc_personality_sj0_wrapper(int version, int actions, uint64_t *exClass,
    void *ex, void *ctx)
{
	return __gnu_objc_personality_sj0(version, actions, *exClass, ex, ctx);
}
#endif

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
	    struct ObjFWRTBase *base OBJC_M68K_REG(d0),
	    void *segList OBJC_M68K_REG(a0),
	    struct ExecBase *execBase OBJC_M68K_REG(a6));
} initTable = {
	sizeof(struct ObjFWRTBase),
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
	.rt_Version = OBJFWRT_LIB_MINOR,
	.rt_Type = NT_LIBRARY,
	.rt_Pri = 0,
	.rt_Name = (char *)OBJFWRT_AMIGA_LIB,
	.rt_IdString = (char *)OBJFWRT_AMIGA_LIB " "
	    OF_PREPROCESSOR_STRINGIFY(OBJFWRT_LIB_MINOR) "."
	    OF_PREPROCESSOR_STRINGIFY(OBJFWRT_LIB_PATCH)
	    " \xA9 2008-2025 Jonathan Schleifer",
	.rt_Init = &initTable,
#ifdef OF_MORPHOS
	.rt_Revision = OBJFWRT_LIB_PATCH,
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
