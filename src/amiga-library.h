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

#include <exec/libraries.h>

#include <setjmp.h>

typedef void (*sighandler_t)(int);

struct OFLibC {
	void *_Nullable (*_Nonnull malloc)(size_t);
	void *_Nullable (*_Nonnull calloc)(size_t, size_t);
	void *_Nullable (*_Nonnull realloc)(void *_Nullable, size_t);
	void (*_Nonnull free)(void *_Nullable);
	void (*_Nonnull abort)(void);
	void (*_Nonnull __register_frame)(void *_Nonnull);
	void (*_Nonnull __deregister_frame)(void *_Nonnull);
	int *_Nonnull (*_Nonnull errNo)(void);
	int (*_Nonnull vasprintf)(char *_Nonnull *_Nullable restrict,
	    const char *_Nonnull restrict, va_list);
	float (*_Nonnull strtof)(const char *_Nonnull,
	    char *_Nullable *_Nullable);
	double (*_Nonnull strtod)(const char *_Nonnull,
	    char *_Nullable *_Nullable);
	struct tm *(*_Nonnull gmtime_r)(const time_t *_Nonnull,
	    struct tm *_Nonnull);
	struct tm *(*_Nonnull localtime_r)(const time_t *_Nonnull,
	    struct tm *_Nonnull);
	time_t (*_Nonnull mktime)(struct tm *_Nonnull);
	int (*_Nonnull gettimeofday)(struct timeval *_Nonnull,
	    struct timezone *_Nullable);
	size_t (*_Nonnull strftime)(char *_Nonnull, size_t,
	    const char *_Nonnull, const struct tm *_Nonnull);
	void (*_Nonnull exit)(int);
	int (*_Nonnull atexit)(void (*_Nonnull)(void));
	sighandler_t _Nullable (*_Nonnull signal)(int, sighandler_t _Nullable);
	char *_Nullable (*_Nonnull setlocale)(int, const char *_Nullable);
	int (*_Nonnull _Unwind_Backtrace)(int (*_Nonnull)(void *_Nonnull,
	    void *_Null_unspecified), void *_Null_unspecified);
	int (*_Nonnull setjmp)(jmp_buf);
	void __dead2 (*_Nonnull longjmp)(jmp_buf, int);
};

extern bool OFInit(unsigned int version, struct OFLibC *_Nonnull libC,
    struct Library *_Nonnull RTBase);
extern unsigned long *OFHashSeedRef(void);
