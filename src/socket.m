/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#ifdef OF_NINTENDO_3DS
# include <malloc.h>  /* For memalign() */
#endif

#include <errno.h>

#import "OFException.h"  /* For some E* -> WSAE* defines */
#import "OFInvalidArgumentException.h"
#import "OFLockFailedException.h"
#import "OFUnlockFailedException.h"

#import "socket.h"
#ifdef OF_HAVE_THREADS
# include "threading.h"
#endif

#ifdef OF_NINTENDO_3DS
# include <3ds/types.h>
# include <3ds/services/soc.h>
#endif

#ifdef OF_HAVE_THREADS
static of_mutex_t mutex;
#endif
static bool initSuccessful = false;

static void
init(void)
{
#if defined(OF_WINDOWS)
	WSADATA wsa;

	if (WSAStartup(MAKEWORD(2, 0), &wsa))
		return;
#elif defined(OF_WII)
	if (net_init() < 0)
		return;
#elif defined(OF_NINTENDO_3DS)
	void *ctx;

	if ((ctx = memalign(0x1000, 0x100000)) == NULL)
		return;

	if (socInit(ctx, 0x100000) != 0)
		return;

	atexit((void (*)(void))socExit);
#endif

#ifdef OF_HAVE_THREADS
	if (!of_mutex_new(&mutex))
		return;

# ifdef OF_WII
	if (!of_spinlock_new(&spinlock))
		return;
# endif
#endif

	initSuccessful = true;
}

bool
of_socket_init()
{
#ifdef OF_HAVE_THREADS
	static of_once_t onceControl = OF_ONCE_INIT;
	of_once(&onceControl, init);
#else
	static bool initialized = false;
	if (!initialized) {
		init();
		initialized = true;
	}
#endif

	return initSuccessful;
}

int
of_socket_errno()
{
#ifndef OF_WINDOWS
	return errno;
#else
	switch (WSAGetLastError()) {
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
	}

	return 0;
#endif
}

#ifndef OF_WII
int
of_getsockname(of_socket_t sock, struct sockaddr *restrict addr,
    socklen_t *restrict addrLen)
{
	int ret;

# ifdef OF_HAVE_THREADS
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];

# endif

	ret = getsockname(sock, addr, addrLen);

# ifdef OF_HAVE_THREADS
	if (!of_mutex_unlock(&mutex))
		@throw [OFUnlockFailedException exception];
# endif

	return ret;
}
#endif
