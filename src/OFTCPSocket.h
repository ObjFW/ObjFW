/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import <stdio.h>

/*
 * Headers for UNIX systems
 */
#ifndef _WIN32
#import <sys/types.h>
#import <sys/socket.h>
#import <netdb.h>
#endif

#import "OFObject.h"
#import "OFStream.h"

/*
 * Headers for Win32
 *
 * These must be imported after objc/Object and thus OFObject!
 */
#ifdef _WIN32
#define _WIN32_WINNT 0x0501
#import <winsock2.h>
#import <ws2tcpip.h>
#endif

/**
 * The OFTCPSocket class provides functions to create and use sockets.
 */
@interface OFTCPSocket: OFObject <OFStream>
{
#ifndef _WIN32
	int	  sock;
#else
	SOCKET	  sock;
#endif
	struct	  sockaddr *saddr;
	socklen_t saddr_len;
}

/**
 * Initializes an already allocated OFTCPSocket.
 *
 * \return An initialized OFTCPSocket
 */
- init;

- free;

/**
 * Connect the OFTCPSocket to the specified destination.
 *
 * \param host The host or IP to connect to
 * \param port The port of the host to connect to
 */
- connectTo: (const char*)host
     onPort: (uint16_t)port;

/**
 * Bind socket to the specified address and port.
 *
 * \param host The host or IP to bind to
 * \param port The port to bind to
 * \param protocol The protocol to use (AF_INET or AF_INET6)
 */
-    bindOn: (const char*)host
   withPort: (uint16_t)port
  andFamily: (int)family;

/**
 * Listen on the socket.
 *
 * \param backlog Maximum length for the queue of pending connections.
 */
- listenWithBackLog: (int)backlog;

/**
 * Listen on the socket.
 */
- listen;

/**
 * Accept an incoming connection.
 */
- (OFTCPSocket*)accept;

/**
 * Enables/disables non-blocking I/O.
 */
- setBlocking: (BOOL)enable;

/**
 * Enable or disable keep alives for the connection.
 */
- enableKeepAlives: (BOOL)enable;

/**
 * Closes the socket.
 */
- close;
@end
