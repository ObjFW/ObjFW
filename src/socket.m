/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFArray.h"
#import "OFCharacterSet.h"
#import "OFLocale.h"
#import "OFString.h"

#import "OFException.h"  /* For some E* -> WSAE* defines */
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFLockFailedException.h"
#import "OFUnlockFailedException.h"

#import "socket.h"
#import "socket_helpers.h"
#ifdef OF_HAVE_THREADS
# ifndef OF_AMIGAOS
#  import "mutex.h"
# else
#  import "tlskey.h"
# endif
#endif
#include "once.h"

#ifdef OF_AMIGAOS
# include <proto/exec.h>
#endif

#ifdef OF_NINTENDO_3DS
# include <3ds/types.h>
# include <3ds/services/soc.h>
#endif

#if defined(OF_HAVE_THREADS) && !defined(OF_AMIGAOS)
static of_mutex_t mutex;
#endif
#ifndef OF_AMIGAOS
static bool initSuccessful = false;
#else
# ifdef OF_HAVE_THREADS
of_tlskey_t of_socket_base_key;
#  ifdef OF_AMIGAOS4
of_tlskey_t of_socket_interface_key;
#  endif
# else
struct Library *SocketBase;
#  ifdef OF_AMIGAOS4
struct SocketIFace *ISocket = NULL;
#  endif
# endif
#endif

#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS)
OF_CONSTRUCTOR()
{
	if (!of_tlskey_new(&of_socket_base_key))
		@throw [OFInitializationFailedException exception];

# ifdef OF_AMIGAOS4
	if (!of_tlskey_new(&of_socket_interface_key))
		@throw [OFInitializationFailedException exception];
# endif
}
#endif

#if !defined(OF_AMIGAOS) || !defined(OF_HAVE_THREADS)
static void
init(void)
{
# if defined(OF_WINDOWS)
	WSADATA wsa;

	if (WSAStartup(MAKEWORD(2, 0), &wsa))
		return;
# elif defined(OF_AMIGAOS)
	if ((SocketBase = OpenLibrary("bsdsocket.library", 4)) == NULL)
		return;

#  ifdef OF_AMIGAOS4
	if ((ISocket = (struct SocketIFace *)
	    GetInterface(SocketBase, "main", 1, NULL)) == NULL) {
		CloseLibrary(SocketBase);
		return;
	}
#  endif
# elif defined(OF_WII)
	if (net_init() < 0)
		return;
# elif defined(OF_NINTENDO_3DS)
	void *ctx;

	if ((ctx = memalign(0x1000, 0x100000)) == NULL)
		return;

	if (socInit(ctx, 0x100000) != 0)
		return;

	atexit((void (*)(void))socExit);
# endif

# if defined(OF_HAVE_THREADS) && !defined(OF_AMIGAOS)
	if (!of_mutex_new(&mutex))
		return;

#  ifdef OF_WII
	if (!of_spinlock_new(&spinlock))
		return;
#  endif
# endif

	initSuccessful = true;
}

# ifdef OF_AMIGAOS
OF_DESTRUCTOR()
{
#  ifdef OF_AMIGAOS4
	if (ISocket != NULL)
		DropInterface((struct Interface *)ISocket);
#  endif

	if (SocketBase != NULL)
		CloseLibrary(SocketBase);
}
# endif
#endif

bool
of_socket_init(void)
{
#if !defined(OF_AMIGAOS) || !defined(OF_HAVE_THREADS)
	static of_once_t onceControl = OF_ONCE_INIT;
	of_once(&onceControl, init);

	return initSuccessful;
#else
	struct Library *socketBase;
# ifdef OF_AMIGAOS4
	struct SocketIFace *socketInterface;
# endif

# ifdef OF_AMIGAOS4
	if ((socketInterface = of_tlskey_get(of_socket_interface_key)) != NULL)
# else
	if ((socketBase = of_tlskey_get(of_socket_base_key)) != NULL)
# endif
		return true;

	if ((socketBase = OpenLibrary("bsdsocket.library", 4)) == NULL)
		return false;

# ifdef OF_AMIGAOS4
	if ((socketInterface = (struct SocketIFace *)
	    GetInterface(socketBase, "main", 1, NULL)) == NULL) {
		CloseLibrary(socketBase);
		return false;
	}
# endif

	if (!of_tlskey_set(of_socket_base_key, socketBase)) {
		CloseLibrary(socketBase);
# ifdef OF_AMIGAOS4
		DropInterface((struct Interface *)socketInterface);
# endif
		return false;
	}

# ifdef OF_AMIGAOS4
	if (!of_tlskey_set(of_socket_interface_key, socketInterface)) {
		CloseLibrary(socketBase);
		DropInterface((struct Interface *)socketInterface);
		return false;
	}
# endif

	return true;
#endif
}

