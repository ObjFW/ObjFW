/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "OFObject.h"

@class OFHTTPServer;
@class OFHTTPRequest;
@class OFHTTPRequestReply;
@class OFTCPSocket;
@class OFException;

/*!
 * @brief A delegate for OFHTTPServer.
 */
@protocol OFHTTPServerDelegate <OFObject>
/*!
 * @brief This method is called when the HTTP server received a request from a
 *	  client.
 *
 * @param server The HTTP server which received the request
 * @param request The request the HTTP server received
 * @param reply The reply the server wants to send to the client
 */
-      (void)server: (OFHTTPServer*)server
  didReceiveRequest: (OFHTTPRequest*)request
	      reply: (OFHTTPRequestReply*)reply;

#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif
/*!
 * @brief This method is called when the HTTP server's listening socket
 *	  encountered an exception.
 *
 * @param server The HTTP server which encountered an exception
 * @param exception The exception that occurred on the HTTP server's listening
 *		    socket
 * @return Whether to continue listening. If you return NO, existing connections
 *	   will still be handled and you can start accepting new connections
 *	   again by calling @ref OFHTTPServer::start again.
 */
-			  (BOOL)server: (OFHTTPServer*)server
  didReceiveExceptionOnListeningSocket: (OFException*)exception;
@end

/*!
 * @brief A class for creating a simple HTTP server inside of applications.
 */
@interface OFHTTPServer: OFObject
{
	OFString *host;
	uint16_t port;
	id <OFHTTPServerDelegate> delegate;
	OFString *name;
	OFTCPSocket *listeningSocket;
}

#ifdef OF_HAVE_PROPERTIES
@property (copy) OFString *host;
@property uint16_t port;
@property (assign) id <OFHTTPServerDelegate> delegate;
@property (copy) OFString *name;
#endif

/*!
 * @brief Creates a new HTTP server.
 *
 * @return A new HTTP server
 */
+ (instancetype)server;

/*!
 * @brief Sets the host on which the HTTP server will listen.
 *
 * @param host The host to listen on
 */
- (void)setHost: (OFString*)host;

/*!
 * @brief Returns the host on which the HTTP server will listen.
 *
 * @return The host on which the HTTP server will listen
 */
- (OFString*)host;

/*!
 * @brief Sets the port on which the HTTP server will listen.
 *
 * @param port The port to listen on
 */
- (void)setPort: (uint16_t)port;

/*!
 * @brief Returns the port on which the HTTP server will listen.
 *
 * @return The port on which the HTTP server will listen
 */
- (uint16_t)port;

/*!
 * @brief Sets the delegate for the HTTP server.
 *
 * @param delegate The delegate for the HTTP server
 */
- (void)setDelegate: (id <OFHTTPServerDelegate>)delegate;

/*!
 * @brief Returns the delegate for the HTTP server.
 *
 * @return The delegate for the HTTP server
 */
- (id <OFHTTPServerDelegate>)delegate;

/*!
 * @brief Sets the server name the server presents to clients.
 *
 * @param name The server name to present to clients
 */
- (void)setName: (OFString*)name;

/*!
 * @brief Returns the server name the server presents to clients.
 *
 * @return The server name the server presents to clients
 */
- (OFString*)name;

/*!
 * @brief Starts the HTTP server in the current thread's runloop.
 */
- (void)start;

/*!
 * @brief Stops the HTTP server, meaning it will not accept any new incoming
 *	  connections, but still handle existing connections until they are
 *	  finished or timed out.
 */
- (void)stop;

- (BOOL)OF_socket: (OFTCPSocket*)socket
  didAcceptSocket: (OFTCPSocket*)clientSocket
	exception: (OFException*)exception;
@end

@interface OFObject (OFHTTPServerDelegate) <OFHTTPServerDelegate>
@end
