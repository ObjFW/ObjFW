/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "macros.h"

#import "amiga-library.h"
#import "amiga-library-glue.h"

#import "runtime/private.h"

#define Class IntuitionClass
#include <exec/execbase.h>
#include <exec/libraries.h>
#include <exec/nodes.h>
#include <exec/resident.h>
#include <proto/exec.h>
#undef Class

#define DATA_OFFSET 0x8000

/* This always needs to be the first thing in the file. */
int
__start(void)
{
	return -1;
}

const char *VER = "$VER: " OBJFWTLS_AMIGA_LIB " "
    OF_PREPROCESSOR_STRINGIFY(OBJFWTLS_LIB_MINOR) "."
    OF_PREPROCESSOR_STRINGIFY(OBJFWTLS_LIB_PATCH)
    " (" BUILD_DATE ") \xA9 2008-2026 Jonathan Schleifer";

struct ObjFWTLSBase {
	struct Library library;
	void *segList;
	struct ObjFWTLSBase *parent;
	char *dataSeg;
	bool initialized;
} *ObjFWTLSBase;

const ULONG __abox__ = 1;
struct ExecBase *SysBase;
struct OFTLSLinklibContext linklibCtx;
extern struct Library *ObjFWRTBase, *ObjFWBase, *OpenSSL4Base;

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
	    : "=r" (dataSeg)
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
	    : "=r" (dataSize)
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
	    : "=r" (dataDataRelocs)
	);

	return dataDataRelocs;
}

static struct Library *
libInit(struct ObjFWTLSBase *base, void *segList, struct ExecBase *sysBase)
{
	__asm__ __volatile__ (
	    "lis	%%r9, SysBase@ha\n\t"
	    "stw	%0, SysBase@l(%%r9)"
	    :: "r" (sysBase) : "r9"
	);

	base->segList = segList;
	base->parent = NULL;
	base->dataSeg = getDataSeg();

	return &base->library;
}

