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
#import "OFRunLoop.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFGeminiClient;
@class OFGeminiResponse;
@class OFStream;
@class OFTCPSocket;
@class OFTLSStream;

/**
 * @protocol OFGeminiClientDelegate OFGeminiClient.h ObjFW/ObjFW.h
 *
 * @brief A delegate for OFGeminiClient.
 */
@protocol OFGeminiClientDelegate <OFObject>
/**
 * @brief A callback which is called when an @ref OFGeminiClient performed a
 *	  request.
 *
 * @param client The OFGeminiClient which performed the request
 * @param IRI The requested IRI
 * @param response The response to the request performed, or nil on error
 * @param exception An exception if the request failed, or nil on success
 */
-	     (void)client: (OFGeminiClient *)client
  didPerformRequestForIRI: (OFIRI *)IRI
		 response: (nullable OFGeminiResponse *)response
		exception: (nullable id)exception;

@optional
/**
 * @brief A callback which is called when an @ref OFGeminiResponse creates a TCP
 *	  socket.
 *
 * This can be used to tell the socket about a SOCKS5 proxy it should use for
 * this connection.
 *
 * @param client The OFGeminiClient that created a TCP socket
 * @param TCPSocket The socket created by the OFGeminiClient
 * @param IRI The IRI for which the TCP socket was created
 */
-	(void)client: (OFGeminiClient *)client
  didCreateTCPSocket: (OFTCPSocket *)TCPSocket
		 IRI: (OFIRI *)IRI;

/**
 * @brief A callback which is called when an @ref OFGeminiClient creates a TLS
 *	  stream.
 *
 * This can be used to tell the TLS stream about a client certificate it should
 * use before performing the TLS handshake.
 *
 * @param client The OFGeminiClient that created a TLS stream
 * @param TLSStream The TLS stream created by the OFGeminiClient
 * @param IRI The IRI for which the TLS stream was created
 */
-	(void)client: (OFGeminiClient *)client
  didCreateTLSStream: (OFTLSStream *)TLSStream
		 IRI: (OFIRI *)IRI;

/**
 * @brief A callback which is called when an @ref OFGeminiClient wants to follow
 *	  a redirect.
 *
 * This callback will only be called if the OFGeminiClient will follow a
 * redirect. If the maximum number of redirects has been reached already, this
 * callback will not be called.
 *
 * @param client The OFGeminiClient which wants to follow a redirect
 * @param toIRI The IRI to which it will follow a redirect
 * @param fromIRI The IRI for which the OFGeminiClient wants to redirect
 * @param statusCode The status code for the redirection
 * @return A boolean whether the OFGeminiClient should follow the redirect
 */
-	       (bool)client: (OFGeminiClient *)client
  shouldFollowRedirectToIRI: (OFIRI *)toIRI
		    fromIRI: (OFIRI *)fromIRI
		 statusCode: (unsigned char)statusCode;
@end

/**
 * @class OFGeminiClient OFGeminiClient.h ObjFW/ObjFW.h
 *
 * @brief A class for performing Gemini requests.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFGeminiClient: OFObject
{
#ifdef OF_GEMINI_CLIENT_M
@public
#endif
	OFObject <OFGeminiClientDelegate> *_Nullable _delegate;
	bool _inProgress;
	OFStream *_streamToCancel;
}

/**
 * @brief The delegate of the Gemini client.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    OFObject <OFGeminiClientDelegate> *delegate;

/**
 * @brief Creates a new OFGeminiClient.
 *
 * @return A new, autoreleased OFGeminiClient.
 */
+ (instancetype)client;

/**
 * @brief Synchronously performs a request for the specified IRI.
 *
 * @note You must not change the delegate while a Synchronous request is
 *	 running! If you want to change the delegate during the request,
 *	 perform an asynchronous request instead!
 *
 * @param IRI The IRI to request
 * @return The OFGeminiResponse for the requested IRI
 * @throw OFGeminiRequestFailedException The Gemini request failed
 * @throw OFInvalidServerResponseException The server sent an invalid responsse
 * @throw OFAlreadyOpenException The client is already performing a request
 */
- (OFGeminiResponse *)performRequestForIRI: (OFIRI *)IRI;

/**
 * @brief Synchronously performs a request for the specified IRI.
 *
 * @note You must not change the delegate while a Synchronous request is
 *	 running! If you want to change the delegate during the request,
 *	 perform an asynchronous request instead!
 *
 * @param IRI The IRI to request
 * @param redirects The maximum number of redirects after which no further
 *		    attempt is done to follow the redirect, but instead the
 *		    request fails
 * @return The OFGeminiResponse for the requested IRI
 * @throw OFGeminiRequestFailedException The Gemini request failed
 * @throw OFInvalidServerResponseException The server sent an invalid responsse
 * @throw OFAlreadyOpenException The client is already performing a request
 */
- (OFGeminiResponse *)performRequestForIRI: (OFIRI *)IRI
				 redirects: (unsigned int)redirects;

/**
 * @brief Asynchronously performs a request for the specified IRI.
 *
 * @param IRI The IRI to request
 * @throw OFAlreadyOpenException The client is already performing a request
 */
- (void)asyncPerformRequestForIRI: (OFIRI *)IRI;

/**
 * @brief Asynchronously performs a request for the specified IRI.
 *
 * @param IRI The IRI to request
 * @param redirects The maximum number of redirects after which no further
 *		    attempt is done to follow the redirect, but instead the
 *		    request fails
 * @throw OFAlreadyOpenException The client is already performing a request
 */
- (void)asyncPerformRequestForIRI: (OFIRI *)IRI
			redirects: (unsigned int)redirects;

/**
 * @brief Asynchronously performs a request for the specified IRI.
 *
 * @param IRI The IRI to request
 * @param redirects The maximum number of redirects after which no further
 *		    attempt is done to follow the redirect, but instead the
 *		    request fails
 * @param runLoopMode The run loop mode in which to perform the request
 * @throw OFAlreadyOpenException The client is already performing a request
 */
- (void)asyncPerformRequestForIRI: (OFIRI *)IRI
			redirects: (unsigned int)redirects
		      runLoopMode: (OFRunLoopMode)runLoopMode;

/**
 * @brief Cancels all pending asynchronous requests.
 */
- (void)cancelAsyncRequests;
@end

OF_ASSUME_NONNULL_END
