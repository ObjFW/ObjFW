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

#import "OFSocket.h"
#import "OFString.h"

/**
 * The OFTCPSocket class provides functions to create and use sockets.
 */
@interface OFTCPSocket: OFSocket {}
/**
 * Connect the OFTCPSocket to the specified destination.
 *
 * \param service The service on the node to connect to
 * \param node The node to connect to
 */
- connectToService: (OFString*)service
	    onNode: (OFString*)node;

/**
 * Bind socket on the specified node and service.
 *
 * \param service The service to bind
 * \param node The node to bind to
 * \param family The family to use (AF_INET or AF_INET6)
 */
- bindService: (OFString*)service
       onNode: (OFString*)node
   withFamily: (int)family;

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
 * \return An autoreleased OFTCPSocket for the accepted connection.
 */
- (OFSocket*)accept;

/**
 * Enable or disable keep alives for the connection.
 */
- enableKeepAlives: (BOOL)enable;

/**
 * Closes the socket.
 */
- close;
@end
