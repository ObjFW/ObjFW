/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_DLFCN_H
# include <dlfcn.h>
#endif

#import "OFException.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFLocalization.h"

#import "OFInitializationFailedException.h"
#import "OFLockFailedException.h"
#import "OFUnlockFailedException.h"

#if !defined(HAVE_STRERROR_R) && defined(OF_HAVE_THREADS)
# import "threading.h"
#endif

#if defined(OF_WINDOWS) && defined(OF_HAVE_SOCKETS)
# include <winerror.h>
#endif

/*
 * Define HAVE_DWARF_EXCEPTIONS if OBJC_ZEROCOST_EXCEPTIONS is defined, but
 * don't do so on iOS, as it is defined there even if SjLj exceptions are used.
 */
#ifndef HAVE_DWARF_EXCEPTIONS
# if defined(OBJC_ZEROCOST_EXCEPTIONS) && !defined(OF_IOS)
#  define HAVE_DWARF_EXCEPTIONS
# endif
#endif

/*
 * Define HAVE_DWARF_EXCEPTIONS if HAVE_SEH_EXCEPTIONS is defined, as SEH
 * exceptions are implemented as a wrapper around DWARF exceptions.
 */
#ifdef HAVE_SEH_EXCEPTIONS
# define HAVE_DWARF_EXCEPTIONS
#endif

#if defined(OF_ARM) && !defined(__ARM_DWARF_EH__)
# define HAVE_ARM_EHABI_EXCEPTIONS
#endif

#ifdef HAVE_DWARF_EXCEPTIONS
struct _Unwind_Context;
typedef enum {
	_URC_OK		  = 0,
	_URC_END_OF_STACK = 5
}_Unwind_Reason_Code;

struct backtrace_ctx {
	void **backtrace;
	uint8_t i;
};

extern _Unwind_Reason_Code _Unwind_Backtrace(
    _Unwind_Reason_Code (*)(struct _Unwind_Context *, void *), void *);
# ifndef HAVE_ARM_EHABI_EXCEPTIONS
extern uintptr_t _Unwind_GetIP(struct _Unwind_Context *);
# else
extern int _Unwind_VRS_Get(struct _Unwind_Context *, int, uint32_t, int,
    void *);
# endif
#endif

#if !defined(HAVE_STRERROR_R) && defined(OF_HAVE_THREADS)
static of_mutex_t mutex;

OF_CONSTRUCTOR()
{
	if (!of_mutex_new(&mutex))
		@throw [OFInitializationFailedException exception];
}
#endif