#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS)
void
of_socket_deinit(void)
{
	struct Library *socketBase = of_tlskey_get(of_socket_base_key);
# ifdef OF_AMIGAOS4
	struct SocketIFace *socketInterface =
	    of_tlskey_get(of_socket_interface_key);

	if (socketInterface != NULL)
		DropInterface((struct Interface *)socketInterface);
# endif
	if (socketBase != NULL)
		CloseLibrary(socketBase);
}
#endif

int
of_socket_errno()
{
#if defined(OF_WINDOWS)
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
#elif defined(OF_AMIGAOS)
	return Errno();
#else
	return errno;
#endif
}

#ifndef OF_WII
int
of_getsockname(of_socket_t sock, struct sockaddr *restrict addr,
    socklen_t *restrict addrLen)
{
	int ret;

# if defined(OF_HAVE_THREADS) && !defined(OF_AMIGAOS)
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];

# endif

	ret = getsockname(sock, addr, addrLen);

# if defined(OF_HAVE_THREADS) && !defined(OF_AMIGAOS)
	if (!of_mutex_unlock(&mutex))
		@throw [OFUnlockFailedException exception];
# endif

	return ret;
}
#endif

of_socket_address_t
of_socket_address_parse_ipv4(OFString *IPv4, uint16_t port)
{
	/* TODO: Support IPs that are not in the a.b.c.d format? */

	void *pool = objc_autoreleasePoolPush();
	OFCharacterSet *whitespaceCharacterSet =
	    [OFCharacterSet whitespaceCharacterSet];
	of_socket_address_t ret;
	struct sockaddr_in *addrIn = &ret.sockaddr.in;
	OFArray OF_GENERIC(OFString *) *components;
	uint32_t addr;

	memset(&ret, '\0', sizeof(ret));
	ret.family = OF_SOCKET_ADDRESS_FAMILY_IPV4;
#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
	ret.length = 8;
#else
	ret.length = sizeof(ret.sockaddr.in);
#endif

	addrIn->sin_family = AF_INET;
	addrIn->sin_port = OF_BSWAP16_IF_LE(port);
#ifdef OF_WII
	addrIn->sin_len = ret.length;
#endif

	components = [IPv4 componentsSeparatedByString: @"."];

	if (components.count != 4)
		@throw [OFInvalidFormatException exception];

	addr = 0;

	for (OFString *component in components) {
		intmax_t number;

		if (component.length == 0)
			@throw [OFInvalidFormatException exception];

		if ([component indexOfCharacterFromSet:
		    whitespaceCharacterSet] != OF_NOT_FOUND)
			@throw [OFInvalidFormatException exception];

		number = component.decimalValue;

		if (number < 0 || number > UINT8_MAX)
			@throw [OFInvalidFormatException exception];

		addr = (addr << 8) | (number & 0xFF);
	}

	addrIn->sin_addr.s_addr = OF_BSWAP32_IF_LE(addr);

	objc_autoreleasePoolPop(pool);

	return ret;
}

static uint16_t
parseIPv6Component(OFString *component)
{
	uintmax_t number;

	if ([component indexOfCharacterFromSet:
	    [OFCharacterSet whitespaceCharacterSet]] != OF_NOT_FOUND)
		@throw [OFInvalidFormatException exception];

	number = component.hexadecimalValue;

	if (number > UINT16_MAX)
		@throw [OFInvalidFormatException exception];

	return (uint16_t)number;
}

of_socket_address_t
of_socket_address_parse_ipv6(OFString *IPv6, uint16_t port)
{
	void *pool = objc_autoreleasePoolPush();
	of_socket_address_t ret;
	struct sockaddr_in6 *addrIn6 = &ret.sockaddr.in6;
	size_t doubleColon;

	memset(&ret, '\0', sizeof(ret));
	ret.family = OF_SOCKET_ADDRESS_FAMILY_IPV6;
	ret.length = sizeof(ret.sockaddr.in6);

#ifdef AF_INET6
	addrIn6->sin6_family = AF_INET6;
#else
	addrIn6->sin6_family = AF_UNSPEC;
#endif
	addrIn6->sin6_port = OF_BSWAP16_IF_LE(port);

	doubleColon = [IPv6 rangeOfString: @"::"].location;

	if (doubleColon != OF_NOT_FOUND) {
		OFString *left = [IPv6 substringWithRange:
		    of_range(0, doubleColon)];
		OFString *right = [IPv6 substringWithRange:
		    of_range(doubleColon + 2, IPv6.length - doubleColon - 2)];
		OFArray OF_GENERIC(OFString *) *leftComponents;
		OFArray OF_GENERIC(OFString *) *rightComponents;
		size_t i;

		if ([right hasPrefix: @":"] || [right containsString: @"::"])
			@throw [OFInvalidFormatException exception];

		leftComponents = [left componentsSeparatedByString: @":"];
		rightComponents = [right componentsSeparatedByString: @":"];

		if (leftComponents.count + rightComponents.count > 7)
			@throw [OFInvalidFormatException exception];

		i = 0;
		for (OFString *component in leftComponents) {
			uint16_t number = parseIPv6Component(component);

			addrIn6->sin6_addr.s6_addr[i++] = number >> 8;
			addrIn6->sin6_addr.s6_addr[i++] = number;
		}

		i = 16;
		for (OFString *component in rightComponents.reversedArray) {
			uint16_t number = parseIPv6Component(component);

			addrIn6->sin6_addr.s6_addr[--i] = number >> 8;
			addrIn6->sin6_addr.s6_addr[--i] = number;
		}
	} else {
		OFArray OF_GENERIC(OFString *) *components =
		    [IPv6 componentsSeparatedByString: @":"];
		size_t i;

		if (components.count != 8)
			@throw [OFInvalidFormatException exception];

		i = 0;
		for (OFString *component in components) {
			uint16_t number;

			if (component.length == 0)
				@throw [OFInvalidFormatException exception];

			number = parseIPv6Component(component);

			addrIn6->sin6_addr.s6_addr[i++] = number >> 8;
			addrIn6->sin6_addr.s6_addr[i++] = number;
		}
	}

	objc_autoreleasePoolPop(pool);

	return ret;
}

