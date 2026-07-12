/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFGeminiRequest;
@class OFGeminiResponse;
@class OFGeminiServer;
@class OFStream;
@class OFTCPSocket;
@class OFX509Certificate;

/**
 * @protocol OFGeminiServerDelegate OFGeminiServer.h ObjFW/ObjFW.h
 *
 * @brief A delegate for OFGeminiServer.
 */
@protocol OFGeminiServerDelegate <OFObject>
/**
 * @brief This method is called when the Gemini server received a request from a
 *	  client.
 *
 * @param server The Gemini server which received the request
 * @param request The request the Gemini server received
 * @param requestBody A stream to read the body of the request from. Always
 *		      `nil` for Gemini requests and never `nil` for Titan
 *		      requests.
 * @param response The response the server will send to the client
 */
-      (void)server: (OFGeminiServer *)server
  didReceiveRequest: (OFGeminiRequest *)request
	requestBody: (nullable OFStream *)requestBody
	   response: (OFGeminiResponse *)response;

@optional
/**
 * @brief This method is called when the server encountered an exception.
 *
 * One common situation for this to happen is when the OFGeminiServer tries to
 * properly close the connection that the other end closed uncleanly.
 *
 * Another common situation is the TLS handshake failing, in which case
 * `request` and `response` will both be `nil`, as the connection never even
 * progressed far enough to create those.
 *
 * Another possibility is that the server failed to accept a socket.
 *
 * @param server The Gemini server which encountered an exception
 * @param exception The exception which occurred
 * @param request The requested for the response for which the exception
 *		  occurred, if any
 * @param response The response for which the exception occurred, if any
 */
-	   (void)server: (OFGeminiServer *)server
  didEncounterException: (id)exception
		request: (nullable OFGeminiRequest *)request
	       response: (nullable OFGeminiResponse *)response;
@end

/**
 * @class OFGeminiServer OFGeminiServer.h ObjFW/ObjFW.h
 *
 * @brief A class for creating a simple Gemini server inside of applications.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFGeminiServer: OFObject
{
	OFString *_Nullable _host;
	uint16_t _port;
	OFObject <OFGeminiServerDelegate> *_Nullable _delegate;
	OFTCPSocket *_Nullable _listeningSocket;
	OFArray OF_GENERIC(OFX509Certificate *) *_Nullable _certificateChain;
	OFTimeInterval _requestTimeout;
#ifdef OF_HAVE_THREADS
	size_t _numberOfThreads, _nextThreadIndex;
	OFArray *_threadPool;
#endif
}

/**
 * @brief The host on which the Gemini server will listen.
 *
 * @throw OFAlreadyOpenException The host could not be set because @ref start
 *				 had already been called
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *host;

/**
 * @brief The port on which the Gemini server will listen.
 *
 * @throw OFAlreadyOpenException The port could not be set because @ref start
 *				 had already been called
 */
@property (nonatomic) uint16_t port;

/**
 * @brief The certificate chain to use.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic)
    OFArray OF_GENERIC(OFX509Certificate *) *certificateChain;

/**
 * @brief The delegate for the Gemini server.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    OFObject <OFGeminiServerDelegate> *delegate;

/**
 * @brief The timeout (in seconds) for a request after which it gets canceled.
 *
 * Defaults to 3.0.
 */
@property (nonatomic) OFTimeInterval requestTimeout;

#ifdef OF_HAVE_THREADS
/**
 * @brief The number of threads the OFGeminiServer should use.
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
 * @brief Creates a new Gemini server.
 *
 * @return A new Gemini server
 */
+ (instancetype)server;

/**
 * @brief Starts the Gemini server in the current thread's run loop.
 *
 * @throw OFAlreadyOpenException The server had already been started
 */
- (void)start;

/**
 * @brief Stops the Gemini server, meaning it will not accept any new incoming
 *	  connections, but still handle existing connections until they are
 *	  finished or timed out.
 */
- (void)stop;
@end

OF_ASSUME_NONNULL_END