OFString *
of_strerror(int errNo)
{
	OFString *ret;
#ifdef HAVE_STRERROR_R
	char buffer[256];
#endif

#ifdef OF_WINDOWS
	/*
	 * These were translated from WSAE* errors to errno and thus Win32's
	 * strerror_r() does not know about them.
	 *
	 * FIXME: These could have better descriptions!
	 */
	switch (errNo) {
	case EADDRINUSE:
		return @"EADDRINUSE";
	case EADDRNOTAVAIL:
		return @"EADDRNOTAVAIL";
	case EAFNOSUPPORT:
		return @"EAFNOSUPPORT";
	case EALREADY:
		return @"EALREADY";
	case ECONNABORTED:
		return @"ECONNABORTED";
	case ECONNREFUSED:
		return @"ECONNREFUSED";
	case ECONNRESET:
		return @"ECONNRESET";
	case EDESTADDRREQ:
		return @"EDESTADDRREQ";
	case EDQUOT:
		return @"EDQUOT";
	case EHOSTDOWN:
		return @"EHOSTDOWN";
	case EHOSTUNREACH:
		return @"EHOSTUNREACH";
	case EINPROGRESS:
		return @"EINPROGRESS";
	case EISCONN:
		return @"EISCONN";
	case ELOOP:
		return @"ELOOP";
	case EMSGSIZE:
		return @"EMSGSIZE";
	case ENETDOWN:
		return @"ENETDOWN";
	case ENETRESET:
		return @"ENETRESET";
	case ENETUNREACH:
		return @"ENETUNREACH";
	case ENOBUFS:
		return @"ENOBUFS";
	case ENOPROTOOPT:
		return @"ENOPROTOOPT";
	case ENOTCONN:
		return @"ENOTCONN";
	case ENOTSOCK:
		return @"ENOTSOCK";
	case EOPNOTSUPP:
		return @"EOPNOTSUPP";
	case EPFNOSUPPORT:
		return @"EPFNOSUPPORT";
	case EPROCLIM:
		return @"EPROCLIM";
	case EPROTONOSUPPORT:
		return @"EPROTONOSUPPORT";
	case EPROTOTYPE:
		return @"EPROTOTYPE";
	case EREMOTE:
		return @"EREMOTE";
	case ESHUTDOWN:
		return @"ESHUTDOWN";
	case ESOCKTNOSUPPORT:
		return @"ESOCKTNOSUPPORT";
	case ESTALE:
		return @"ESTALE";
	case ETIMEDOUT:
		return @"ETIMEDOUT";
	case ETOOMANYREFS:
		return @"ETOOMANYREFS";
	case EUSERS:
		return @"EUSERS";
	case EWOULDBLOCK:
		return @"EWOULDBLOCK";
	}
#endif

#if defined(HAVE_STRERROR_R) && defined(_GNU_SOURCE)
	/* glibc uses a different strerror_r when _GNU_SOURCE is defined */
	char *string;

	if ((string = strerror_r(errNo, buffer, 256)) == NULL)
		return @"Unknown error (strerror_r failed)";

	ret = [OFString stringWithCString: string
				 encoding: [OFLocalization encoding]];
#elif defined(HAVE_STRERROR_R)
	if (strerror_r(errNo, buffer, 256) != 0)
		return @"Unknown error (strerror_r failed)";

	ret = [OFString stringWithCString: buffer
				 encoding: [OFLocalization encoding]];
#else
# ifdef OF_HAVE_THREADS
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];

	@try {
# endif
		ret = [OFString
		    stringWithCString: strerror(errNo)
			     encoding: [OFLocalization encoding]];
# ifdef OF_HAVE_THREADS
	} @finally {
		if (!of_mutex_unlock(&mutex))
			@throw [OFUnlockFailedException exception];
	}
# endif
#endif

	return ret;
}

#ifdef HAVE_DWARF_EXCEPTIONS
static _Unwind_Reason_Code
backtrace_callback(struct _Unwind_Context *ctx, void *data)
{
	struct backtrace_ctx *bt = data;

	if (bt->i < OF_BACKTRACE_SIZE) {
# ifndef HAVE_ARM_EHABI_EXCEPTIONS
		bt->backtrace[bt->i++] = (void *)_Unwind_GetIP(ctx);
# else
		uintptr_t ip;

		_Unwind_VRS_Get(ctx, 0, 15, 0, &ip);
		bt->backtrace[bt->i++] = (void *)(ip & ~1);
# endif
		return _URC_OK;
	}

	return _URC_END_OF_STACK;
}
#endif

@implementation OFException
+ (instancetype)exception
{
	return [[[self alloc] init] autorelease];
}

#ifdef HAVE_DWARF_EXCEPTIONS
- init
{
	struct backtrace_ctx ctx;

	self = [super init];

	ctx.backtrace = _backtrace;
	ctx.i = 0;
	_Unwind_Backtrace(backtrace_callback, &ctx);

	return self;
}
#endif

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"An exception of type %@ occurred!", [self class]];
}

- (OFArray *)backtrace
{
#ifdef HAVE_DWARF_EXCEPTIONS
	OFMutableArray *backtrace = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();

	for (uint8_t i = 0;
	    i < OF_BACKTRACE_SIZE && _backtrace[i] != NULL; i++) {
# ifdef HAVE_DLADDR
		Dl_info info;

		if (dladdr(_backtrace[i], &info)) {
			OFString *frame;

			if (info.dli_sname != NULL) {
				ptrdiff_t offset = (char *)_backtrace[i] -
				    (char *)info.dli_saddr;

				frame = [OFString stringWithFormat:
				    @"%p <%s+%td> at %s",
				    _backtrace[i], info.dli_sname, offset,
				    info.dli_fname];
			} else
				frame = [OFString stringWithFormat:
				    @"%p <?" @"?> at %s",
				    _backtrace[i], info.dli_fname];

			[backtrace addObject: frame];
		} else
# endif
			[backtrace addObject:
			    [OFString stringWithFormat: @"%p", _backtrace[i]]];
	}

	objc_autoreleasePoolPop(pool);

	[backtrace makeImmutable];

	return backtrace;
#else
	return nil;
#endif
}
@end
