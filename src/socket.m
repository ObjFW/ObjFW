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

#import "OFLocale.h"

#import "OFException.h"  /* For some E* -> WSAE* defines */
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFLockFailedException.h"
#import "OFUnlockFailedException.h"

#import "socket.h"
#import "socket_helpers.h"
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

static of_socket_address_t
parseIPv4(OFString *IPv4, uint16_t port)
{
	void *pool = objc_autoreleasePoolPush();
	of_socket_address_t ret;
	struct sockaddr_in *sin = (struct sockaddr_in *)&ret.address;

	memset(&ret, '\0', sizeof(ret));
	ret.length = sizeof(struct sockaddr_in);

	sin->sin_family = AF_INET;
	sin->sin_port = OF_BSWAP16_IF_LE(port);

	if (inet_pton(AF_INET, [IPv4 cStringWithEncoding: [OFLocale encoding]],
	    &sin->sin_addr) != 1)
		@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);

	return ret;
}

#ifdef HAVE_IPV6
static of_socket_address_t
parseIPv6(OFString *IPv6, uint16_t port)
{
	void *pool = objc_autoreleasePoolPush();
	of_socket_address_t ret;
	struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)&ret.address;

	memset(&ret, '\0', sizeof(ret));
	ret.length = sizeof(struct sockaddr_in6);

	sin6->sin6_family = AF_INET6;
	sin6->sin6_port = OF_BSWAP16_IF_LE(port);

	if (inet_pton(AF_INET6, [IPv6 cStringWithEncoding: [OFLocale encoding]],
	    &sin6->sin_addr6) != 1)
		@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);

	return ret;
}
#endif

of_socket_address_t
of_socket_address_parse_ip(OFString *IP, uint16_t port)
{
#ifdef HAVE_IPV6
	@try {
		return parseIPv6(IP, port);
	} @catch (OFInvalidFormatException *e) {
#endif
		return parseIPv4(IP, port);
#ifdef HAVE_IPV6
	}
#endif
}

bool
of_socket_address_equal(of_socket_address_t *address1,
    of_socket_address_t *address2)
{
	struct sockaddr_in *addrIn1, *addrIn2;
#ifdef HAVE_IPV6
	struct sockaddr_in6 *addrIn6_1, *addrIn6_2;
#endif

	if (address1->address.ss_family != address2->address.ss_family)
		return false;

	switch (address1->address.ss_family) {
	case AF_INET:
#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
		if (address1->length < (socklen_t)sizeof(struct sockaddr_in) ||
		    address2->length < (socklen_t)sizeof(struct sockaddr_in))
			@throw [OFInvalidArgumentException exception];
#else
		if (address1->length < 8 || address2->length < 8)
			@throw [OFInvalidArgumentException exception];
#endif

		addrIn1 = (struct sockaddr_in *)&address1->address;
		addrIn2 = (struct sockaddr_in *)&address2->address;

		if (addrIn1->sin_port != addrIn2->sin_port)
			return false;
		if (addrIn1->sin_addr.s_addr != addrIn2->sin_addr.s_addr)
			return false;

		break;
#ifdef HAVE_IPV6
	case AF_INET6:
		if (address1->length < sizeof(struct sockaddr_in6) ||
		    address2->length < sizeof(struct sockaddr_in6))
			@throw [OFInvalidArgumentException exception];

		addrIn6_1 = (struct sockaddr_in6 *)&address1->address;
		addrIn6_2 = (struct sockaddr_in6 *)&address2->address;

		if (addrIn6_1->sin6_port != addrIn6_2->sin6_port)
			return false;
		if (memcmp(addrIn6_1->sin6_addr.s6_addr,
		    addrIn6_2->sin6_addr.s6_addr,
		    sizeof(addrIn6_1->sin6_addr.s6_addr)) != 0)
			return false;

		break;
#endif
	default:
		@throw [OFInvalidArgumentException exception];
	}

	return true;
}

uint32_t
of_socket_address_hash(of_socket_address_t *address)
{
	uint32_t hash = of_hash_seed;
	struct sockaddr_in *addrIn;
#ifdef HAVE_IPV6
	struct sockaddr_in6 *addrIn6;
	uint32_t subhash;
#endif

	hash += address->address.ss_family;

	switch (address->address.ss_family) {
	case AF_INET:
#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
		if (address->length < (socklen_t)sizeof(struct sockaddr_in))
			@throw [OFInvalidArgumentException exception];
#else
		if (address->length < 8)
			@throw [OFInvalidArgumentException exception];
#endif

		addrIn = (struct sockaddr_in *)&address->address;

		hash += (addrIn->sin_port << 1);
		hash ^= addrIn->sin_addr.s_addr;

		break;
#ifdef HAVE_IPV6
	case AF_INET6:
		if (address->length < sizeof(struct sockaddr_in6))
			@throw [OFInvalidArgumentException exception];

		addrIn6 = (struct sockaddr_in6 *)&address->address;

		hash += (addrIn6->sin6_port << 1);

		OF_HASH_INIT(subhash);

		for (size_t i = 0; i < sizeof(addrIn6->sin6_addr.s6_addr); i++)
			OF_HASH_ADD(subhash, adrIn6->sin6_addr.s6_addr[i]);

		OF_HASH_FINALIZE(subhash);

		hash ^= subhash;

		break;
#endif
	default:
		@throw [OFInvalidArgumentException exception];
	}

	return hash;
}

static OFString *
IPv4String(const of_socket_address_t *address, uint16_t *port)
{
	const struct sockaddr_in *sin =
	    (const struct sockaddr_in *)&address->address;
	char buffer[INET_ADDRSTRLEN];

	if (inet_ntop(AF_INET, &sin->sin_addr, buffer, sizeof(buffer)) == NULL)
		@throw [OFInvalidArgumentException exception];

	if (port != NULL)
		*port = OF_BSWAP16_IF_LE(sin->sin_port);

	return [OFString stringWithCString: buffer
				  encoding: [OFLocale encoding]];
}

#ifdef HAVE_IPV6
static OFString *
IPv6String(const of_socket_address_t *address, uint16_t *port)
{
	const struct sockaddr_in6 *sin6 =
	    (const struct sockaddr_in6 *)&address->address;
	char buffer[INET6_ADDRSTRLEN];

	if (inet_ntop(AF_INET, &sin6->sin_addr6, buffer, sizeof(buffer)) ==
	    NULL)
		@throw [OFInvalidArgumentException exception];

	if (port != NULL)
		*port = OF_BSWAP16_IF_LE(sin6->sin_port);

	return [OFString stringWithCString: buffer
				  encoding: [OFLocale encoding]];
}
#endif

OFString *
of_socket_address_ip_string(const of_socket_address_t *address, uint16_t *port)
{
	switch (address->address.ss_family) {
	case AF_INET:
		return IPv4String(address, port);
#ifdef HAVE_IPV6
	case AF_INET6:
		return IPv6String(address, port);
#endif
	default:
		@throw [OFInvalidArgumentException exception];
	}
}
