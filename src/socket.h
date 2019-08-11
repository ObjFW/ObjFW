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

#include "objfw-defs.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

#include <stdbool.h>

#import "OFString.h"

#ifdef OF_HAVE_SYS_SOCKET_H
# include <sys/socket.h>
#endif
#ifdef OF_HAVE_NETINET_IN_H
# include <netinet/in.h>
#endif
#ifdef OF_HAVE_NETINET_TCP_H
# include <netinet/tcp.h>
#endif

#include "platform.h"

#ifdef OF_WINDOWS
# include <windows.h>
# include <ws2tcpip.h>
#endif

/*! @file */

#ifdef OF_WII
# include <network.h>
#endif

#ifdef OF_PSP
# include <stdint.h>
#endif

#import "macros.h"
#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS)
# import "tlskey.h"
#endif

OF_ASSUME_NONNULL_BEGIN

#ifndef OF_WINDOWS
typedef int of_socket_t;
#else
typedef SOCKET of_socket_t;
#endif

#ifdef OF_WII
typedef u8 sa_family_t;
#endif

#ifdef OF_MORPHOS
typedef long socklen_t;
typedef u_char sa_family_t;
typedef u_short in_port_t;
#endif

#ifdef OF_MORPHOS_IXEMUL
typedef int socklen_t;
#endif

/*!
 * @brief A socket address family.
 */
typedef enum {
	/** An unknown address family. */
	OF_SOCKET_ADDRESS_FAMILY_UNKNOWN,
	/** IPv4 */
	OF_SOCKET_ADDRESS_FAMILY_IPV4,
	/** IPv6 */
	OF_SOCKET_ADDRESS_FAMILY_IPV6,
	/** Any address family */
	OF_SOCKET_ADDRESS_FAMILY_ANY = 255
} of_socket_address_family_t;

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

/*!
 * @struct of_socket_address_t socket.h ObjFW/socket.h
 *
 * @brief A struct which represents a host / port pair for a socket.
 */
typedef struct OF_BOXABLE {
	/*
	 * Even though struct sockaddr contains the family, we need to use our
	 * own family, as we need to support storing an IPv6 address on systems
	 * that don't support IPv6. These may not have AF_INET6 defined and we
	 * can't just define it, as the value is system-dependent and might
	 * clash with an existing value.
	 */
	of_socket_address_family_t family;
	union {
		struct sockaddr sockaddr;
		struct sockaddr_in in;
		struct sockaddr_in6 in6;
	} sockaddr;
	socklen_t length;
} of_socket_address_t;

#ifdef __cplusplus
extern "C" {
#endif
/*!
 * @brief Parses the specified IP and port into an of_socket_address_t.
 *
 * @param IP The IP to parse
 * @param port The port to use
 * @return The parsed IP and port as an of_socket_address_t
 */
extern of_socket_address_t of_socket_address_parse_ip(
    OFString *IP, uint16_t port);

/*!
 * @brief Parses the specified IPv4 and port into an of_socket_address_t.
 *
 * @param IP The IPv4 to parse
 * @param port The port to use
 * @return The parsed IPv4 and port as an of_socket_address_t
 */
extern of_socket_address_t of_socket_address_parse_ipv4(
    OFString *IP, uint16_t port);

#ifdef OF_HAVE_IPV6
/*!
 * @brief Parses the specified IPv6 and port into an of_socket_address_t.
 *
 * @param IP The IPv6 to parse
 * @param port The port to use
 * @return The parsed IPv6 and port as an of_socket_address_t
 */
extern of_socket_address_t of_socket_address_parse_ipv6(
    OFString *IP, uint16_t port);
#endif

/*!
 * @brief Compares two of_socket_address_t for equality.
 *
 * @param address1 The address to compare with the second address
 * @param address2 The second address
 * @return Whether the two addresses are equal
 */
extern bool of_socket_address_equal(
    const of_socket_address_t *_Nonnull address1,
    const of_socket_address_t *_Nonnull address2);

/*!
 * @brief Returns the hash for the specified of_socket_address_t.
 *
 * @param address The address to hash
 * @return The hash for the specified of_socket_address_t
 */
extern uint32_t of_socket_address_hash(
    const of_socket_address_t *_Nonnull address);

/*!
 * @brief Converts the specified of_socket_address_t to an IP string and port.
 *
 * @param address The address to convert to a string
 * @param port A pointer to an uint16_t which should be set to the port of the
 *	       address or NULL if the port is not needed
 * @return The address as an IP string
 */
extern OFString *_Nonnull of_socket_address_ip_string(
    const of_socket_address_t *_Nonnull address, uint16_t *_Nullable port);

/*!
 * @brief Sets the port of the specified of_socket_address_t, independent of
 *	  the address family used.
 *
 * @param address The address on which to set the port
 * @param port The port to set on the address
 */
extern void of_socket_address_set_port(of_socket_address_t *_Nonnull address,
    uint16_t port);

/*!
 * @brief Returns the port of the specified of_socket_address_t, independent of
 *	  the address family used.
 *
 * @param address The address on which to get the port
 * @return The port of the address
 */
extern uint16_t of_socket_address_get_port(
    const of_socket_address_t *_Nonnull address);

extern bool of_socket_init(void);
#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS)
extern void of_socket_deinit(void);
#endif
extern int of_socket_errno(void);
#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
extern int of_getsockname(of_socket_t sock, struct sockaddr *restrict addr,
    socklen_t *restrict addrLen);
#endif

#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS)
extern of_tlskey_t of_socket_base_key;
# ifdef OF_AMIGAOS4
extern of_tlskey_t of_socket_interface_key;
# endif
#endif
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
