/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "macros.h"

#ifdef OF_MORPHOS
# include <ppcinline/macros.h>
# define OBJC_M68K_ARG(type, name, reg) type name = (type)REG_##reg;
#else
# define OBJC_M68K_ARG(type, name, reg)	\
	register type reg_##name __asm__(#reg);	\
	type name = reg_##name;
#endif

struct objc_libc {
	void *_Nullable (*_Nonnull malloc)(size_t);
	void *_Nullable (*_Nonnull calloc)(size_t, size_t);
	void *_Nullable (*_Nonnull realloc)(void *_Nullable, size_t);
	void (*_Nonnull free)(void *_Nullable);
	int (*_Nonnull vfprintf)(FILE *_Nonnull, const char *_Nonnull, va_list);
	int (*_Nonnull fflush)(FILE *_Nonnull);
	void (*_Nonnull abort)(void);
# ifdef HAVE_SJLJ_EXCEPTIONS
	int (*_Nonnull _Unwind_SjLj_RaiseException)(void *_Nonnull);
# else
	int (*_Nonnull _Unwind_RaiseException)(void *_Nonnull);
# endif
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
# ifdef HAVE_SJLJ_EXCEPTIONS
	void (*_Nonnull _Unwind_SjLj_Resume)(void *_Nonnull);
# else
	void (*_Nonnull _Unwind_Resume)(void *_Nonnull);
# endif
# ifdef OF_AMIGAOS_M68K
	void (*_Nonnull __register_frame_info)(const void *_Nonnull,
	    void *_Nonnull);
	void *(*_Nonnull __deregister_frame_info)(const void *_Nonnull);
# endif
# ifdef OF_MORPHOS
	void (*_Nonnull __register_frame)(void *_Nonnull);
	void (*_Nonnull __deregister_frame)(void *_Nonnull);
# endif
	int *_Nonnull (*_Nonnull get_errno)(void);
};

extern bool objc_init(unsigned int, struct objc_libc *_Nonnull,
    FILE *_Nonnull *_Nonnull);
