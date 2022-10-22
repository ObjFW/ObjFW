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

#include "objfw-defs.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

#include <stdbool.h>

#import "OFString.h"
#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS)
# import "OFTLSKey.h"
#endif

#ifdef OF_HAVE_SYS_SOCKET_H
# include <sys/socket.h>
#endif
#ifdef OF_HAVE_NETINET_IN_H
# include <netinet/in.h>
#endif
#ifdef OF_HAVE_NETINET_TCP_H
# include <netinet/tcp.h>
#endif
#ifdef OF_HAVE_NETIPX_IPX_H
# include <netipx/ipx.h>
#endif
#ifdef OF_HAVE_SYS_UN_H
# include <sys/un.h>
#endif
#ifdef OF_HAVE_AFUNIX_H
# include <afunix.h>
#endif

#ifdef OF_WINDOWS
# include <windows.h>
# include <ws2tcpip.h>
# ifdef OF_HAVE_IPX
#  include <wsipx.h>
# endif
#endif

/** @file */

#ifdef OF_WII
# include <network.h>
#endif

#ifdef OF_PSP
# include <stdint.h>
#endif

#import "macros.h"

OF_ASSUME_NONNULL_BEGIN

#ifndef OF_WINDOWS
typedef int OFSocketHandle;
static const OFSocketHandle OFInvalidSocketHandle = -1;
#else
typedef SOCKET OFSocketHandle;
static const OFSocketHandle OFInvalidSocketHandle = INVALID_SOCKET;
#endif

#ifdef OF_WINDOWS
typedef short sa_family_t;
#endif

#ifdef OF_WII
typedef u8 sa_family_t;
#endif

#ifdef OF_MORPHOS
typedef long socklen_t;
typedef u_char sa_family_t;
typedef u_short in_port_t;
#endif

/**
 * @brief A socket address family.
 */
typedef enum {
	/** An unknown address family. */
	OFSocketAddressFamilyUnknown,
	/** IPv4 */
	OFSocketAddressFamilyIPv4,
	/** IPv6 */
	OFSocketAddressFamilyIPv6,
	/** UNIX */
	OFSocketAddressFamilyUNIX,
	/** IPX */
	OFSocketAddressFamilyIPX,
	/** Any address family */
	OFSocketAddressFamilyAny = 255
} OFSocketAddressFamily;

#ifndef OF_HAVE_IPV6
struct sockaddr_in6 {
	sa_family_t sin6_family;
	in_port_t sin6_port;
	uint32_t sin6_flowinfo;
	struct in6_addr {
		uint8_t s6_addr[16];
	} sin6_addr;
	uint32_t sin6_scope_id;
};
#endif

#if !defined(OF_HAVE_UNIX_SOCKETS) && !defined(OF_MORPHOS) && !defined(OF_MINT)
struct sockaddr_un {
	sa_family_t sun_family;
	char sun_path[108];
};
#endif

#ifndef OF_HAVE_IPX
# define IPX_NODE_LEN 6
struct sockaddr_ipx {
	sa_family_t sipx_family;
	uint32_t sipx_network;
	unsigned char sipx_node[IPX_NODE_LEN];
	uint16_t sipx_port;
	uint8_t sipx_type;
};
#endif
#ifdef OF_WINDOWS
# define IPX_NODE_LEN 6
# define sipx_family sa_family
# define sipx_network sa_netnum
# define sipx_node sa_nodenum
# define sipx_port sa_socket
#endif

/**
 * @struct OFSocketAddress OFSocket.h ObjFW/OFSocket.h
 *
 * @brief A struct which represents a host / port pair for a socket.
 */
typedef struct OF_BOXABLE {
	OFSocketAddressFamily family;
	/*
	 * We can't use struct sockaddr as it can contain variable length
	 * arrays.
	 */
	union {
		struct sockaddr_in in;
		struct sockaddr_in6 in6;
		struct sockaddr_un un;
		struct sockaddr_ipx ipx;
	} sockaddr;
	socklen_t length;
} OFSocketAddress;

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Parses the specified IP (either v4 or v6) and port into an
 *	  @ref OFSocketAddress.
 *
 * @param IP The IP to parse
 * @param port The port to use
 * @return The parsed IP and port as an OFSocketAddress
 * @throw OFInvalidFormatException The specified string is not a valid IP
 */
extern OFSocketAddress OFSocketAddressParseIP(OFString *IP, uint16_t port);

/**
 * @brief Parses the specified IPv4 and port into an @ref OFSocketAddress.
 *
 * @param IP The IPv4 to parse
 * @param port The port to use
 * @return The parsed IPv4 and port as an OFSocketAddress
 * @throw OFInvalidFormatException The specified string is not a valid IPv4
 */
