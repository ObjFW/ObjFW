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

#define USE_INLINE_STDARG
#define Class IntuitionClass
#include <proto/exec.h>
#include <proto/intuition.h>
#undef Class

#include <stdio.h>
#include <stdlib.h>

#if defined(OF_MORPHOS)
# include <constructor.h>
#elif defined(OF_AMIGAOS_M68K)
# include <stabs.h>
#endif

#ifdef OF_MORPHOS
extern int _Unwind_RaiseException(void *);
#else
extern int _Unwind_SjLj_RaiseException(void *);
#endif
extern void _Unwind_DeleteException(void *);
extern void *_Unwind_GetLanguageSpecificData(void *);
extern uintptr_t _Unwind_GetRegionStart(void *);
extern uintptr_t _Unwind_GetDataRelBase(void *);
extern uintptr_t _Unwind_GetTextRelBase(void *);
extern uintptr_t _Unwind_GetIP(void *);
extern uintptr_t _Unwind_GetGR(void *, int);
extern void _Unwind_SetIP(void *, uintptr_t);
extern void _Unwind_SetGR(void *, int, uintptr_t);
#ifdef OF_MORPHOS
extern void _Unwind_Resume(void *);
extern void __register_frame(void *);
extern void __deregister_frame(void *);
#else
extern void _Unwind_SjLj_Resume(void *);
extern void __register_frame_info(const void *, void *);
extern void *__deregister_frame_info(const void *);
#endif

void *__objc_class_name_Protocol;

#ifndef OBJC_AMIGA_LIB
extern bool objc_init(struct objc_linklib_context *ctx);

struct Library *ObjFWRTBase;

static void
error(const char *string, ULONG arg)
{
	struct Library *IntuitionBase = OpenLibrary("intuition.library", 0);

	if (IntuitionBase != NULL) {
		struct EasyStruct easy = {
			.es_StructSize = sizeof(easy),
			.es_Flags = 0,
			.es_Title = (void *)NULL,
			.es_TextFormat = (void *)string,
			(void *)"OK"
		};

		EasyRequest(NULL, &easy, NULL, arg);

		CloseLibrary(IntuitionBase);
	}

	exit(EXIT_FAILURE);
}

static void __attribute__((__used__))
ctor(void)
{
	static bool initialized = false;
	struct objc_linklib_context ctx = {
		.version = 1,
		.malloc = malloc,
		.calloc = calloc,
		.realloc = realloc,
		.free = free,
# ifdef OF_MORPHOS
		._Unwind_RaiseException = _Unwind_RaiseException,
# else
		._Unwind_SjLj_RaiseException = _Unwind_SjLj_RaiseException,
# endif
		._Unwind_DeleteException = _Unwind_DeleteException,
		._Unwind_GetLanguageSpecificData =
		    _Unwind_GetLanguageSpecificData,
		._Unwind_GetRegionStart = _Unwind_GetRegionStart,
		._Unwind_GetDataRelBase = _Unwind_GetDataRelBase,
		._Unwind_GetTextRelBase = _Unwind_GetTextRelBase,
		._Unwind_GetIP = _Unwind_GetIP,
		._Unwind_GetGR = _Unwind_GetGR,
		._Unwind_SetIP = _Unwind_SetIP,
		._Unwind_SetGR = _Unwind_SetGR,
# ifdef OF_MORPHOS
		._Unwind_Resume = _Unwind_Resume,
		.__register_frame = __register_frame,
		.__deregister_frame = __deregister_frame,
# else
		._Unwind_SjLj_Resume = _Unwind_SjLj_Resume,
		.__register_frame_info = __register_frame_info,
		.__deregister_frame_info = __deregister_frame_info,
# endif
		.atexit = atexit,
		.exit = exit,
# ifdef OF_AMIGAOS_M68K
		.vsnprintf = vsnprintf,
# endif
	};

	if (initialized)
		return;

	if ((ObjFWRTBase = OpenLibrary(OBJFWRT_AMIGA_LIB,
	    OBJFWRT_LIB_MINOR)) == NULL)
		error("Failed to open " OBJFWRT_AMIGA_LIB " version %lu!",
		    OBJFWRT_LIB_MINOR);

	if (!objc_init(&ctx))
		error("Failed to initialize " OBJFWRT_AMIGA_LIB "!", 0);

	initialized = true;
}

static void __attribute__((__used__))
dtor(void)
{
	CloseLibrary(ObjFWRTBase);
}

# ifdef OF_MORPHOS
CONSTRUCTOR_P(ObjFWRT, 4000)
{
	ctor();

	return 0;
}

DESTRUCTOR_P(ObjFWRT, 0)
{
	dtor();
}
# elif defined(OF_AMIGAOS_M68K)
ADD2INIT(ctor, -5)
ADD2EXIT(dtor, -5)
# endif
#endif

#ifdef OF_AMIGAOS_M68K
int
__gnu_objc_personality_sj0(int version, int actions, uint64_t exClass,
    void *ex, void *ctx)
{
	return __gnu_objc_personality_sj0(version, action, &exClass, ex, ctx);
}
#endif
