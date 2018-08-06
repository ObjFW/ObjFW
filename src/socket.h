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

#include "objfw-defs.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

#include <stdbool.h>

#import "platform.h"

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
# ifdef __MINGW32__
#  include <_mingw.h>
#  ifdef __MINGW64_VERSION_MAJOR
#   include <winsock2.h>
#  endif
# endif
# include <windows.h>
# include <ws2tcpip.h>
#endif

/*! @file */

#if defined(OF_AMIGAOS) && defined(OF_MORPHOS_IXEMUL)
struct sockaddr_storage {
	uint8_t ss_len;
	sa_family_t ss_family;
	char ss_data[2 + sizeof(struct in_addr) + 8];
};
#endif

#ifdef OF_MORPHOS
typedef long socklen_t;
#endif
#ifdef OF_MORPHOS_IXEMUL
typedef int socklen_t;
#endif

#ifdef OF_WII
# include <network.h>

struct sockaddr_storage {
	u8 ss_len;
	sa_family_t ss_family;
	u8 ss_data[14];
};
#endif

#ifdef OF_PSP
# include <stdint.h>

struct sockaddr_storage {
	uint8_t	       ss_len;
	sa_family_t    ss_family;
	in_port_t      ss_data1;
	struct in_addr ss_data2;
	int8_t	       ss_data3[8];
};
#endif

#import "macros.h"

OF_ASSUME_NONNULL_BEGIN

#ifndef OF_WINDOWS
typedef int of_socket_t;
#else
typedef SOCKET of_socket_t;
#endif

/*!
 * @struct of_socket_address_t socket.h ObjFW/socket.h
 *
 * @brief A struct which represents a host / port pair for a socket.
 */
typedef struct OF_BOXABLE {
	struct sockaddr_storage address;
	socklen_t length;
} of_socket_address_t;

#ifdef __cplusplus
extern "C" {
#endif
extern bool of_socket_init(void);
extern int of_socket_errno(void);
# ifndef OF_WII
extern int of_getsockname(of_socket_t sock, struct sockaddr *restrict addr,
    socklen_t *restrict addrLen);
# endif

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
extern bool of_socket_address_equal(of_socket_address_t *address1,
    of_socket_address_t *address2);

/*!
 * @brief Returns the hash for the specified of_socket_address_t.
 *
 * @param address The address to hash
 * @return The hash for the specified of_socket_address_t
 */
extern uint32_t of_socket_address_hash(of_socket_address_t *address);

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
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
