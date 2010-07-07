/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
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
 */
@interface OFTCPSocket: OFStreamSocket
{
	struct sockaddr	*sockAddr;
	socklen_t	sockAddrLen;
}

/**
 * Connect the OFTCPSocket to the specified destination.
 *
 * \param service The service on the node to connect to
 * \param node The node to connect to
 */
- (void)connectToService: (OFString*)service
		  onNode: (OFString*)node;

/**
 * Bind socket on the specified node and service.
 *
 * \param service The service to bind
 * \param node The node to bind to
 * \param family The family to use (AF_INET for IPv4 or AF_INET6 for IPv6)
 */
- (void)bindService: (OFString*)service
	     onNode: (OFString*)node
	 withFamily: (int)family;

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
 * \return The remote address as a string.
 */
- (OFString*)remoteAddress;
@end
