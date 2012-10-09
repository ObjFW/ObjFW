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

@class OFString;
@class OFDictionary;
@class OFURL;
@class OFHTTPRequest;
@class OFHTTPRequestResult;
@class OFTCPSocket;
@class OFDataArray;

typedef enum of_http_request_type_t {
	OF_HTTP_REQUEST_TYPE_GET,
	OF_HTTP_REQUEST_TYPE_POST,
	OF_HTTP_REQUEST_TYPE_HEAD
} of_http_request_type_t;

/**
 * \brief A delegate for OFHTTPRequests.
 */
#ifndef OF_HTTP_REQUEST_M
@protocol OFHTTPRequestDelegate <OFObject>
#else
@protocol OFHTTPRequestDelegate
#endif
#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif
/**
 * \brief A callback which is called when an OFHTTPRequest creates a socket.
 *
 * This is useful if the connection is using HTTPS and the server requires a
 * client certificate. This callback can then be used to tell the TLS socket
 * about the certificate. Another use case is to tell the socket about a SOCKS5
 * proxy it should use for this connection.
 *
 * \param request The OFHTTPRequest that created a socket
 * \param socket The socket created by the OFHTTPRequest
 */
-   (void)request: (OFHTTPRequest*)request
  didCreateSocket: (OFTCPSocket*)socket;

/**
 * \brief A callback which is called when an OFHTTPRequest received headers.
 *
 * \param request The OFHTTPRequest which received the headers
 * \param headers The headers received
 * \param statusCode The status code received
 */
-     (void)request: (OFHTTPRequest*)request
  didReceiveHeaders: (OFDictionary*)headers
     withStatusCode: (int)statusCode;

/**
 * \brief A callback which is called when an OFHTTPRequest received data.
 *
 * This is useful for example if you want to update a status display.
 *
 * \param request The OFHTTPRequest which received data
 * \param data The data the OFHTTPRequest received
 * \param length The length of the data received, in bytes
 */
-  (void)request: (OFHTTPRequest*)request
  didReceiveData: (const char*)data
      withLength: (size_t)length;

/**
 * \brief A callback which is called when an OFHTTPRequest will follow a
 *	  redirect.
 *
 * If you want to get the headers and data for each redirect, set the number of
 * redirects to 0 and perform a new OFHTTPRequest for each redirect. However,
 * this callback will not be called then and you have to look at the status code
 * to detect a redirect.
 *
 * This callback will only be called if the OFHTTPRequest will follow a
 * redirect. If the maximum number of redirects has been reached already, this
 * callback will not be called.
 *
 * \param request The OFHTTPRequest which will follow a redirect
 * \param URL The URL to which it will follow a redirect
 * \return A boolean whether the OFHTTPRequest should follow the redirect
 */
-	 (BOOL)request: (OFHTTPRequest*)request
  willFollowRedirectTo: (OFURL*)URL;
@end

/**
 * \brief A class for storing and performing HTTP requests.
 */
@interface OFHTTPRequest: OFObject
{
	OFURL *URL;
	of_http_request_type_t requestType;
	OFString *queryString;
	OFDictionary *headers;
	BOOL redirectsFromHTTPSToHTTPAllowed;
	id <OFHTTPRequestDelegate> delegate;
	BOOL storesData;
}

#ifdef OF_HAVE_PROPERTIES
@property (copy) OFURL *URL;
@property of_http_request_type_t requestType;
@property (copy) OFString *queryString;
@property (copy) OFDictionary *headers;
@property BOOL redirectsFromHTTPSToHTTPAllowed;
@property (assign) id <OFHTTPRequestDelegate> delegate;
@property BOOL storesData;
#endif

/**
 * \brief Creates a new OFHTTPRequest.
 *
 * \return A new, autoreleased OFHTTPRequest
 */
+ (instancetype)request;

/**
 * \brief Creates a new OFHTTPRequest with the specified URL.
 *
 * \param URL The URL for the request
 * \return A new, autoreleased OFHTTPRequest
 */
+ (instancetype)requestWithURL: (OFURL*)URL;

/**
 * \brief Initializes an already allocated OFHTTPRequest with the specified URL.
 *
 * \param URL The URL for the request
 * \return An initialized OFHTTPRequest
 */
- initWithURL: (OFURL*)URL;

/**
 * \brief Sets the URL of the HTTP request.
 *
 * \param URL The URL of the HTTP request
 */
