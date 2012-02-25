/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#ifndef _WIN32
# include <sys/types.h>
# include <sys/socket.h>
# include <netdb.h>
#endif

#import "OFStreamSocket.h"

#ifdef _WIN32
# include <ws2tcpip.h>
#endif

@class OFString;

/**
 * \brief A class which provides functions to create and use TCP sockets.
 *
 * To connect to a server, create a socket and connect it.
 * To create a server, create a socket, bind it and listen on it.
 */
@interface OFTCPSocket: OFStreamSocket
{
	BOOL			listening;
	struct sockaddr_storage	*sockAddr;
	socklen_t		sockAddrLen;
	OFString		*SOCKS5Host;
	uint16_t		SOCKS5Port;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, getter=isListening) BOOL listening;
@property (copy) OFString *SOCKS5Host;
@property uint16_t SOCKS5Port;
#endif

/**
 * \brief Sets the global SOCKS5 proxy host to use when creating a new socket
 *
 * \param host The host to use as a SOCKS5 proxy when creating a new socket
 */
+ (void)setSOCKS5Host: (OFString*)host;

/**
 * \brief Returns the host to use as a SOCKS5 proxy when creating a new socket
 *
 * \return The host to use as a SOCKS5 proxy when creating a new socket
 */
+ (OFString*)SOCKS5Host;

/**
 * \brief Sets the global SOCKS5 proxy port to use when creating a new socket
 *
 * \param port The port to use as a SOCKS5 proxy when creating a new socket
 */
+ (void)setSOCKS5Port: (uint16_t)port;

/**
 * \brief Returns the port to use as a SOCKS5 proxy when creating a new socket
 *
 * \return The port to use as a SOCKS5 proxy when creating a new socket
 */
+ (uint16_t)SOCKS5Port;

/**
 * \brief Sets the host to use as a SOCKS5 proxy.
 *
 * \param host The host to use as a SOCKS5 proxy
 */
- (void)setSOCKS5Host: (OFString*)host;

/**
 * \brief Returns the host to use as a SOCKS5 proxy.
 *
 * \return The host to use as a SOCKS5 proxy
 */
- (OFString*)SOCKS5Host;

/**
 * \brief Sets the port to use on the SOCKS5 proxy.
 *
 * The default port is 1080.
 *
 * \param port The port to use on the SOCKS5 proxy
 */
- (void)setSOCKS5Port: (uint16_t)port;

/**
 * \brief Returns the port to use on the SOCKS5 proxy.
 *
 * \return The port to use on the SOCKS5 proxy
 */
- (uint16_t)SOCKS5Port;

/**
 * \brief Connect the OFTCPSocket to the specified destination.
 *
 * \param host The host to connect to
 * \param port The port on the host to connect to
 */
- (void)connectToHost: (OFString*)host
		 port: (uint16_t)port;

/**
 * \brief Bind the socket on the specified port and host.
 *
 * \param host The host to bind to. Use @"0.0.0.0" for IPv4 or @"::" for IPv6
 *	       to bind to all.
 * \param port The port to bind to. If the port is 0, an unused port will be
 *	       chosen, which can be obtained using the return value.
 * \return The port the socket was bound to
 */
- (uint16_t)bindToHost: (OFString*)host
		  port: (uint16_t)port;

/**
 * \brief Listen on the socket.
 *
 * \param backlog Maximum length for the queue of pending connections.
 */
- (void)listenWithBackLog: (int)backLog;

/**
 * \brief Listen on the socket.
 */
- (void)listen;

/**
 * \brief Accept an incoming connection.
 *
 * \return An autoreleased OFTCPSocket for the accepted connection.
 */
- (OFTCPSocket*)accept;

/**
 * \brief Enable or disable keep alives for the connection.
 *
 * \param enable Whether to enable or disable keep alives for the connection
 */
- (void)setKeepAlivesEnabled: (BOOL)enable;

/**
 * \brief Returns the remote address of the socket.
 *
 * Only works with accepted sockets!
 *
 * \return The remote address as a string
 */
- (OFString*)remoteAddress;

/**
 * \brief Returns whether the socket is a listening socket.
 *
 * \return Whether the socket is a listening socket
 */
- (BOOL)isListening;
@end
