/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
#else
typedef SOCKET OFSocketHandle;
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
struct OF_BOXABLE OFSocketAddress {
	/*
	 * Even though struct sockaddr contains the family, we need to use our
	 * own family, as we need to support storing an IPv6 address on systems
	 * that don't support IPv6. These may not have AF_INET6 defined and we
	 * can't just define it, as the value is system-dependent and might
	 * clash with an existing value.
	 */
	OFSocketAddressFamily family;
	union {
		struct sockaddr sockaddr;
		struct sockaddr_in in;
		struct sockaddr_in6 in6;
		struct sockaddr_ipx ipx;
	} sockaddr;
	socklen_t length;
};
typedef struct OFSocketAddress OFSocketAddress;

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
 */
extern OFSocketAddress OFSocketAddressParseIP(OFString *IP, uint16_t port);

/**
 * @brief Parses the specified IPv4 and port into an @ref OFSocketAddress.
 *
 * @param IP The IPv4 to parse
 * @param port The port to use
 * @return The parsed IPv4 and port as an OFSocketAddress
 */
extern OFSocketAddress OFSocketAddressParseIPv4(OFString *IP, uint16_t port);

/**
 * @brief Parses the specified IPv6 and port into an @ref OFSocketAddress.
 *
 * @param IP The IPv6 to parse
 * @param port The port to use
 * @return The parsed IPv6 and port as an OFSocketAddress
 */
extern OFSocketAddress OFSocketAddressParseIPv6(OFString *IP, uint16_t port);

/**
 * @brief Creates an IPX address for the specified network, node and port.
 *
 * @param node The node in the IPX network
 * @param network The IPX network
 * @param port The IPX port (sometimes called socket number) on the node
 */
extern OFSocketAddress OFSocketAddressMakeIPX(
    const unsigned char node[_Nonnull IPX_NODE_LEN], uint32_t network,
    uint16_t port);

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
extern void OFSocketAddressIPXNode(const OFSocketAddress *_Nonnull address,
    unsigned char node[_Nonnull IPX_NODE_LEN]);

extern bool of_socket_init(void);
#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS) && !defined(OF_MORPHOS)
extern void of_socket_deinit(void);
#endif
extern int of_socket_errno(void);
#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
extern int of_getsockname(OFSocketHandle sock, struct sockaddr *restrict addr,
    socklen_t *restrict addrLen);
#endif

#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS) && !defined(OF_MORPHOS)
extern OFTLSKey of_socket_base_key;
# ifdef OF_AMIGAOS4
extern OFTLSKey of_socket_interface_key;
# endif
#endif
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
