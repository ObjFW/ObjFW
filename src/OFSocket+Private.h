/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#include "unistd_wrapper.h"

#ifdef HAVE_ARPA_INET_H
# include <arpa/inet.h>
#endif
#ifdef HAVE_NETDB_H
# include <netdb.h>
#endif

#import "OFSocket.h"

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

#if defined(OF_AMIGAOS)
# ifdef OF_MORPHOS
#  include <proto/socket.h>
# else
#  include <proto/bsdsocket.h>
# endif
# include <sys/filio.h>
# define closesocket(sock) CloseSocket(sock)
# define ioctlsocket(fd, req, arg) IoctlSocket(fd, req, arg)
# define hstrerror(err) "unknown (no hstrerror)"
# define SOCKET_ERROR -1
# if defined(OF_HAVE_THREADS) && !defined(OF_MORPHOS)
#  define SocketBase ((struct Library *)OFTLSKeyGet(_OFSocketBaseKey))
#  ifdef OF_AMIGAOS4
#   define ISocket ((struct SocketIFace *)OFTLSKeyGet(_OFSocketInterfaceKey))
#  endif
# endif
# ifdef OF_MORPHOS
typedef uint32_t in_addr_t;
# endif
#elif !defined(OF_WINDOWS) && !defined(OF_WII)
# define closesocket(sock) close(sock)
#endif

#ifdef OF_WII
# define accept(sock, addr, addrlen) net_accept(sock, addr, addrlen)
# define bind(sock, addr, addrlen) net_bind(sock, addr, addrlen)
# define closesocket(sock) net_close(sock)
# define connect(sock, addr, addrlen) \
    net_connect(sock, (struct sockaddr *)addr, addrlen)
# define fcntl(fd, cmd, flags) net_fcntl(fd, cmd, flags)
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
    net_sendto(sock, buf, len, flags, (struct sockaddr *)(addr), addrlen)
# define setsockopt(sock, level, name, value, len) \
    net_setsockopt(sock, level, name, value, len)
# define socket(domain, type, proto) net_socket(domain, type, proto)
typedef u32 in_addr_t;
typedef u32 nfds_t;
#endif

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern bool _OFSocketInit(void) OF_VISIBILITY_HIDDEN;
#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS) && !defined(OF_MORPHOS)
extern void _OFSocketDeinit(void) OF_VISIBILITY_HIDDEN;
#endif
extern int _OFSocketErrNo(void) OF_VISIBILITY_HIDDEN;
#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
extern int _OFGetSockName(OFSocketHandle sock, struct sockaddr *restrict addr,
    socklen_t *restrict addrLen) OF_VISIBILITY_HIDDEN;
#endif

#if defined(OF_HAVE_THREADS) && defined(OF_AMIGAOS) && !defined(OF_MORPHOS)
extern OFTLSKey _OFSocketBaseKey OF_VISIBILITY_HIDDEN;
# ifdef OF_AMIGAOS4
extern OFTLSKey _OFSocketInterfaceKey OF_VISIBILITY_HIDDEN;
# endif
#endif
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
