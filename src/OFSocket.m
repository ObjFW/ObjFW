/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#ifndef _XOPEN_SOURCE_EXTENDED
# define _XOPEN_SOURCE_EXTENDED
#endif
#define _HPUX_ALT_XOPEN_SOCKET_API

#ifdef OF_NINTENDO_3DS
# include <malloc.h>  /* For memalign() */
#endif

#include <errno.h>

#import "OFArray.h"
#import "OFCharacterSet.h"
#import "OFLocale.h"
#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif
#import "OFOnce.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFString.h"
#ifdef OF_HAVE_THREADS
# import "OFTLSKey.h"
#endif

#import "OFException.h"  /* For some E* -> WSAE* defines */
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFLockFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFUnlockFailedException.h"

#ifdef OF_AMIGAOS
# include <proto/exec.h>
#endif

#ifdef OF_NINTENDO_3DS
# include <3ds/types.h>
# include <3ds/services/soc.h>
#endif

#ifdef OF_NINTENDO_SWITCH
# define id nx_id
# include <switch.h>
# undef id
#endif

#if defined(OF_HAVE_THREADS) && (!defined(OF_AMIGAOS) || defined(OF_MORPHOS))
static OFMutex *mutex;

static void
releaseMutex(void)
{
	[mutex release];
}
#endif
#if !defined(OF_AMIGAOS) || defined(OF_MORPHOS) || !defined(OF_HAVE_THREADS)
static bool initSuccessful = false;
#endif

#ifdef OF_AMIGAOS
# if defined(OF_HAVE_THREADS) && !defined(OF_MORPHOS)
OFTLSKey OFSocketBaseKey;
#  ifdef OF_AMIGAOS4
OFTLSKey OFSocketInterfaceKey;
#  endif
# else
struct Library *SocketBase;
#  ifdef OF_AMIGAOS4
struct SocketIFace *ISocket = NULL;
#  endif
# endif
#endif

#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS) && !defined(OF_MORPHOS)
OF_CONSTRUCTOR()
{
	if (OFTLSKeyNew(&OFSocketBaseKey) != 0)
		@throw [OFInitializationFailedException exception];

# ifdef OF_AMIGAOS4
	if (OFTLSKeyNew(&OFSocketInterfaceKey) != 0)
		@throw [OFInitializationFailedException exception];
# endif
}
#endif

#if !defined(OF_AMIGAOS) || defined(OF_MORPHOS) || !defined(OF_HAVE_THREADS)
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
# elif defined(OF_NINTENDO_SWITCH)
	if (R_FAILED(socketInitializeDefault()))
		return;

	atexit(socketExit);
# endif

# if defined(OF_HAVE_THREADS) && (!defined(OF_AMIGAOS) || defined(OF_MORPHOS))
	mutex = [[OFMutex alloc] init];
	atexit(releaseMutex);
# endif

	initSuccessful = true;
}

OF_DESTRUCTOR()
{
# ifdef OF_AMIGAOS
#  ifdef OF_AMIGAOS4
	if (ISocket != NULL)
		DropInterface((struct Interface *)ISocket);
#  endif

	if (SocketBase != NULL)
		CloseLibrary(SocketBase);
# endif
}
#endif

bool
OFSocketInit(void)
{
#if !defined(OF_AMIGAOS) || defined(OF_MORPHOS) || !defined(OF_HAVE_THREADS)
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, init);

	return initSuccessful;
#else
	struct Library *socketBase;
# ifdef OF_AMIGAOS4
	struct SocketIFace *socketInterface;
# endif

# ifdef OF_AMIGAOS4
	if ((socketInterface = OFTLSKeyGet(OFSocketInterfaceKey)) != NULL)
# else
	if ((socketBase = OFTLSKeyGet(OFSocketBaseKey)) != NULL)
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

	if (OFTLSKeySet(OFSocketBaseKey, socketBase) != 0) {
		CloseLibrary(socketBase);
# ifdef OF_AMIGAOS4
		DropInterface((struct Interface *)socketInterface);
# endif
		return false;
	}

# ifdef OF_AMIGAOS4
	if (OFTLSKeySet(OFSocketInterfaceKey, socketInterface) != 0) {
		CloseLibrary(socketBase);
		DropInterface((struct Interface *)socketInterface);
		return false;
	}
# endif

	return true;
#endif
}

#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS) && !defined(OF_MORPHOS)
void
OFSocketDeinit(void)
{
	struct Library *socketBase = OFTLSKeyGet(OFSocketBaseKey);
# ifdef OF_AMIGAOS4
	struct SocketIFace *socketInterface = OFTLSKeyGet(OFSocketInterfaceKey);

	if (socketInterface != NULL)
		DropInterface((struct Interface *)socketInterface);
# endif
	if (socketBase != NULL)
		CloseLibrary(socketBase);
}
#endif

