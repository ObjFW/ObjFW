/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
#ifdef OF_HAVE_NETINET_SCTP_H
# include <netinet/sctp.h>
#endif
#ifdef OF_HAVE_SYS_UN_H
# include <sys/un.h>
#endif
#ifdef OF_HAVE_AFUNIX_H
# include <afunix.h>
#endif
#ifdef OF_HAVE_NETIPX_IPX_H
# include <netipx/ipx.h>
#endif
#if defined(OF_HAVE_NETAT_APPLETALK_H)
# include <netat/appletalk.h>
#elif defined(OF_HAVE_NETATALK_AT_H)
# include <netatalk/at.h>
#endif

#ifdef OF_WINDOWS
# include <windows.h>
# include <ws2tcpip.h>
# ifdef OF_HAVE_IPX
#  include <wsipx.h>
# endif
# ifdef OF_HAVE_APPLETALK
#  include <atalkwsh.h>
# endif
#endif

#ifdef OF_WII
# include <network.h>
#endif

#ifdef OF_PSP
# include <stdint.h>
#endif

#import "macros.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

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
	/** AppleTalk */
	OFSocketAddressFamilyAppleTalk,
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

#ifndef IPX_NODE_LEN
# define IPX_NODE_LEN 6
#endif
#if !defined(OF_HAVE_IPX)
struct sockaddr_ipx {
	sa_family_t sipx_family;
	uint32_t sipx_network;
	unsigned char sipx_node[IPX_NODE_LEN];
	uint16_t sipx_port;
	uint8_t sipx_type;
};
#elif defined(OF_WINDOWS)
# define IPX_NODE_LEN 6
# define sipx_family sa_family
# define sipx_network sa_netnum
# define sipx_node sa_nodenum
# define sipx_port sa_socket
#elif defined(OF_FREEBSD)
# define sipx_network sipx_addr.x_net.c_net
# define sipx_node sipx_addr.x_host.c_host
#endif

#ifndef OF_HAVE_APPLETALK
struct sockaddr_at {
	sa_family_t sat_family;
	uint8_t sat_port;
	uint16_t sat_net;
	uint8_t sat_node;
};
#else
# ifdef OF_WINDOWS
#  define sat_port sat_socket
# else
#  define sat_net sat_addr.s_net
#  define sat_node sat_addr.s_node
# endif
#endif

/**
 * @struct OFSocketAddress OFSocket.h ObjFW/ObjFW.h
 *
 * @brief A struct which represents a host / port pair for a socket.
 */
typedef struct OF_BOXABLE OFSocketAddress {
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
		struct sockaddr_at at;
#ifdef OF_HAVE_SOCKADDR_STORAGE
		/*
		 * Required to make the ABI stable in case we want to add more
		 * address types later.
		 */
		struct sockaddr_storage storage;
#endif
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
 * @brief Creates an IPX address for the specified network, node and port.
 *
 * @param network The IPX network
 * @param node The node in the IPX network
 * @param port The IPX port (sometimes called socket number) on the node
 * @return An IPX socket address with the specified node, network and port.
 */
extern OFSocketAddress OFSocketAddressMakeIPX(uint32_t network,
    const unsigned char node[_Nonnull IPX_NODE_LEN], uint16_t port);

/**
 * @brief Creates an AppleTalk address for the specified network, node and port.
 *
 * @param network The AppleTalk network
 * @param node The node in the AppleTalk network
 * @param port The AppleTalk (sometimes called socket number) on the node
 * @return An AppleTalk socket address with the specified node, network and
 *	   port.
 */
extern OFSocketAddress OFSocketAddressMakeAppleTalk(uint16_t network,
    uint8_t node, uint8_t port);

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
 * @return The address as a string, without the port
 */
extern OFString *_Nonnull OFSocketAddressString(
    const OFSocketAddress *_Nonnull address);

/**
 * @brief Returns a description for the specified @ref OFSocketAddress.
 *
 * This is similar to @ref OFSocketAddressString, but it also contains the port.
 *
 * @param address The address to return a description for
 * @return The address as an string, with the port
 */
extern OFString *_Nonnull OFSocketAddressDescription(
    const OFSocketAddress *_Nonnull address);

/**
 * @brief Sets the IP port of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to set the port
 * @param port The port to set on the address
 */
extern void OFSocketAddressSetIPPort(OFSocketAddress *_Nonnull address,
    uint16_t port);

/**
 * @brief Returns the IP port of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to get the port
 * @return The port of the address
 */
extern uint16_t OFSocketAddressIPPort(const OFSocketAddress *_Nonnull address);

/**
 * @brief Gets the UNIX socket path of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to get the UNIX socket path
 * @return The UNIX socket path
 */
extern OFString *OFSocketAddressUNIXPath(
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

/**
 * @brief Sets the IPX port of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to set the port
 * @param port The port to set on the address
 */
extern void OFSocketAddressSetIPXPort(OFSocketAddress *_Nonnull address,
    uint16_t port);

/**
 * @brief Returns the IPX port of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to get the port
 * @return The port of the address
 */
extern uint16_t OFSocketAddressIPXPort(const OFSocketAddress *_Nonnull address);

/**
 * @brief Sets the AppleTalk network of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to set the AppleTalk network
 * @param network The AppleTalk network to set on the address
 */
extern void OFSocketAddressSetAppleTalkNetwork(
    OFSocketAddress *_Nonnull address, uint16_t network);

/**
 * @brief Returns the AppleTalk network of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to get the AppleTalk network
 * @return The AppleTalk network of the address
 */
extern uint16_t OFSocketAddressAppleTalkNetwork(
    const OFSocketAddress *_Nonnull address);

/**
 * @brief Sets the AppleTalk node of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to set the AppleTalk node
 * @param node The AppleTalk node to set on the address
 */
extern void OFSocketAddressSetAppleTalkNode(OFSocketAddress *_Nonnull address,
    uint8_t node);

/**
 * @brief Gets the AppleTalk node of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to get the AppleTalk node
 * @return The AppleTalk node of the address
 */
extern uint8_t OFSocketAddressAppleTalkNode(
    const OFSocketAddress *_Nonnull address);

/**
 * @brief Sets the AppleTalk port of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to set the port
 * @param port The port to set on the address
 */
extern void OFSocketAddressSetAppleTalkPort(OFSocketAddress *_Nonnull address,
    uint8_t port);

/**
 * @brief Returns the AppleTalk port of the specified @ref OFSocketAddress.
 *
 * @param address The address on which to get the port
 * @return The port of the address
 */
extern uint8_t OFSocketAddressAppleTalkPort(
    const OFSocketAddress *_Nonnull address);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
