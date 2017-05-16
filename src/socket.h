/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#ifdef OF_MORPHOS
/* Strangely, MorphOS defines socklen_t in pthread.h */
# include <pthread.h>

struct sockaddr_storage {
	uint8_t ss_len;
	uint8_t ss_family;
	char ss_data[2 + sizeof(struct in_addr) + 8];
};
#endif

#ifdef OF_WII
# define BOOL OGC_BOOL
# include <network.h>
# undef BOOL

struct sockaddr_storage {
	u8 ss_len;
	u8 ss_family;
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

#ifdef __cplusplus
extern "C" {
#endif
extern bool of_socket_init(void);
extern int of_socket_errno(void);
# ifndef OF_WII
extern int of_getsockname(of_socket_t socket, struct sockaddr *restrict address,
    socklen_t *restrict address_len);
# endif
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