int
OFSocketErrNo(void)
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
OFGetSockName(OFSocketHandle sock, struct sockaddr *restrict addr,
    socklen_t *restrict addrLen)
{
	int ret;

# if defined(OF_HAVE_THREADS) && (!defined(OF_AMIGAOS) || defined(OF_MORPHOS))
	[mutex lock];
# endif
	ret = getsockname(sock, addr, addrLen);
# if defined(OF_HAVE_THREADS) && (!defined(OF_AMIGAOS) || defined(OF_MORPHOS))
	[mutex unlock];
# endif

	return ret;
}
#endif

OFSocketAddress
OFSocketAddressParseIPv4(OFString *IPv4, uint16_t port)
{
	void *pool = objc_autoreleasePoolPush();
	OFCharacterSet *whitespaceCharacterSet =
	    [OFCharacterSet whitespaceCharacterSet];
	OFSocketAddress ret;
	struct sockaddr_in *addrIn = &ret.sockaddr.in;
	OFArray OF_GENERIC(OFString *) *components;
	uint32_t addr;

	memset(&ret, '\0', sizeof(ret));
	ret.family = OFSocketAddressFamilyIPv4;
#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
	ret.length = 8;
#else
	ret.length = sizeof(ret.sockaddr.in);
#endif

	addrIn->sin_family = AF_INET;
	addrIn->sin_port = OFToBigEndian16(port);
#ifdef OF_WII
	addrIn->sin_len = ret.length;
#endif

	components = [IPv4 componentsSeparatedByString: @"."];

	if (components.count != 4)
		@throw [OFInvalidFormatException exception];

	addr = 0;

	for (OFString *component in components) {
		unsigned long long number;

		if (component.length == 0)
			@throw [OFInvalidFormatException exception];

		if ([component indexOfCharacterFromSet:
		    whitespaceCharacterSet] != OFNotFound)
			@throw [OFInvalidFormatException exception];

		number = component.unsignedLongLongValue;

		if (number > UINT8_MAX)
			@throw [OFInvalidFormatException exception];

		addr = (addr << 8) | ((uint32_t)number & 0xFF);
	}

	addrIn->sin_addr.s_addr = OFToBigEndian32(addr);

	objc_autoreleasePoolPop(pool);

	return ret;
}

static uint16_t
parseIPv6Component(OFString *component)
{
	unsigned long long number;

	if ([component indexOfCharacterFromSet:
	    [OFCharacterSet whitespaceCharacterSet]] != OFNotFound)
		@throw [OFInvalidFormatException exception];

	number = [component unsignedLongLongValueWithBase: 16];

	if (number > UINT16_MAX)
		@throw [OFInvalidFormatException exception];

	return (uint16_t)number;
}

