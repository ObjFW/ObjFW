/*
 * Copyright (c) 2008, 2009, 2010, 2011
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
	BOOL			isListening;
	struct sockaddr_storage	*sockAddr;
	socklen_t		sockAddrLen;
}

/**
 * Connect the OFTCPSocket to the specified destination.
 *
 * \param host The host to connect to
 * \param port The port on the host to connect to
 */
- (void)connectToHost: (OFString*)host
	       onPort: (uint16_t)port;

/**
 * Bind the socket on the specified port and host.
 *
 * \param port The port to bind to. If the port is 0, an unused port will be
 *	       chosen, which can be obtained using the return value.
 * \param host The host to bind to. Use @"0.0.0.0" for IPv4 or @"::" for IPv6
 *	       to bind to all.
 * \return The port the socket was bound to
 */
- (uint16_t)bindToPort: (uint16_t)port
		onHost: (OFString*)host;

/**
 * Listen on the socket.
 *
 * \param backlog Maximum length for the queue of pending connections.
 */
- (void)listenWithBackLog: (int)backlog;

/**
 * Listen on the socket.
 */
- (void)listen;

/**
 * Accept an incoming connection.
 * \return An autoreleased OFTCPSocket for the accepted connection.
 */
- (OFTCPSocket*)accept;

/**
 * Enable or disable keep alives for the connection.
 */
- (void)setKeepAlivesEnabled: (BOOL)enable;

/**
 * Returns the remote address of the socket. Only works with accepted sockets!
 *
 * \return The remote address as a string
 */
- (OFString*)remoteAddress;

/**
 * \return Whether the socket is a listening socket
 */
- (BOOL)isListening;
@end