- (void)setURL: (OFURL*)URL;

/**
 * \brief Returns the URL of the HTTP request.
 *
 * \return The URL of the HTTP request
 */
- (OFURL*)URL;

/**
 * \brief Sets the request type of the HTTP request.
 *
 * \param requestType The request type of the HTTP request
 */
- (void)setRequestType: (of_http_request_type_t)requestType;

/**
 * \brief Returns the request type of the HTTP request.
 *
 * \return The request type of the HTTP request
 */
- (of_http_request_type_t)requestType;

/**
 * \brief Sets the query string of the HTTP request.
 *
 * \param queryString The query string of the HTTP request
 */
- (void)setQueryString: (OFString*)queryString;

/**
 * \brief Returns the query string of the HTTP request.
 *
 * \return The query string of the HTTP request
 */
- (OFString*)queryString;

/**
 * \brief Sets a dictionary with headers for the HTTP request.
 *
 * \param headers A dictionary with headers for the HTTP request
 */
- (void)setHeaders: (OFDictionary*)headers;

/**
 * \brief Retrusn a dictionary with headers for the HTTP request.
 *
 * \return A dictionary with headers for the HTTP request.
 */
- (OFDictionary*)headers;

/**
 * \brief Sets whether redirects from HTTPS to HTTP are allowed.
 *
 * \param allowed Whether redirects from HTTPS to HTTP are allowed
 */
- (void)setRedirectsFromHTTPSToHTTPAllowed: (BOOL)allowed;

/**
 * \brief Returns whether redirects from HTTPS to HTTP will be allowed
 *
 * \return Whether redirects from HTTPS to HTTP will be allowed
 */
- (BOOL)redirectsFromHTTPSToHTTPAllowed;

/**
 * \brief Sets the delegate of the HTTP request.
 *
 * \param delegate The delegate of the HTTP request
 */
- (void)setDelegate: (id <OFHTTPRequestDelegate>)delegate;

/**
 * \brief Returns the delegate of the HTTP reqeust.
 *
 * \return The delegate of the HTTP request
 */
- (id <OFHTTPRequestDelegate>)delegate;

/**
 * \brief Sets whether an OFDataArray with the data should be created.
 *
 * Setting this to NO is only useful if you are using the delegate to handle the
 * data.
 *
 * \param storesData Whether to store the data in an OFDataArray
 */
- (void)setStoresData: (BOOL)storesData;

/**
 * \brief Returns whether an OFDataArray with the date should be created.
 *
 * \return Whether an OFDataArray with the data should be created
 */
- (BOOL)storesData;

/**
 * \brief Performs the HTTP request and returns an OFHTTPRequestResult.
 *
 * \return An OFHTTPRequestResult with the result of the HTTP request
 */
- (OFHTTPRequestResult*)perform;

/**
 * \brief Performs the HTTP request and returns an OFHTTPRequestResult.
 *
 * \param redirects The maximum number of redirects after which no further
 *		    attempt is done to follow the redirect, but instead the
 *		    redirect is returned as an OFHTTPRequest
 * \return An OFHTTPRequestResult with the result of the HTTP request
 */
- (OFHTTPRequestResult*)performWithRedirects: (size_t)redirects;
@end

/**
 * \brief A class for storing the result of an HTTP request.
 */
@interface OFHTTPRequestResult: OFObject
{
	short statusCode;
	OFDataArray *data;
	OFDictionary *headers;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) short statusCode;
@property (readonly, copy) OFDictionary *headers;
@property (readonly, retain) OFDataArray *data;
#endif

- initWithStatusCode: (short)status
	     headers: (OFDictionary*)headers
		data: (OFDataArray*)data;

/**
 * \brief Returns the state code of the result of the HTTP request.
 *
 * \return The status code of the result of the HTTP request
 */
- (short)statusCode;

/**
 * \brief Returns the headers of the result of the HTTP request.
 *
 * \return The headers of the result of the HTTP request
 */
- (OFDictionary*)headers;

/**
 * \brief Returns the data received for the HTTP request.
 *
 * Returns nil if storesData was set to NO.
 *
 * \return The data received for the HTTP request
 */
- (OFDataArray*)data;
@end

@interface OFObject (OFHTTPRequestDelegate) <OFHTTPRequestDelegate>
@end

extern Class of_http_request_tls_socket_class;