extern OFSocketAddress OFSocketAddressParseIPv4(OFString *IP, uint16_t port);

/**
 * @brief Parses the specified IPv6 and port into an @ref OFSocketAddress.
 *
 * @param IP The IPv6 to parse
 * @param port The port to use
 * @return The parsed IPv6 and port as an OFSocketAddress
 * @throw OFInvalidFormatException The specified string is not a valid IPv6
 */
extern OFSocketAddress OFSocketAddressParseIPv6(OFString *IP, uint16_t port);

/**
 * @brief Creates a UNIX socket address from the specified path.
 *
 * @param path The path of the UNIX socket
 * @return A UNIX socket address with the specified path
 */
extern OFSocketAddress OFSocketAddressMakeUNIX(OFString *path);

/**
 * @brief Creates an IPX address for the specified node, network and port.
 *
 * @param network The IPX network
 * @param node The node in the IPX network
 * @param port The IPX port (sometimes called socket number) on the node
 * @return An IPX socket address with the specified node, network and port.
 */
extern OFSocketAddress OFSocketAddressMakeIPX(uint32_t network,
    const unsigned char node[_Nonnull IPX_NODE_LEN], uint16_t port);

/**
 * @brief Compares two OFSocketAddress for equality.
 *
 * @param address1 The address to compare with the second address
 * @param address2 The second address
 * @return Whether the two addresses are equal
 */
extern bool OFSocketAddressEqual(const OFSocketAddress *_Nonnull address1,
    const OFSocketAddress *_Nonnull address2);

/**
 * @brief Returns the hash for the specified @ref OFSocketAddress.
 *
 * @param address The address to hash
 * @return The hash for the specified OFSocketAddress
 */
extern unsigned long OFSocketAddressHash(
    const OFSocketAddress *_Nonnull address);

/**
 * @brief Converts the specified @ref OFSocketAddress to a string.
 *
 * @param address The address to convert to a string
 * @return The address as an IP string
 */
extern OFString *_Nonnull OFSocketAddressString(
    const OFSocketAddress *_Nonnull address);

/**
 * @brief Sets the port of the specified @ref OFSocketAddress, independent of
 *	  the address family used.
 *
 * @param address The address on which to set the port
 * @param port The port to set on the address
 */
extern void OFSocketAddressSetPort(OFSocketAddress *_Nonnull address,
    uint16_t port);

/**
 * @brief Returns the port of the specified @ref OFSocketAddress, independent of
 *	  the address family used.
 *
 * @param address The address on which to get the port
 * @return The port of the address
 */
extern uint16_t OFSocketAddressPort(const OFSocketAddress *_Nonnull address);

/**
 * @brief Gets the UNIX socket path of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to get the UNIX socket path
 * @return The UNIX socket path
 */
extern OFString *_Nullable OFSocketAddressUNIXPath(
    const OFSocketAddress *_Nonnull address);

/**
 * @brief Sets the IPX network of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to set the IPX network
 * @param network The IPX network to set on the address
 */
extern void OFSocketAddressSetIPXNetwork(OFSocketAddress *_Nonnull address,
    uint32_t network);

/**
 * @brief Returns the IPX network of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to get the IPX network
 * @return The IPX network of the address
 */
extern uint32_t OFSocketAddressIPXNetwork(
    const OFSocketAddress *_Nonnull address);

/**
 * @brief Sets the IPX node of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to set the IPX node
 * @param node The IPX node to set on the address
 */
extern void OFSocketAddressSetIPXNode(OFSocketAddress *_Nonnull address,
    const unsigned char node[_Nonnull IPX_NODE_LEN]);

/**
 * @brief Gets the IPX node of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to get the IPX node
 * @param node A byte array to store the IPX node of the address
 */
extern void OFSocketAddressGetIPXNode(const OFSocketAddress *_Nonnull address,
    unsigned char node[_Nonnull IPX_NODE_LEN]);

extern bool OFSocketInit(void);
#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS) && !defined(OF_MORPHOS)
extern void OFSocketDeinit(void);
#endif
extern int OFSocketErrNo(void);
#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
extern int OFGetSockName(OFSocketHandle sock, struct sockaddr *restrict addr,
    socklen_t *restrict addrLen);
#endif

#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS) && !defined(OF_MORPHOS)
extern OFTLSKey OFSocketBaseKey;
# ifdef OF_AMIGAOS4
extern OFTLSKey OFSocketInterfaceKey;
# endif
#endif
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