OFSocketAddress
OFSocketAddressParseIPv6(OFString *IPv6, uint16_t port)
{
	void *pool = objc_autoreleasePoolPush();
	OFSocketAddress ret;
	struct sockaddr_in6 *addrIn6 = &ret.sockaddr.in6;
	size_t doubleColon;

	memset(&ret, '\0', sizeof(ret));
	ret.family = OFSocketAddressFamilyIPv6;
	ret.length = sizeof(ret.sockaddr.in6);

#ifdef AF_INET6
	addrIn6->sin6_family = AF_INET6;
#else
	addrIn6->sin6_family = AF_UNSPEC;
#endif
	addrIn6->sin6_port = OFToBigEndian16(port);

	doubleColon = [IPv6 rangeOfString: @"::"].location;

	if (doubleColon != OFNotFound) {
		OFString *left = [IPv6 substringToIndex: doubleColon];
		OFString *right = [IPv6 substringFromIndex: doubleColon + 2];
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

			addrIn6->sin6_addr.s6_addr[--i] = number;
			addrIn6->sin6_addr.s6_addr[--i] = number >> 8;
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

OFSocketAddress
OFSocketAddressParseIP(OFString *IP, uint16_t port)
{
	OFSocketAddress ret;

	@try {
		ret = OFSocketAddressParseIPv6(IP, port);
	} @catch (OFInvalidFormatException *e) {
		ret = OFSocketAddressParseIPv4(IP, port);
	}

	return ret;
}

OFSocketAddress
OFSocketAddressMakeUNIX(OFString *path)
{
	void *pool = objc_autoreleasePoolPush();
	OFStringEncoding encoding = [OFLocale encoding];
	size_t length = [path cStringLengthWithEncoding: encoding];
	OFSocketAddress ret;

	if (length > sizeof(ret.sockaddr.un.sun_path))
		@throw [OFOutOfRangeException exception];

	memset(&ret, '\0', sizeof(ret));
	ret.family = OFSocketAddressFamilyUNIX;
	ret.length = (socklen_t)
	    (offsetof(struct sockaddr_un, sun_path) + length);

#ifdef AF_UNIX
	ret.sockaddr.un.sun_family = AF_UNIX;
#else
	ret.sockaddr.un.sun_family = AF_UNSPEC;
#endif
	memcpy(ret.sockaddr.un.sun_path,
	    [path cStringWithEncoding: encoding], length);

	objc_autoreleasePoolPop(pool);

	return ret;
}

OFSocketAddress
OFSocketAddressMakeIPX(uint32_t network, const unsigned char node[IPX_NODE_LEN],
    uint16_t port)
{
	OFSocketAddress ret;

	memset(&ret, '\0', sizeof(ret));
	ret.family = OFSocketAddressFamilyIPX;
	ret.length = sizeof(ret.sockaddr.ipx);

#ifdef AF_IPX
	ret.sockaddr.ipx.sipx_family = AF_IPX;
#else
	ret.sockaddr.ipx.sipx_family = AF_UNSPEC;
#endif
	network = OFToBigEndian32(network);
	memcpy(&ret.sockaddr.ipx.sipx_network, &network,
	    sizeof(ret.sockaddr.ipx.sipx_network));
	memcpy(ret.sockaddr.ipx.sipx_node, node, IPX_NODE_LEN);
	ret.sockaddr.ipx.sipx_port = OFToBigEndian16(port);

	return ret;
}

OFSocketAddress
OFSocketAddressMakeAppleTalk(uint16_t network, uint8_t node, uint8_t port)
{
	OFSocketAddress ret;

	memset(&ret, '\0', sizeof(ret));
	ret.family = OFSocketAddressFamilyAppleTalk;
	ret.length = sizeof(ret.sockaddr.at);

#ifdef AF_APPLETALK
	ret.sockaddr.at.sat_family = AF_APPLETALK;
#else
	ret.sockaddr.at.sat_family = AF_UNSPEC;
#endif
	ret.sockaddr.at.sat_net = OFToBigEndian16(network);
	ret.sockaddr.at.sat_node = node;
	ret.sockaddr.at.sat_port = port;

	return ret;
}

bool
OFSocketAddressEqual(const OFSocketAddress *address1,
    const OFSocketAddress *address2)
{
	const struct sockaddr_in *addrIn1, *addrIn2;
	const struct sockaddr_in6 *addrIn6_1, *addrIn6_2;
	const struct sockaddr_ipx *addrIPX1, *addrIPX2;
	const struct sockaddr_at *addrAT1, *addrAT2;
	void *pool;
	OFString *path1, *path2;
	bool ret;

	if (address1->family != address2->family)
		return false;

	switch (address1->family) {
	case OFSocketAddressFamilyIPv4:
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

		return true;
	case OFSocketAddressFamilyIPv6:
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

		return true;
	case OFSocketAddressFamilyUNIX:
		pool = objc_autoreleasePoolPush();

		path1 = OFSocketAddressUNIXPath(address1);
		path2 = OFSocketAddressUNIXPath(address2);

		if (path1 == nil || path2 == nil) {
			objc_autoreleasePoolPop(pool);

			return false;
		}

		ret = [path1 isEqual: path2];

		objc_autoreleasePoolPop(pool);

		return ret;
	case OFSocketAddressFamilyIPX:
		if (address1->length < (socklen_t)sizeof(struct sockaddr_ipx) ||
		    address2->length < (socklen_t)sizeof(struct sockaddr_ipx))
			@throw [OFInvalidArgumentException exception];

		addrIPX1 = &address1->sockaddr.ipx;
		addrIPX2 = &address2->sockaddr.ipx;

		if (addrIPX1->sipx_port != addrIPX2->sipx_port)
			return false;
		if (memcmp(&addrIPX1->sipx_network, &addrIPX2->sipx_network,
		    4) != 0)
			return false;
		if (memcmp(addrIPX1->sipx_node, addrIPX2->sipx_node,
		    IPX_NODE_LEN) != 0)
			return false;

		return true;
	case OFSocketAddressFamilyAppleTalk:
		if (address1->length < (socklen_t)sizeof(struct sockaddr_at) ||
		    address2->length < (socklen_t)sizeof(struct sockaddr_at))
			@throw [OFInvalidArgumentException exception];

		addrAT1 = &address1->sockaddr.at;
		addrAT2 = &address2->sockaddr.at;

		if (addrAT1->sat_net != addrAT2->sat_net)
			return false;
		if (addrAT1->sat_node != addrAT2->sat_node)
			return false;
		if (addrAT1->sat_port != addrAT2->sat_port)
			return false;

		return true;
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

unsigned long
OFSocketAddressHash(const OFSocketAddress *address)
{
	unsigned long hash;

	OFHashInit(&hash);
	OFHashAddByte(&hash, address->family);

	switch (address->family) {
	case OFSocketAddressFamilyIPv4:
#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
		if (address->length < 8)
			@throw [OFInvalidArgumentException exception];
#else
		if (address->length < (socklen_t)sizeof(struct sockaddr_in))
			@throw [OFInvalidArgumentException exception];
#endif

		OFHashAddByte(&hash, address->sockaddr.in.sin_port >> 8);
		OFHashAddByte(&hash, address->sockaddr.in.sin_port);
		OFHashAddByte(&hash,
		    address->sockaddr.in.sin_addr.s_addr >> 24);
		OFHashAddByte(&hash,
		    address->sockaddr.in.sin_addr.s_addr >> 16);
		OFHashAddByte(&hash, address->sockaddr.in.sin_addr.s_addr >> 8);
		OFHashAddByte(&hash, address->sockaddr.in.sin_addr.s_addr);

		break;
	case OFSocketAddressFamilyIPv6:
		if (address->length < (socklen_t)sizeof(struct sockaddr_in6))
			@throw [OFInvalidArgumentException exception];

		OFHashAddByte(&hash, address->sockaddr.in6.sin6_port >> 8);
		OFHashAddByte(&hash, address->sockaddr.in6.sin6_port);

		for (size_t i = 0;
		    i < sizeof(address->sockaddr.in6.sin6_addr.s6_addr); i++)
			OFHashAddByte(&hash,
			    address->sockaddr.in6.sin6_addr.s6_addr[i]);

		break;
	case OFSocketAddressFamilyUNIX:;
		void *pool = objc_autoreleasePoolPush();
		OFString *path = OFSocketAddressUNIXPath(address);

		hash = path.hash;

		objc_autoreleasePoolPop(pool);

		return hash;
	case OFSocketAddressFamilyIPX:;
		unsigned char network[
		    sizeof(address->sockaddr.ipx.sipx_network)];

		if (address->length < (socklen_t)sizeof(struct sockaddr_ipx))
			@throw [OFInvalidArgumentException exception];

		OFHashAddByte(&hash, address->sockaddr.ipx.sipx_port >> 8);
		OFHashAddByte(&hash, address->sockaddr.ipx.sipx_port);

		memcpy(network, &address->sockaddr.ipx.sipx_network,
		    sizeof(network));

		for (size_t i = 0; i < sizeof(network); i++)
			OFHashAddByte(&hash, network[i]);

		for (size_t i = 0; i < IPX_NODE_LEN; i++)
			OFHashAddByte(&hash,
			    address->sockaddr.ipx.sipx_node[i]);

		break;
	case OFSocketAddressFamilyAppleTalk:
		if (address->length < (socklen_t)sizeof(struct sockaddr_at))
			@throw [OFInvalidArgumentException exception];

		OFHashAddByte(&hash, address->sockaddr.at.sat_net >> 8);
		OFHashAddByte(&hash, address->sockaddr.at.sat_net);
		OFHashAddByte(&hash, address->sockaddr.at.sat_port);

		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}

	OFHashFinalize(&hash);

	return hash;
}

static OFString *
IPv4String(const OFSocketAddress *address)
{
	const struct sockaddr_in *addrIn = &address->sockaddr.in;
	uint32_t addr = OFFromBigEndian32(addrIn->sin_addr.s_addr);
	OFString *string;

	string = [OFString stringWithFormat: @"%u.%u.%u.%u",
	    (addr & 0xFF000000) >> 24, (addr & 0x00FF0000) >> 16,
	    (addr & 0x0000FF00) >>  8, addr & 0x000000FF];

	return string;
}

static OFString *
IPv6String(const OFSocketAddress *address)
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

	return string;
}

OFString *
OFSocketAddressString(const OFSocketAddress *address)
{
	switch (address->family) {
	case OFSocketAddressFamilyIPv4:
		return IPv4String(address);
	case OFSocketAddressFamilyIPv6:
		return IPv6String(address);
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

void
OFSocketAddressSetPort(OFSocketAddress *address, uint16_t port)
{
	switch (address->family) {
	case OFSocketAddressFamilyIPv4:
		address->sockaddr.in.sin_port = OFToBigEndian16(port);
		break;
	case OFSocketAddressFamilyIPv6:
		address->sockaddr.in6.sin6_port = OFToBigEndian16(port);
		break;
	case OFSocketAddressFamilyIPX:
		address->sockaddr.ipx.sipx_port = OFToBigEndian16(port);
		break;
	case OFSocketAddressFamilyAppleTalk:
		if (port > UINT8_MAX)
			@throw [OFOutOfRangeException exception];

		address->sockaddr.at.sat_port = (uint8_t)port;
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

uint16_t
OFSocketAddressPort(const OFSocketAddress *address)
{
	switch (address->family) {
	case OFSocketAddressFamilyIPv4:
		return OFFromBigEndian16(address->sockaddr.in.sin_port);
	case OFSocketAddressFamilyIPv6:
		return OFFromBigEndian16(address->sockaddr.in6.sin6_port);
	case OFSocketAddressFamilyIPX:
		return OFFromBigEndian16(address->sockaddr.ipx.sipx_port);
	case OFSocketAddressFamilyAppleTalk:
		return address->sockaddr.at.sat_port;
	default:
		@throw [OFInvalidArgumentException exception];
	}
}

OFString *
OFSocketAddressUNIXPath(const OFSocketAddress *_Nonnull address)
{
	socklen_t length;

	if (address->family != OFSocketAddressFamilyUNIX)
		@throw [OFInvalidArgumentException exception];

	length = address->length - offsetof(struct sockaddr_un, sun_path);

	for (socklen_t i = 0; i < length; i++)
		if (address->sockaddr.un.sun_path[i] == 0)
			length = i;

	if (length <= 0)
		return nil;

	return [OFString stringWithCString: address->sockaddr.un.sun_path
				  encoding: [OFLocale encoding]
				    length: length];
}

void
OFSocketAddressSetIPXNetwork(OFSocketAddress *address, uint32_t network)
{
	if (address->family != OFSocketAddressFamilyIPX)
		@throw [OFInvalidArgumentException exception];

	network = OFToBigEndian32(network);
	memcpy(&address->sockaddr.ipx.sipx_network, &network,
	    sizeof(address->sockaddr.ipx.sipx_network));
}

uint32_t
OFSocketAddressIPXNetwork(const OFSocketAddress *address)
{
	uint32_t network;

	if (address->family != OFSocketAddressFamilyIPX)
		@throw [OFInvalidArgumentException exception];

	memcpy(&network, &address->sockaddr.ipx.sipx_network, sizeof(network));

	return OFFromBigEndian32(network);
}

void
OFSocketAddressSetIPXNode(OFSocketAddress *address,
    const unsigned char node[IPX_NODE_LEN])
{
	if (address->family != OFSocketAddressFamilyIPX)
		@throw [OFInvalidArgumentException exception];

	memcpy(address->sockaddr.ipx.sipx_node, node, IPX_NODE_LEN);
}

void
OFSocketAddressIPXNode(const OFSocketAddress *address,
    unsigned char node[IPX_NODE_LEN])
{
	if (address->family != OFSocketAddressFamilyIPX)
		@throw [OFInvalidArgumentException exception];

	memcpy(node, address->sockaddr.ipx.sipx_node, IPX_NODE_LEN);
}

void
OFSocketAddressSetAppleTalkNetwork(OFSocketAddress *address, uint16_t network)
{
	if (address->family != OFSocketAddressFamilyAppleTalk)
		@throw [OFInvalidArgumentException exception];

	address->sockaddr.at.sat_net = OFToBigEndian16(network);
}

uint16_t
OFSocketAddressAppleTalkNetwork(const OFSocketAddress *address)
{
	if (address->family != OFSocketAddressFamilyAppleTalk)
		@throw [OFInvalidArgumentException exception];

	return OFFromBigEndian16(address->sockaddr.at.sat_net);
}

void
OFSocketAddressSetAppleTalkNode(OFSocketAddress *address, uint8_t node)
{
	if (address->family != OFSocketAddressFamilyAppleTalk)
		@throw [OFInvalidArgumentException exception];

	address->sockaddr.at.sat_node = node;
}

uint8_t
OFSocketAddressAppleTalkNode(const OFSocketAddress *address)
{
	if (address->family != OFSocketAddressFamilyAppleTalk)
		@throw [OFInvalidArgumentException exception];

	return address->sockaddr.at.sat_node;
}
