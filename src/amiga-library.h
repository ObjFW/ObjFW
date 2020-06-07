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

#if defined(OF_COMPILING_AMIGA_LIBRARY) || defined(OF_COMPILING_AMIGA_LINKLIB)
struct of_libc {
	void *_Nullable (*_Nonnull malloc)(size_t);
	void *_Nullable (*_Nonnull calloc)(size_t, size_t);
	void *_Nullable (*_Nonnull realloc)(void *_Nullable, size_t);
	void (*_Nonnull free)(void *_Nullable);
	int (*_Nonnull vfprintf)(FILE *_Nonnull restrict,
	    const char *restrict _Nonnull, va_list);
	int (*_Nonnull vsnprintf)(const char *_Nonnull restrict, size_t,
	    const char *_Nonnull restrict, va_list);
	void (*_Nonnull exit)(int);
	void (*_Nonnull abort)(void);
	char *_Nullable (*_Nonnull setlocale)(int, const char *_Nullable);
	void (*_Nonnull __register_frame_info)(const void *_Nonnull,
	    void *_Nonnull);
	void *_Nullable (*_Nonnull __deregister_frame_info)(
	    const void *_Nonnull);
};

extern bool of_init(unsigned int version, struct of_libc *libc_, FILE *stderr_);
#endif
