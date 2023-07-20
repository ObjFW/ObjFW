/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFArray;
@class OFHTTPRequest;
@class OFHTTPResponse;
@class OFHTTPServer;
@class OFStream;
@class OFTCPSocket;

/**
 * @protocol OFHTTPServerDelegate OFHTTPServer.h ObjFW/OFHTTPServer.h
 *
 * @brief A delegate for OFHTTPServer.
 */
@protocol OFHTTPServerDelegate <OFObject>
/**
 * @brief This method is called when the HTTP server received a request from a
 *	  client.
 *
 * @param server The HTTP server which received the request
 * @param request The request the HTTP server received
 * @param requestBody A stream to read the body of the request from, if any
 * @param response The response the server will send to the client
 */
-      (void)server: (OFHTTPServer *)server
  didReceiveRequest: (OFHTTPRequest *)request
	requestBody: (nullable OFStream *)requestBody
	   response: (OFHTTPResponse *)response;

@optional
/**
 * @brief This method is called when the HTTP server's listening socket
 *	  encountered an exception.
 *
 * @param server The HTTP server which encountered an exception
 * @param exception The exception which occurred on the HTTP server's listening
 *		    socket
 * @return Whether to continue listening. If you return false, existing
 *	   connections will still be handled and you can start accepting new
 *	   connections again by calling @ref OFHTTPServer::start again.
 */
-			  (bool)server: (OFHTTPServer *)server
  didReceiveExceptionOnListeningSocket: (id)exception;

/**
 * @brief This method is called when a socket for a client encountered an
 * exception.
 *
 * This can happen when the OFHTTPServer tries to properly close the
 * connection. If no headers have been sent yet, it will send headers, and if
 * chunked transfer encoding was used, it will send a chunk of size 0. However,
 * if the other end already closed the connection before that, this will raise
 * an exception.
 *
 * @param server The HTTP server which encountered an exception
 * @param response The response for which the exception occurred
 * @param request The request for the response for which the exception occurred
 * @param exception The exception which occurred
 */
-		    (void)server: (OFHTTPServer *)server
  didReceiveExceptionForResponse: (OFHTTPResponse *)response
			 request: (OFHTTPRequest *)request
		       exception: (id)exception;
@end

/**
 * @class OFHTTPServer OFHTTPServer.h ObjFW/OFHTTPServer.h
 *
 * @brief A class for creating a simple HTTP server inside of applications.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFHTTPServer: OFObject
{
	OFString *_Nullable _host;
	uint16_t _port;
	id <OFHTTPServerDelegate> _Nullable _delegate;
	OFString *_Nullable _name;
	OFTCPSocket *_Nullable _listeningSocket;
#ifdef OF_HAVE_THREADS
	size_t _numberOfThreads, _nextThreadIndex;
	OFArray *_threadPool;
#endif
}

/**
 * @brief The host on which the HTTP server will listen.
 *
 * @throw OFAlreadyOpenException The host could not be set because @ref start
 *				  had already been called
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *host;

/**
 * @brief The port on which the HTTP server will listen.
 *
 * @throw OFAlreadyOpenException The port could not be set because @ref start
 *				 had already been called
 */
@property (nonatomic) uint16_t port;

/**
 * @brief The delegate for the HTTP server.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFHTTPServerDelegate> delegate;

#ifdef OF_HAVE_THREADS
/**
 * @brief The number of threads the OFHTTPServer should use.
 *
 * If this is larger than 1 (the default), one thread will be used to accept
 * incoming connections and all others will be used to handle connections.
 *
 * For maximum CPU utilization, set this to `[OFSystemInfo numberOfCPUs] + 1`.
 *
 * @throw OFAlreadyOpenException The number of threads could not be set because
 *				 @ref start had already been called
 */
@property (nonatomic) size_t numberOfThreads;
#endif

/**
 * @brief The server name the server presents to clients.
 *
 * Setting it to `nil` means no `Server` header will be sent, unless one is
 * specified in the response headers.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *name;

/**
 * @brief Creates a new HTTP server.
 *
 * @return A new HTTP server
 */
+ (instancetype)server;

/**
 * @brief Starts the HTTP server in the current thread's run loop.
 *
 * @throw OFAlreadyOpenException The server had already been started
 */
- (void)start;

/**
 * @brief Stops the HTTP server, meaning it will not accept any new incoming
 *	  connections, but still handle existing connections until they are
 *	  finished or timed out.
 */
- (void)stop;
@end

OF_ASSUME_NONNULL_END
