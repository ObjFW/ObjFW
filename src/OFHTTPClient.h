/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFHTTPClient;
@class OFHTTPRequest;
@class OFHTTPResponse;
@class OFIRI;
@class OFStream;
@class OFTCPSocket;
@class OFTLSStream;

/**
 * @protocol OFHTTPClientDelegate OFHTTPClient.h ObjFW/ObjFW.h
 *
 * @brief A delegate for OFHTTPClient.
 */
@protocol OFHTTPClientDelegate <OFObject>
/**
 * @brief A callback which is called when an @ref OFHTTPClient performed a
 *	  request.
 *
 * @param client The OFHTTPClient which performed the request
 * @param request The request the OFHTTPClient performed
 * @param response The response to the request performed, or nil on error
 * @param exception An exception if the request failed, or nil on success
 */
-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
	   response: (nullable OFHTTPResponse *)response
	  exception: (nullable id)exception;

@optional
/**
 * @brief A callback which is called when an @ref OFHTTPClient creates a TCP
 *	  socket.
 *
 * This can be used to tell the socket about a SOCKS5 proxy it should use for
 * this connection.
 *
 * @param client The OFHTTPClient that created a TCP socket
 * @param TCPSocket The socket created by the OFHTTPClient
 * @param request The request for which the TCP socket was created
 */
-	(void)client: (OFHTTPClient *)client
  didCreateTCPSocket: (OFTCPSocket *)TCPSocket
	     request: (OFHTTPRequest *)request;

/**
 * @brief A callback which is called when an @ref OFHTTPClient creates a TLS
 *	  stream.
 *
 * This can be used to tell the TLS stream about a client certificate it should
 * use before performing the TLS handshake.
 *
 * @param client The OFHTTPClient that created a TLS stream
 * @param TLSStream The TLS stream created by the OFHTTPClient
 * @param request The request for which the TLS stream was created
 */
-	(void)client: (OFHTTPClient *)client
  didCreateTLSStream: (OFTLSStream *)TLSStream
	     request: (OFHTTPRequest *)request;

/**
 * @brief A callback which is called when an @ref OFHTTPClient wants to send
 *	  the body for a request.
 *
 * @param client The OFHTTPClient that wants to send the body
 * @param requestBody A stream into which the body of the request should be
 *		      written
 * @param request The request for which the OFHTTPClient wants to send the body
 */
-     (void)client: (OFHTTPClient *)client
  wantsRequestBody: (OFStream *)requestBody
	   request: (OFHTTPRequest *)request;

/**
 * @brief A callback which is called when an @ref OFHTTPClient received headers.
 *
 * @param client The OFHTTPClient which received the headers
 * @param headers The headers received
 * @param statusCode The status code received
 * @param request The request for which the headers and status code have been
 *		  received
 */
-      (void)client: (OFHTTPClient *)client
  didReceiveHeaders: (OFDictionary OF_GENERIC(OFString *, OFString *) *)headers
	 statusCode: (short)statusCode
	    request: (OFHTTPRequest *)request;

/**
 * @brief A callback which is called when an @ref OFHTTPClient wants to follow
 *	  a redirect.
 *
 * If you want to get the headers and data for each redirect, set the number of
 * redirects to 0 and perform a new OFHTTPClient for each redirect. However,
 * this callback will not be called then and you have to look at the status code
 * to detect a redirect.
 *
 * This callback will only be called if the OFHTTPClient will follow a
 * redirect. If the maximum number of redirects has been reached already, this
 * callback will not be called.
 *
 * @param client The OFHTTPClient which wants to follow a redirect
 * @param IRI The IRI to which it will follow a redirect
 * @param statusCode The status code for the redirection
 * @param request The request for which the OFHTTPClient wants to redirect.
 *		  You are allowed to change the request's headers from this
 *		  callback and they will be used when following the redirect
 *		  (e.g. to set the cookies for the new IRI), however, keep in
 *		  mind that this will change the request you originally passed.
 * @param response The response indicating the redirect
 * @return A boolean whether the OFHTTPClient should follow the redirect
 */
-	       (bool)client: (OFHTTPClient *)client
  shouldFollowRedirectToIRI: (OFIRI *)IRI
		 statusCode: (short)statusCode
		    request: (OFHTTPRequest *)request
		   response: (OFHTTPResponse *)response;
@end

/**
 * @class OFHTTPClient OFHTTPClient.h ObjFW/ObjFW.h
 *
 * @brief A class for performing HTTP requests.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFHTTPClient: OFObject
{
#ifdef OF_HTTP_CLIENT_M
@public
#endif
	OFObject <OFHTTPClientDelegate> *_Nullable _delegate;
	bool _allowsInsecureRedirects, _inProgress;
	OFStream *_Nullable _stream;
	OFIRI *_Nullable _lastIRI;
	bool _lastWasHEAD;
	OFHTTPResponse *_Nullable _lastResponse;
}

/**
 * @brief The delegate of the HTTP request.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    OFObject <OFHTTPClientDelegate> *delegate;

/**
 * @brief Whether the HTTP client allows redirects from HTTPS to HTTP.
 */
@property (nonatomic) bool allowsInsecureRedirects;

/**
 * @brief Creates a new OFHTTPClient.
 *
 * @return A new, autoreleased OFHTTPClient
 */
+ (instancetype)client;

/**
 * @brief Synchronously performs the specified HTTP request.
 *
 * @note You must not change the delegate while a synchronous request is
 *	 running! If you want to change the delegate during the request,
 *	 perform an asynchronous request instead!
 *
 * @param request The request to perform
 * @return The OFHTTPResponse for the request
 * @throw OFHTTPRequestFailedException The HTTP request failed
 * @throw OFInvalidServerResponseException The server sent an invalid response
 * @throw OFUnsupportedVersionException The server responded in an unsupported
 *					version
 * @throw OFAlreadyOpenException The client is already performing a request
 */
- (OFHTTPResponse *)performRequest: (OFHTTPRequest *)request;

/**
 * @brief Synchronously performs the specified HTTP request.
 *
 * @note You must not change the delegate while a synchronous request is
 *	 running! If you want to change the delegate during the request,
 *	 perform an asynchronous request instead!
 *
 * @param request The request to perform
 * @param redirects The maximum number of redirects after which no further
 *		    attempt is done to follow the redirect, but instead the
 *		    redirect is treated as an OFHTTPResponse
 * @return The OFHTTPResponse for the request
 * @throw OFHTTPRequestFailedException The HTTP request failed
 * @throw OFInvalidServerResponseException The server sent an invalid response
 * @throw OFUnsupportedVersionException The server responded in an unsupported
 *					version
 * @throw OFAlreadyOpenException The client is already performing a request
 */
- (OFHTTPResponse *)performRequest: (OFHTTPRequest *)request
			 redirects: (unsigned int)redirects;

/**
 * @brief Asynchronously performs the specified HTTP request.
 *
 * @param request The request to perform
 * @throw OFAlreadyOpenException The client is already performing a request
 */
- (void)asyncPerformRequest: (OFHTTPRequest *)request;

/**
 * @brief Asynchronously performs the specified HTTP request.
 *
 * @param request The request to perform
 * @param redirects The maximum number of redirects after which no further
 *		    attempt is done to follow the redirect, but instead the
 *		    redirect is treated as an OFHTTPResponse
 * @throw OFAlreadyOpenException The client is already performing a request
 */
- (void)asyncPerformRequest: (OFHTTPRequest *)request
		  redirects: (unsigned int)redirects;

/**
 * @brief Closes connections that are still open due to keep-alive.
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
