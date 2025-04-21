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

#import "macros.h"
#import "OFPBKDF2.h"
#import "OFScrypt.h"

#include <exec/libraries.h>

#ifdef OF_MORPHOS
# include <ppcinline/macros.h>
# define OF_M68K_ARG(type, name, reg) type name = (type)REG_##reg;
#else
# define OF_M68K_ARG(type, name, reg)		\
	register type reg_##name __asm__(#reg);	\
	type name = reg_##name;
#endif

#ifdef OF_MORPHOS
# include <setjmp.h>
#endif

typedef void (*OFSignalHandler)(int);

struct OFLibC {
	/*
	 * Needed by the runtime. Some of them are also used by ObjFW, but we
	 * need all of them to pass them along to the runtime.
	 */
	void *_Nullable (*_Nonnull malloc)(size_t);
	void *_Nullable (*_Nonnull calloc)(size_t, size_t);
	void *_Nullable (*_Nonnull realloc)(void *_Nullable, size_t);
	void (*_Nonnull free)(void *_Nullable);
	void (*_Nonnull abort)(void);
#ifdef HAVE_SJLJ_EXCEPTIONS
	int (*_Nonnull _Unwind_SjLj_RaiseException)(void *_Nonnull);
#else
	int (*_Nonnull _Unwind_RaiseException)(void *_Nonnull);
#endif
	void (*_Nonnull _Unwind_DeleteException)(void *_Nonnull);
	void *_Nullable (*_Nonnull _Unwind_GetLanguageSpecificData)(
	    void *_Nonnull);
	uintptr_t (*_Nonnull _Unwind_GetRegionStart)(void *_Nonnull);
	uintptr_t (*_Nonnull _Unwind_GetDataRelBase)(void *_Nonnull);
	uintptr_t (*_Nonnull _Unwind_GetTextRelBase)(void *_Nonnull);
	uintptr_t (*_Nonnull _Unwind_GetIP)(void *_Nonnull);
	uintptr_t (*_Nonnull _Unwind_GetGR)(void *_Nonnull, int);
	void (*_Nonnull _Unwind_SetIP)(void *_Nonnull, uintptr_t);
	void (*_Nonnull _Unwind_SetGR)(void *_Nonnull, int, uintptr_t);
#ifdef HAVE_SJLJ_EXCEPTIONS
	void (*_Nonnull _Unwind_SjLj_Resume)(void *_Nonnull);
#else
	void (*_Nonnull _Unwind_Resume)(void *_Nonnull);
#endif
#ifdef OF_AMIGAOS_M68K
	void (*_Nonnull __register_frame_info)(const void *_Nonnull,
	    void *_Nonnull);
	void *_Nullable (*_Nonnull __deregister_frame_info)(
	    const void *_Nonnull);
#endif
#ifdef OF_MORPHOS
	void (*_Nonnull __register_frame)(void *_Nonnull);
	void (*_Nonnull __deregister_frame)(void *_Nonnull);
#endif
	int *_Nonnull (*_Nonnull errNo)(void);

	/* Needed only by ObjFW. */
#ifdef OF_MORPHOS
	int (*_Nonnull vasprintf)(char *_Nonnull *_Nullable restrict,
	    const char *_Nonnull restrict, va_list);
#else
	int (*_Nonnull vsnprintf)(char *_Nonnull restrict, size_t,
	    const char *_Nonnull restrict, va_list);
#endif
	float (*_Nonnull strtof)(const char *_Nonnull,
	    char *_Nullable *_Nullable);
	double (*_Nonnull strtod)(const char *_Nonnull,
	    char *_Nullable *_Nullable);
#ifdef OF_MORPHOS
	struct tm *(*_Nonnull gmtime_r)(const time_t *_Nonnull,
	    struct tm *_Nonnull);
	struct tm *(*_Nonnull localtime_r)(const time_t *_Nonnull,
	    struct tm *_Nonnull);
#endif
	time_t (*_Nonnull mktime)(struct tm *_Nonnull);
	int (*_Nonnull gettimeofday)(struct timeval *_Nonnull,
	    struct timezone *_Nullable);
	size_t (*_Nonnull strftime)(char *_Nonnull, size_t,
	    const char *_Nonnull, const struct tm *_Nonnull);
	void (*_Nonnull exit)(int);
	int (*_Nonnull atexit)(void (*_Nonnull)(void));
	OFSignalHandler _Nullable (*_Nonnull signal)(int, OFSignalHandler _Nullable);
	char *_Nullable (*_Nonnull setlocale)(int, const char *_Nullable);
	int (*_Nonnull _Unwind_Backtrace)(int (*_Nonnull)(void *_Nonnull,
	    void *_Null_unspecified), void *_Null_unspecified);
#ifdef OF_MORPHOS
	int (*_Nonnull setjmp)(jmp_buf);
	void __dead2 (*_Nonnull longjmp)(jmp_buf, int);
#endif
};

extern bool OFInit(unsigned int version, struct OFLibC *_Nonnull libC,
    struct Library *_Nonnull RTBase);
extern unsigned long *OFHashSeedRef(void);
extern void OFPBKDF2Wrapper(const OFPBKDF2Parameters *_Nonnull parameters);
extern void OFScryptWrapper(const OFScryptParameters *_Nonnull parameters);