of_socket_address_t
of_socket_address_parse_ip(OFString *IP, uint16_t port)
{
	@try {
		return of_socket_address_parse_ipv6(IP, port);
	} @catch (OFInvalidFormatException *e) {
		return of_socket_address_parse_ipv4(IP, port);
	}
}

bool
of_socket_address_equal(const of_socket_address_t *address1,
    const of_socket_address_t *address2)
{
	const struct sockaddr_in *addrIn1, *addrIn2;
	const struct sockaddr_in6 *addrIn6_1, *addrIn6_2;

	if (address1->family != address2->family)
		return false;

	switch (address1->family) {
	case OF_SOCKET_ADDRESS_FAMILY_IPV4:
#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
		if (address1->length < 8 || address2->length < 8)
			@throw [OFInvalidArgumentException exception];
#else
		if (address1->length < (socklen_t)sizeof(struct sockaddr_in) ||
		    address2->length < (socklen_t)sizeof(struct sockaddr_in))
			@throw [OFInvalidArgumentException exception];
#endif

		addrIn1 = &address1->sockaddr.in;
		addrIn2 = &address2->sockaddr.in;

		if (addrIn1->sin_port != addrIn2->sin_port)
			return false;
		if (addrIn1->sin_addr.s_addr != addrIn2->sin_addr.s_addr)
			return false;

		break;
	case OF_SOCKET_ADDRESS_FAMILY_IPV6:
		if (address1->length < (socklen_t)sizeof(struct sockaddr_in6) ||
		    address2->length < (socklen_t)sizeof(struct sockaddr_in6))
			@throw [OFInvalidArgumentException exception];

		addrIn6_1 = &address1->sockaddr.in6;
		addrIn6_2 = &address2->sockaddr.in6;

		if (addrIn6_1->sin6_port != addrIn6_2->sin6_port)
			return false;
		if (memcmp(addrIn6_1->sin6_addr.s6_addr,
		    addrIn6_2->sin6_addr.s6_addr,
		    sizeof(addrIn6_1->sin6_addr.s6_addr)) != 0)
			return false;

		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}

	return true;
}

