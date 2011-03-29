/*
 * Copyright (c) 2008, 2009, 2010, 2011
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
@class OFHTTPRequestResult;
@class OFDataArray;

typedef enum of_http_request_type_t {
	OF_HTTP_REQUEST_TYPE_GET,
	OF_HTTP_REQUEST_TYPE_POST,
	OF_HTTP_REQUEST_TYPE_HEAD
} of_http_request_type_t;

/**
 * \brief A class for storing and performing HTTP requests.
 */
@interface OFHTTPRequest: OFObject
{
	OFURL *URL;
	of_http_request_type_t requestType;
	OFString *queryString;
	OFDictionary *headers;
}

#ifdef OF_HAVE_PROPERTIES
@property (copy) OFURL *URL;
@property (assign) of_http_request_type_t requestType;
@property (copy) OFString *queryString;
@property (copy) OFDictionary *headers;
#endif

/**
 * \return A new, autoreleased OFHTTPRequest
 */
+ request;

/**
 * \param url The URL for the request
 * \return A new, autoreleased OFHTTPRequest
 */
+ requestWithURL: (OFURL*)url;

/**
 * Initializes an already allocated OFHTTPRequest with the specified URL.
 *
 * \param url The URL for the request
 * \return An initialized OFHTTPRequest
 */
- initWithURL: (OFURL*)url;

/**
 * Sets the URL for the HTTP request.
 *
 * \param URL The URL for the HTTP request
 */
- (void)setURL: (OFURL*)url;

/**
 * \return The URL for the HTTP request
 */
- (OFURL*)URL;

/**
 * Sets the request type for the HTTP request.
 *
 * \param type The request type for the HTTP request
 */
- (void)setRequestType: (of_http_request_type_t)type;

/**
 * \return The request type for the HTTP request
 */
- (of_http_request_type_t)requestType;

/**
 * Sets the query string for the HTTP request.
 *
 * \param qs The query string for the HTTP request
 */
- (void)setQueryString: (OFString*)qs;

/**
 * \return The query string for the HTTP request
 */
- (OFString*)queryString;

/**
 * Sets a dictionary with headers for the HTTP request.
 *
 * \param headers A dictionary with headers for the HTTP request
 */
- (void)setHeaders: (OFDictionary*)headers;

/**
 * \return A dictionary with headers for the HTTP request.
 */
- (OFDictionary*)headers;

/**
 * Performs the HTTP request and returns an OFHTTPRequestResult.
 *
 * \return An OFHTTPRequestResult with the result of the HTTP request
 */
- (OFHTTPRequestResult*)perform;

/**
 * Performs the HTTP request and returns an OFHTTPRequestResult.
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

/// \cond internal
- initWithStatusCode: (short)status
	     headers: (OFDictionary*)headers
		data: (OFDataArray*)data;
/// \endcond

/**
 * \return The status code of the result of the HTTP request
 */
- (short)statusCode;

/**
 * \return The HTTP headers of the result of the HTTP request
 */
- (OFDictionary*)headers;

/**
 * \return The data returned for the HTTP request
 */
- (OFDataArray*)data;
@end

extern Class of_http_request_tls_socket_class;