struct Library *__saveds
libOpen(void)
{
	struct ObjFWTLSBase *base = (struct ObjFWTLSBase *)REG_A6, *child;
	size_t dataSize, *dataDataRelocs;
	ptrdiff_t displacement;

	if (base->parent != NULL)
		return NULL;

	base->library.lib_OpenCnt++;
	base->library.lib_Flags &= ~LIBF_DELEXP;

	if ((child = AllocMem(base->library.lib_NegSize +
	    base->library.lib_PosSize, MEMF_ANY)) == NULL) {
		base->library.lib_OpenCnt--;
		return NULL;
	}

	CopyMem((char *)base - base->library.lib_NegSize, child,
	    base->library.lib_NegSize + base->library.lib_PosSize);

	child = (struct ObjFWTLSBase *)
	    ((char *)child + base->library.lib_NegSize);
	child->library.lib_OpenCnt = 1;
	child->parent = base;

	CacheClearE((char *)child - child->library.lib_NegSize,
	    child->library.lib_NegSize, CACRF_ClearI);

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
expunge(struct ObjFWTLSBase *base, struct ExecBase *sysBase)
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
	struct ObjFWTLSBase *base = (struct ObjFWTLSBase *)REG_A6;

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
	struct ObjFWTLSBase *base = (struct ObjFWTLSBase *)REG_A6;

	if (base->initialized) {
		void *frame;
		uintptr_t *iter;

		__asm__ (
		    "lis	%0, __EH_FRAME_BEGIN__@ha\n\t"
		    "la		%0, __EH_FRAME_BEGIN__@l(%0)\n\t"
		    "lis	%1, __DTOR_LIST__@ha\n\t"
		    "la		%1, __DTOR_LIST__@l(%1)\n\t"
		    : "=r" (frame), "=r" (iter)
		);

		for (; *iter != 0; iter++) {
			void (*dtor)(void) = (void (*)(void))*iter;
			dtor();
		}

		linklibCtx.__deregister_frame(frame);
	}

	if (base->parent != NULL) {
		struct ObjFWTLSBase *parent = base->parent;

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
OFTLSInit(unsigned int version, struct OFTLSLinklibContext *ctx)
{
	register struct ObjFWTLSBase *r12 __asm__("r12");
	struct ObjFWTLSBase *base = r12;
	void *frame;
	uintptr_t *iter, *iter0;

	if (version > 1)
		return false;

	if (base->initialized)
		return true;

	CopyMem(ctx, &linklibCtx, sizeof(linklibCtx));

	__asm__ (
	    "lis	%0, __EH_FRAME_BEGIN__@ha\n\t"
	    "la		%0, __EH_FRAME_BEGIN__@l(%0)\n\t"
	    "lis	%1, __CTOR_LIST__@ha\n\t"
	    "la		%1, __CTOR_LIST__@l(%1)\n\t"
	    : "=r" (frame), "=r" (iter0)
	);

	linklibCtx.__register_frame(frame);

	ObjFWRTBase = ctx->ObjFWRTBase;
	ObjFWBase = ctx->ObjFWBase;
	ObjFWTLSBase = base;

	for (iter = iter0; *iter != 0; iter++);

	while (iter > iter0) {
		void (*ctor)(void) = (void (*)(void))*--iter;
		ctor();
	}

	base->initialized = true;

	return true;
}


void
__objc_exec_class(struct objc_module *module)
{
	objc_createLibraryTrampolinesForModule(module,
	    (struct Library *)ObjFWTLSBase);

	__asm__ __volatile__ (
	    "mr		%%r12, %0"
	    :: "r" (ObjFWRTBase) : "r12"
	);

	__extension__ ((void (*)(struct objc_module *))*(void **)(
	    ((uintptr_t)ObjFWRTBase) - 34))(module);
}

int *
__errno_location(void)
{
	return linklibCtx.__errno_location();
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

int
_Unwind_RaiseException(void *ex)
{
	return linklibCtx._Unwind_RaiseException(ex);
}

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

void
_Unwind_Resume(void *ex)
{
	linklibCtx._Unwind_Resume(ex);
}

int
_Unwind_Backtrace(int (*callback)(void *, void *), void *data)
{
	return linklibCtx._Unwind_Backtrace(callback, data);
}

int
atexit(void (*function)(void))
{
	return linklibCtx.atexit(function);
}

void
abort(void)
{
	linklibCtx.abort();

	OF_UNREACHABLE
}

FILE *
fopen(const char *restrict path, const char *restrict mode)
{
	return linklibCtx.fopen(path, mode);
}

size_t
fread(void *restrict ptr, size_t size, size_t count, FILE *restrict fp)
{
	return linklibCtx.fread(ptr, size, count, fp);
}

size_t
fwrite(const void *restrict ptr, size_t size, size_t count, FILE *restrict fp)
{
	return linklibCtx.fwrite(ptr, size, count, fp);
}

char *
fgets(char *restrict str, int size, FILE *restrict fp)
{
	return linklibCtx.fgets(str, size, fp);
}

int
fflush(FILE *fp)
{
	return linklibCtx.fflush(fp);
}

int
fseek(FILE *fp, long offset, int whence)
{
	return linklibCtx.fseek(fp, offset, whence);
}

long
ftell(FILE *fp)
{
	return linklibCtx.ftell(fp);
}

int
fclose(FILE *fp)
{
	return linklibCtx.fclose(fp);
}

ssize_t
read(int fd, void *buf, size_t size)
{
	return linklibCtx.read(fd, buf, size);
}

ssize_t
write(int fd, const void *buf, size_t size)
{
	return linklibCtx.write(fd, buf, size);
}

off_t
lseek(int fd, off_t offset, int whence)
{
	return linklibCtx.lseek(fd, offset, whence);
}

int
close(int fd)
{
	return linklibCtx.close(fd);
}

struct Library *
_fetch_OpenSSL4Base(void)
{
	return OpenSSL4Base;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
static const CONST_APTR functionTable[]
    __attribute__((__section__(".rodata"))) = {
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

static const struct {
	ULONG dataSize;
	const CONST_APTR *functionTable;
	ULONG *dataTable;
	struct Library *(*initFunc)(struct ObjFWTLSBase *base, void *segList,
	    struct ExecBase *execBase);
} initTable __attribute__((__section__(".rodata"))) = {
	sizeof(struct ObjFWTLSBase),
	functionTable,
	NULL,
	libInit
};

const struct Resident resident __attribute__((__section__(".rodata"))) = {
	.rt_MatchWord = RTC_MATCHWORD,
	.rt_MatchTag = (struct Resident *)&resident,
	.rt_EndSkip = (struct Resident *)&resident + 1,
	.rt_Flags = RTF_AUTOINIT | RTF_PPC | RTF_EXTENDED,
	.rt_Version = OBJFWTLS_LIB_MINOR,
	.rt_Type = NT_LIBRARY,
	.rt_Pri = 0,
	.rt_Name = (char *)OBJFWTLS_AMIGA_LIB,
	.rt_IdString = (char *)OBJFWTLS_AMIGA_LIB " "
	    OF_PREPROCESSOR_STRINGIFY(OBJFWTLS_LIB_MINOR) "."
	    OF_PREPROCESSOR_STRINGIFY(OBJFWTLS_LIB_PATCH)
	    " (" BUILD_DATE ") \xA9 2008-2026 Jonathan Schleifer",
	.rt_Init = (APTR)&initTable,
	.rt_Revision = OBJFWTLS_LIB_PATCH,
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
    ".section .dtors, \"aw\"\n"
    ".globl __DTOR_LIST__\n"
    ".type __DTOR_LIST__, @object\n"
    "__DTOR_LIST__:\n"
    ".section .text"
);