uint32_t
of_socket_address_hash(const of_socket_address_t *address)
{
	uint32_t hash;

	OF_HASH_INIT(hash);
	OF_HASH_ADD(hash, address->family);

	switch (address->family) {
	case OF_SOCKET_ADDRESS_FAMILY_IPV4:
#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
		if (address->length < 8)
			@throw [OFInvalidArgumentException exception];
#else
		if (address->length < (socklen_t)sizeof(struct sockaddr_in))
			@throw [OFInvalidArgumentException exception];
#endif

		OF_HASH_ADD(hash, address->sockaddr.in.sin_port >> 8);
		OF_HASH_ADD(hash, address->sockaddr.in.sin_port);
		OF_HASH_ADD(hash, address->sockaddr.in.sin_addr.s_addr >> 24);
		OF_HASH_ADD(hash, address->sockaddr.in.sin_addr.s_addr >> 16);
		OF_HASH_ADD(hash, address->sockaddr.in.sin_addr.s_addr >> 8);
		OF_HASH_ADD(hash, address->sockaddr.in.sin_addr.s_addr);

		break;
	case OF_SOCKET_ADDRESS_FAMILY_IPV6:
		if (address->length < (socklen_t)sizeof(struct sockaddr_in6))
			@throw [OFInvalidArgumentException exception];

		OF_HASH_ADD(hash, address->sockaddr.in6.sin6_port >> 8);
		OF_HASH_ADD(hash, address->sockaddr.in6.sin6_port);

		for (size_t i = 0;
		    i < sizeof(address->sockaddr.in6.sin6_addr.s6_addr); i++)
			OF_HASH_ADD(hash,
			    address->sockaddr.in6.sin6_addr.s6_addr[i]);

		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}

static OFString *
IPv4String(const of_socket_address_t *address, uint16_t *port)
{
	const struct sockaddr_in *addrIn = &address->sockaddr.in;
	uint32_t addr = OF_BSWAP32_IF_LE(addrIn->sin_addr.s_addr);
	OFString *string;

	string = [OFString stringWithFormat: @"%u.%u.%u.%u",
	    (addr & 0xFF000000) >> 24, (addr & 0x00FF0000) >> 16,
	    (addr & 0x0000FF00) >>  8, addr & 0x000000FF];

	if (port != NULL)
		*port = OF_BSWAP16_IF_LE(addrIn->sin_port);

	return string;
}

static OFString *
IPv6String(const of_socket_address_t *address, uint16_t *port)
{
	OFMutableString *string = [OFMutableString string];
	const struct sockaddr_in6 *addrIn6 = &address->sockaddr.in6;
	int_fast8_t zerosStart = -1, maxZerosStart = -1;
	uint_fast8_t zerosCount = 0, maxZerosCount = 0;
	bool first = true;

	for (uint_fast8_t i = 0; i < 16; i += 2) {
		if (addrIn6->sin6_addr.s6_addr[i] == 0 &&
		    addrIn6->sin6_addr.s6_addr[i + 1] == 0) {
			if (zerosStart >= 0)
				zerosCount++;
			else {
				zerosStart = i;
				zerosCount = 1;
			}
		} else {
			if (zerosCount > maxZerosCount) {
				maxZerosStart = zerosStart;
				maxZerosCount = zerosCount;
			}

			zerosStart = -1;
		}
	}
	if (zerosCount > maxZerosCount) {
		maxZerosStart = zerosStart;
		maxZerosCount = zerosCount;
	}

	if (maxZerosCount >= 2) {
		for (int_fast8_t i = 0; i < maxZerosStart; i += 2) {
			[string appendFormat:
			    (first ? @"%x" : @":%x"),
			    (addrIn6->sin6_addr.s6_addr[(uint_fast8_t)i] << 8) |
			    addrIn6->sin6_addr.s6_addr[(uint_fast8_t)i + 1]];
			first = false;
		}

		[string appendString: @"::"];
		first = true;

		for (int_fast8_t i = maxZerosStart + (maxZerosCount * 2);
		    i < 16; i += 2) {
			[string appendFormat:
			    (first ? @"%x" : @":%x"),
			    (addrIn6->sin6_addr.s6_addr[(uint_fast8_t)i] << 8) |
			    addrIn6->sin6_addr.s6_addr[(uint_fast8_t)i + 1]];
			first = false;
		}
	} else {
		for (uint_fast8_t i = 0; i < 16; i += 2) {
			[string appendFormat:
			    (first ? @"%x" : @":%x"),
			    (addrIn6->sin6_addr.s6_addr[i] << 8) |
			    addrIn6->sin6_addr.s6_addr[i + 1]];
			first = false;
		}
	}

	[string makeImmutable];

	if (port != NULL)
		*port = OF_BSWAP16_IF_LE(addrIn6->sin6_port);

	return string;
}

OFString *
of_socket_address_ip_string(const of_socket_address_t *address, uint16_t *port)
{
	switch (address->family) {
	case OF_SOCKET_ADDRESS_FAMILY_IPV4:
		return IPv4String(address, port);
	case OF_SOCKET_ADDRESS_FAMILY_IPV6:
		return IPv6String(address, port);
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

void
of_socket_address_set_port(of_socket_address_t *address, uint16_t port)
{
	switch (address->family) {
	case OF_SOCKET_ADDRESS_FAMILY_IPV4:
		address->sockaddr.in.sin_port = OF_BSWAP16_IF_LE(port);
		break;
	case OF_SOCKET_ADDRESS_FAMILY_IPV6:
		address->sockaddr.in6.sin6_port = OF_BSWAP16_IF_LE(port);
		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

uint16_t
of_socket_address_get_port(const of_socket_address_t *address)
{
	switch (address->family) {
	case OF_SOCKET_ADDRESS_FAMILY_IPV4:
		return OF_BSWAP16_IF_LE(address->sockaddr.in.sin_port);
	case OF_SOCKET_ADDRESS_FAMILY_IPV6:
		return OF_BSWAP16_IF_LE(address->sockaddr.in6.sin6_port);
	default:
		@throw [OFInvalidArgumentException exception];
	}
}
