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

#include "config.h"

/* Work around __block being used by glibc */
#ifdef __GLIBC__
# undef __USE_XOPEN
#endif

#include <unistd.h>

#ifdef HAVE_ARPA_INET_H
# include <arpa/inet.h>
#endif
#ifdef HAVE_NETDB_H
# include <netdb.h>
#endif

#include "socket.h"

#ifndef INVALID_SOCKET
# define INVALID_SOCKET -1
#endif

#ifdef HAVE_GETADDRINFO
# ifndef AI_NUMERICSERV
#  define AI_NUMERICSERV 0
# endif
# ifndef AI_NUMERICHOST
#  define AI_NUMERICHOST 0
# endif
#endif

#ifndef INADDR_NONE
# define INADDR_NONE ((in_addr_t)-1)
#endif

#ifndef SOMAXCONN
/*
 * Use 16 as everything > 17 fails on Nintendo 3DS and 16 is a less arbitrary
 * number than 17.
 */
# define SOMAXCONN 16
#endif

#ifndef SOCK_CLOEXEC
# define SOCK_CLOEXEC 0
#endif

#ifdef OF_WINDOWS
# define close(sock) closesocket(sock)
#endif

#ifdef OF_MORPHOS
typedef uint32_t in_addr_t;
#endif

#ifdef OF_WII
# define accept(sock, addr, addrlen) net_accept(sock, addr, addrlen)
# define bind(sock, addr, addrlen) net_bind(sock, addr, addrlen)
# define close(sock) net_close(sock)
# define connect(sock, addr, addrlen) net_connect(sock, addr, addrlen)
# define gethostbyname(name) net_gethostbyname(name)
# define h_errno 0
# define hstrerror(err) "unknown (no hstrerror)"
# define listen(sock, backlog) net_listen(sock, backlog)
# define poll(fds, nfds, timeout) net_poll(fds, nfds, timeout)
# define recv(sock, buf, len, flags) net_recv(sock, buf, len, flags)
# define recvfrom(sock, buf, len, flags, addr, addrlen) \
    net_recvfrom(sock, buf, len, flags, addr, addrlen)
# define select(nfds, readfds, writefds, errorfds, timeout) \
    net_select(nfds, readfds, writefds, errorfds, timeout)
# define send(sock, buf, len, flags) net_send(sock, buf, len, flags)
# define sendto(sock, buf, len, flags, addr, addrlen) \
    net_sendto(sock, buf, len, flags, addr, addrlen)
# define setsockopt(sock, level, name, value, len) \
    net_setsockopt(sock, level, name, value, len)
# define socket(domain, type, proto) net_socket(domain, type, proto)
typedef u32 in_addr_t;
typedef u32 nfds_t;
#endif
