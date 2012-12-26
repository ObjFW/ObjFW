/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

@class OFHTTPClient;
@class OFHTTPRequest;
@class OFHTTPRequestReply;
@class OFURL;
@class OFTCPSocket;
@class OFDictionary;
@class OFDataArray;

/*!
 * @brief A delegate for OFHTTPClient.
 */
@protocol OFHTTPClientDelegate <OFObject>
#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif
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
-    (void)client: (OFHTTPClient*)client
  didCreateSocket: (OFTCPSocket*)socket
	  request: (OFHTTPRequest*)request;

/*!
 * @brief A callback which is called when an OFHTTPClient received headers.
 *
 * @param client The OFHTTPClient which received the headers
 * @param headers The headers received
 * @param statusCode The status code received
 * @param request The request for which the headers and status code have been
 *		  received
 */
-      (void)client: (OFHTTPClient*)client
  didReceiveHeaders: (OFDictionary*)headers
	 statusCode: (int)statusCode
	    request: (OFHTTPRequest*)request;

/*!
 * @brief A callback which is called when an OFHTTPClient received data.
 *
 * This is useful for example if you want to update a status display.
 *
 * @param client The OFHTTPClient which received data
 * @param data The data the OFHTTPClient received
 * @param length The length of the data received, in bytes
 * @param request The request for which data has been received
 */
-   (void)client: (OFHTTPClient*)client
  didReceiveData: (const char*)data
	  length: (size_t)length
	 request: (OFHTTPRequest*)request;

/*!
 * @brief A callback which is called when an OFHTTPClient will follow a
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
 * @param request The request for which the OFHTTPClient wants to redirect
 * @return A boolean whether the OFHTTPClient should follow the redirect
 */
-	  (BOOL)client: (OFHTTPClient*)client
  shouldFollowRedirect: (OFURL*)URL
	       request: (OFHTTPRequest*)request;
@end

/*!
 * @brief A class for performing HTTP requests.
 */
@interface OFHTTPClient: OFObject
{
	id <OFHTTPClientDelegate> delegate;
	BOOL storesData;
	BOOL insecureRedirectsAllowed;
}

#ifdef OF_HAVE_PROPERTIES
@property (assign) id <OFHTTPClientDelegate> delegate;
@property BOOL storesData;
@property BOOL insecureRedirectsAllowed;
#endif

/*!
 * @brief Creates a new OFHTTPClient.
 *
 * @return A new, autoreleased OFHTTPClient
 */
+ (instancetype)client;

/*!
 * @brief Sets the delegate of the HTTP request.
 *
 * @param delegate The delegate of the HTTP request
 */
- (void)setDelegate: (id <OFHTTPClientDelegate>)delegate;

/*!
 * @brief Returns the delegate of the HTTP reqeust.
 *
 * @return The delegate of the HTTP request
 */
- (id <OFHTTPClientDelegate>)delegate;

/*!
 * @brief Sets whether redirects from HTTPS to HTTP are allowed.
 *
 * @param allowed Whether redirects from HTTPS to HTTP are allowed
 */
- (void)setInsecureRedirectsAllowed: (BOOL)allowed;

/*!
 * @brief Returns whether redirects from HTTPS to HTTP will be allowed
 *
 * @return Whether redirects from HTTPS to HTTP will be allowed
 */
- (BOOL)insecureRedirectsAllowed;

/*!
 * @brief Sets whether an OFDataArray with the data should be created.
 *
 * Setting this to NO is only useful if you are using the delegate to handle the
 * data.
 *
 * @param enabled Whether to store the data in an OFDataArray
 */
- (void)setStoresData: (BOOL)enabled;

/*!
 * @brief Returns whether an OFDataArray with the date should be created.
 *
 * @return Whether an OFDataArray with the data should be created
 */
- (BOOL)storesData;

/*!
 * @brief Performs the specified HTTP request
 */
- (OFHTTPRequestReply*)performRequest: (OFHTTPRequest*)request;

/*!
 * @brief Performs the HTTP request and returns an OFHTTPRequestReply.
 *
 * @param redirects The maximum number of redirects after which no further
 *		    attempt is done to follow the redirect, but instead the
 *		    redirect is returned as an OFHTTPRequestReply
 * @return An OFHTTPRequestReply with the reply of the HTTP request
 */
- (OFHTTPRequestReply*)performRequest: (OFHTTPRequest*)request
			    redirects: (size_t)redirects;
@end

@interface OFObject (OFHTTPClientDelegate) <OFHTTPClientDelegate>
@end
