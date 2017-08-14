/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

@class OFHTTPClient;
@class OFHTTPRequest;
@class OFHTTPResponse;
@class OFURL;
@class OFTCPSocket;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

/*!
 * @protocol OFHTTPClientDelegate OFHTTPClient.h ObjFW/OFHTTPClient.h
 *
 * @brief A delegate for OFHTTPClient.
 */
@protocol OFHTTPClientDelegate <OFObject>
@optional
/*!
 * @brief A callback which is called when an OFHTTPClient creates a socket.
 *
 * This is useful if the connection is using HTTPS and the server requires a
 * client certificate. This callback can then be used to tell the TLS socket
 * about the certificate. Another use case is to tell the socket about a SOCKS5
 * proxy it should use for this connection.
 *
 * @param client The OFHTTPClient that created a socket
 * @param socket The socket created by the OFHTTPClient
 * @param request The request for which the socket was created
 */
-    (void)client: (OFHTTPClient *)client
  didCreateSocket: (OF_KINDOF(OFTCPSocket *))socket
	  request: (OFHTTPRequest *)request;

/*!
 * @brief A callback which is called when an OFHTTPClient received headers.
 *
 * @param client The OFHTTPClient which received the headers
 * @param headers The headers received
 * @param statusCode The status code received
 * @param request The request for which the headers and status code have been
 *		  received
 */
-      (void)client: (OFHTTPClient *)client
  didReceiveHeaders: (OFDictionary OF_GENERIC(OFString *, OFString *) *)headers
	 statusCode: (int)statusCode
	    request: (OFHTTPRequest *)request;

/*!
 * @brief A callback which is called when an OFHTTPClient wants to follow a
 *	  redirect.
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
 * @param URL The URL to which it will follow a redirect
 * @param statusCode The status code for the redirection
 * @param request The request for which the OFHTTPClient wants to redirect.
 *		  You are allowed to change the request's headers from this
 *		  callback and they will be used when following the redirect
 *		  (e.g. to set the cookies for the new URL), however, keep in
 *		  mind that this will change the request you originally passed.
 * @param response The response indicating the redirect
 * @return A boolean whether the OFHTTPClient should follow the redirect
 */
-	  (bool)client: (OFHTTPClient *)client
  shouldFollowRedirect: (OFURL *)URL
	    statusCode: (int)statusCode
	       request: (OFHTTPRequest *)request
	      response: (OFHTTPResponse *)response;
@end

/*!
 * @class OFHTTPClient OFHTTPClient.h ObjFW/OFHTTPClient.h
 *
 * @brief A class for performing HTTP requests.
 */
@interface OFHTTPClient: OFObject
{
	id <OFHTTPClientDelegate> _delegate;
	bool _insecureRedirectsAllowed;
	OFTCPSocket *_socket;
	OFURL *_lastURL;
	bool _lastWasHEAD;
	OFHTTPResponse *_lastResponse;
}

/*!
 * The delegate of the HTTP request.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFHTTPClientDelegate> delegate;

/*!
 * Whether redirects from HTTPS to HTTP will be allowed.
 */
@property (nonatomic) bool insecureRedirectsAllowed;

/*!
 * @brief Creates a new OFHTTPClient.
 *
 * @return A new, autoreleased OFHTTPClient
 */
+ (instancetype)client;

/*!
 * @brief Performs the specified HTTP request and returns an OFHTTPResponse.
 *
 * @return An OFHTTPResponse with the response for the HTTP request
 */
- (OFHTTPResponse *)performRequest: (OFHTTPRequest *)request;

/*!
 * @brief Performs the HTTP request and returns an OFHTTPResponse.
 *
 * @param request The request to perform
 * @param redirects The maximum number of redirects after which no further
 *		    attempt is done to follow the redirect, but instead the
 *		    redirect is returned as an OFHTTPResponse
 * @return An OFHTTPResponse with the response for the HTTP request
 */
- (OFHTTPResponse *)performRequest: (OFHTTPRequest *)request
			 redirects: (size_t)redirects;

/*!
 * @brief Closes connections that are still open due to keep-alive.
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
