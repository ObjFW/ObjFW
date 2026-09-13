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

#import "macros.h"

#include <exec/libraries.h>

#include <setjmp.h>

#define OFTLSLibraryTrampolineSize 6

struct OFTLSLinklibContext {
	struct Library *ObjFWRTBase;
	struct Library *ObjFWBase;
	int *_Nonnull (*_Nonnull __errno_location)(void);
	void *_Nullable (*_Nonnull malloc)(size_t);
	void *_Nullable (*_Nonnull calloc)(size_t, size_t);
	void *_Nullable (*_Nonnull realloc)(void *_Nullable, size_t);
	void (*_Nonnull free)(void *_Nullable);
	int (*_Nonnull _Unwind_RaiseException)(void *_Nonnull);
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
	void (*_Nonnull _Unwind_Resume)(void *_Nonnull);
	int (*_Nonnull _Unwind_Backtrace)(int (*_Nonnull)(void *_Nonnull,
	    void *_Null_unspecified), void *_Null_unspecified);
	void (*_Nonnull __register_frame)(void *_Nonnull);
	void (*_Nonnull __deregister_frame)(void *_Nonnull);
	int (*_Nonnull atexit)(void (*_Nonnull)(void));
	void (*_Nonnull abort)(void);
	FILE *(*_Nonnull fopen)(const char *restrict _Nonnull,
	    const char *restrict _Nonnull);
	size_t (*_Nonnull fread)(void *restrict _Nonnull, size_t, size_t,
	    FILE *restrict _Nonnull);
	size_t (*_Nonnull fwrite)(const void *restrict _Nonnull, size_t, size_t,
	    FILE *restrict _Nonnull);
	char *(*_Nonnull fgets)(char *restrict _Nonnull, int,
	    FILE *restrict _Nonnull);
	int (*_Nonnull fflush)(FILE *_Nonnull);
	int (*_Nonnull fseek)(FILE *_Nonnull, long, int);
	long (*_Nonnull ftell)(FILE *_Nonnull);
	int (*_Nonnull fclose)(FILE *_Nonnull);
	ssize_t (*_Nonnull read)(int, void *_Nonnull, size_t);
	ssize_t (*_Nonnull write)(int, const void *_Nonnull, size_t);
	off_t (*_Nonnull lseek)(int, off_t, int);
	int (*_Nonnull close)(int);
};

extern bool OFTLSInit(unsigned int version,
    struct OFTLSLinklibContext *_Nonnull ctx);
