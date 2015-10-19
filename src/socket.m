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

#import "OFException.h"  /* For some E* -> WSAE* defines */
#import "OFInvalidArgumentException.h"
#import "OFLockFailedException.h"
#import "OFUnlockFailedException.h"

#import "socket.h"
#ifdef OF_HAVE_THREADS
# include "threading.h"

static of_once_t onceControl = OF_ONCE_INIT;
static of_mutex_t mutex;
#endif
static bool initialized = false;

#ifdef OF_WII
# ifdef OF_HAVE_THREADS
static of_spinlock_t spinlock;
# endif
static uint8_t portRegistry[2][65536 / 8];
#endif

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
#endif

#ifdef OF_HAVE_THREADS
	if (!of_mutex_new(&mutex))
		return;

# ifdef OF_WII
	if (!of_spinlock_new(&spinlock))
		return;
# endif
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
of_getsockname(of_socket_t socket, struct sockaddr *restrict address,
    socklen_t *restrict address_len)
{
	int ret;

# ifdef OF_HAVE_THREADS
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];

# endif

	ret = getsockname(socket, address, address_len);

# ifdef OF_HAVE_THREADS
	if (!of_mutex_unlock(&mutex))
		@throw [OFUnlockFailedException exception];
# endif

	return ret;
}
#else
static size_t
type_to_index(int type)
{
	switch (type) {
	case SOCK_STREAM:
		return 0;
	case SOCK_DGRAM:
		return 1;
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

bool
of_socket_port_register(uint16_t port, int type)
{
	size_t index;
	bool wasSet;

	if (port == 0)
		@throw [OFInvalidArgumentException exception];

# ifdef OF_HAVE_THREADS
	if (!of_spinlock_lock(&spinlock))
		@throw [OFLockFailedException exception];
# endif

	index = type_to_index(type);
	wasSet = of_bitset_isset(portRegistry[index], port);

	of_bitset_set(portRegistry[index], port);

# ifdef OF_HAVE_THREADS
	if (!of_spinlock_unlock(&spinlock))
		@throw [OFUnlockFailedException exception];
# endif

	return !wasSet;
}

void
of_socket_port_free(uint16_t port, int type)
{
	if (port == 0)
		@throw [OFInvalidArgumentException exception];

# ifdef OF_HAVE_THREADS
	if (!of_spinlock_lock(&spinlock))
		@throw [OFLockFailedException exception];
# endif

	of_bitset_clear(portRegistry[type_to_index(type)], port);

# ifdef OF_HAVE_THREADS
	if (!of_spinlock_unlock(&spinlock))
		@throw [OFUnlockFailedException exception];
# endif
}

uint16_t
of_socket_port_find(int type)
{
	uint16_t port;
	size_t index;

# ifdef OF_HAVE_THREADS
	if (!of_spinlock_lock(&spinlock))
		@throw [OFLockFailedException exception];
# endif

	index = type_to_index(type);

	do {
		port = rand();
	} while (port == 0 || of_bitset_isset(portRegistry[index], port));

# ifdef OF_HAVE_THREADS
	if (!of_spinlock_unlock(&spinlock))
		@throw [OFUnlockFailedException exception];
# endif

	return port;
}
#endif
