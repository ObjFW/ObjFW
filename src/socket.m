/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#include <errno.h>

/* For some E* -> WSAE* defines */
#import "OFException.h"

#import "socket.h"
#ifdef OF_HAVE_THREADS
# include "threading.h"

static of_once_t onceControl = OF_ONCE_INIT;
#endif
static bool initialized = false;

static void
init(void)
{
#if defined(_WIN32)
	WSADATA wsa;

	if (WSAStartup(MAKEWORD(2, 0), &wsa))
		return;
#elif defined(__wii__)
	if (net_init() < 0)
		return;
#endif

	initialized = true;
}

bool
of_socket_init()
{
#ifdef OF_HAVE_THREADS
	of_once(&onceControl, init);
#else
	if (!initialized)
		init();
#endif

	return initialized;
}

int
of_socket_errno()
{
#ifndef _WIN32
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
