/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

/*
 * Headers for UNIX systems
 */
#ifndef _WIN32
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#endif

#import "OFStream.h"

/*
 * Headers for Win32
 *
 * These must be imported after objc/objc.h and thus OFObject!
 */
#ifdef _WIN32
#define _WIN32_WINNT 0x0501
#include <winsock2.h>
#include <ws2tcpip.h>
#endif

/**
 * The OFTCPSocket class provides functions to create and use sockets.
 */
@interface OFSocket: OFStream
{
#ifndef _WIN32
	int		sock;
#else
	SOCKET		sock;
#endif
	struct sockaddr	*saddr;
	socklen_t	saddr_len;
	BOOL		eos;
}

/**
 * \return A new autoreleased OFTCPSocket
 */
+ socket;

/**
 * Enables/disables non-blocking I/O.
 */
- setBlocking: (BOOL)enable;

- connectToService: (OFString*)service
	    onNode: (OFString*)node;
- bindService: (OFString*)service
       onNode: (OFString*)node
   withFamily: (int)family;
- listenWithBackLog: (int)backlog;
- listen;
- (OFSocket*)accept;
- enableKeepAlives: (BOOL)enable;
- close;
@end
