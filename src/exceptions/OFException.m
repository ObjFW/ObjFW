/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <stdlib.h>

#ifdef HAVE_DLFCN_H
# include <dlfcn.h>
#endif

#import "OFException.h"
#import "OFString.h"
#import "OFArray.h"

#import "autorelease.h"

#if defined(_WIN32) && defined(OF_HAVE_SOCKETS)
# include <errno.h>
# include <winerror.h>
#endif

/*
 * Define HAVE_DWARF_EXCEPTIONS if OBJC_ZEROCOST_EXCEPTIONS is defined, but
 * don't do so on 32-bit ARM, as it is defined there even if SjLj exceptions
 * are used.
 */
#ifndef HAVE_DWARF_EXCEPTIONS
# if defined(OBJC_ZEROCOST_EXCEPTIONS) && !defined(__ARMEL__)
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

#ifdef HAVE_DWARF_EXCEPTIONS
struct _Unwind_Context;
typedef enum {
	_URC_OK		  = 0,
	_URC_END_OF_STACK = 5
}_Unwind_Reason_Code;

struct backtrace_ctx {
	void **backtrace;
	uint_fast8_t i;
};

extern _Unwind_Reason_Code _Unwind_Backtrace(
    _Unwind_Reason_Code(*)(struct _Unwind_Context*, void*), void*);
# if defined(__arm__) || defined(__ARM__)
extern int _Unwind_VRS_Get(struct _Unwind_Context*, int, uint32_t, int, void*);
# else
extern uintptr_t _Unwind_GetIP(struct _Unwind_Context*);
# endif

static _Unwind_Reason_Code
backtrace_callback(struct _Unwind_Context *ctx, void *data)
{
	struct backtrace_ctx *bt = data;

	if (bt->i < OF_BACKTRACE_SIZE) {
# if defined(__arm__) || defined(__ARM__)
		uintptr_t ip;

		_Unwind_VRS_Get(ctx, 0, 15, 0, &ip);
		bt->backtrace[bt->i++] = (void*)(ip & ~1);
# else
		bt->backtrace[bt->i++] = (void*)_Unwind_GetIP(ctx);
# endif
		return _URC_OK;
	}

	return _URC_END_OF_STACK;
}
#endif

#if defined(_WIN32) && defined(OF_HAVE_SOCKETS)
int
of_wsaerr_to_errno(int wsaerr)
{
	switch (wsaerr) {
	case WSAEACCES:
		return EACCES;
	case WSAEADDRINUSE:
		return EADDRINUSE;
	case WSAEADDRNOTAVAIL:
		return EADDRNOTAVAIL;
	case WSAEAFNOSUPPORT:
		return EAFNOSUPPORT;
	case WSAEALREADY:
		return EALREADY;
	case WSAEBADF:
		return EBADF;
	case WSAECONNABORTED:
		return ECONNABORTED;
	case WSAECONNREFUSED:
		return ECONNREFUSED;
	case WSAECONNRESET:
		return ECONNRESET;
	case WSAEDESTADDRREQ:
		return EDESTADDRREQ;
	case WSAEDISCON:
		return EPIPE;
	case WSAEDQUOT:
		return EDQUOT;
	case WSAEFAULT:
		return EFAULT;
	case WSAEHOSTDOWN:
		return EHOSTDOWN;
	case WSAEHOSTUNREACH:
		return EHOSTUNREACH;
	case WSAEINPROGRESS:
		return EINPROGRESS;
	case WSAEINTR:
		return EINTR;
	case WSAEINVAL:
		return EINVAL;
	case WSAEISCONN:
		return EISCONN;
	case WSAELOOP:
		return ELOOP;
	case WSAEMSGSIZE:
		return EMSGSIZE;
	case WSAENAMETOOLONG:
		return ENAMETOOLONG;
	case WSAENETDOWN:
		return ENETDOWN;
	case WSAENETRESET:
		return ENETRESET;
	case WSAENETUNREACH:
		return ENETUNREACH;
	case WSAENOBUFS:
		return ENOBUFS;
	case WSAENOPROTOOPT:
		return ENOPROTOOPT;
	case WSAENOTCONN:
		return ENOTCONN;
	case WSAENOTEMPTY:
		return ENOTEMPTY;
	case WSAENOTSOCK:
		return ENOTSOCK;
	case WSAEOPNOTSUPP:
		return EOPNOTSUPP;
	case WSAEPFNOSUPPORT:
		return EPFNOSUPPORT;
	case WSAEPROCLIM:
		return EPROCLIM;
	case WSAEPROTONOSUPPORT:
		return EPROTONOSUPPORT;
	case WSAEPROTOTYPE:
		return EPROTOTYPE;
	case WSAEREMOTE:
		return EREMOTE;
	case WSAESHUTDOWN:
		return ESHUTDOWN;
	case WSAESOCKTNOSUPPORT:
		return ESOCKTNOSUPPORT;
	case WSAESTALE:
		return ESTALE;
	case WSAETIMEDOUT:
		return ETIMEDOUT;
	case WSAETOOMANYREFS:
		return ETOOMANYREFS;
	case WSAEUSERS:
		return EUSERS;
	case WSAEWOULDBLOCK:
		return EWOULDBLOCK;
	default:
		return wsaerr;
	}
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

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"An exception of type %@ occurred!", [self class]];
}

- (OFArray*)backtrace
{
#ifdef HAVE_DWARF_EXCEPTIONS
	OFMutableArray *backtrace = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	uint_fast8_t i;

	for (i = 0; i < OF_BACKTRACE_SIZE && _backtrace[i] != NULL; i++) {
# ifdef HAVE_DLADDR
		Dl_info info;

		if (dladdr(_backtrace[i], &info)) {
			OFString *frame;

			if (info.dli_sname != NULL) {
				ptrdiff_t offset = (char*)_backtrace[i] -
				    (char*)info.dli_saddr;

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
