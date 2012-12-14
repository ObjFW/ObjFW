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

@class OFURL;
@class OFDictionary;
@class OFDataArray;
@class OFString;

typedef enum of_http_request_type_t {
	OF_HTTP_REQUEST_TYPE_GET,
	OF_HTTP_REQUEST_TYPE_POST,
	OF_HTTP_REQUEST_TYPE_HEAD
} of_http_request_type_t;

/*!
 * @brief A class for storing HTTP requests.
 */
@interface OFHTTPRequest: OFObject
{
	OFURL *URL;
	of_http_request_type_t requestType;
	OFDictionary *headers;
	OFDataArray *POSTData;
	OFString *MIMEType;
}

#ifdef OF_HAVE_PROPERTIES
@property (copy) OFURL *URL;
@property of_http_request_type_t requestType;
@property (copy) OFDictionary *headers;
@property (retain) OFDataArray *POSTData;
@property (copy) OFString *MIMEType;
#endif

/*!
 * @brief Creates a new OFHTTPRequest.
 *
 * @return A new, autoreleased OFHTTPRequest
 */
+ (instancetype)request;

/*!
 * @brief Creates a new OFHTTPRequest with the specified URL.
 *
 * @param URL The URL for the request
 * @return A new, autoreleased OFHTTPRequest
 */
+ (instancetype)requestWithURL: (OFURL*)URL;

/*!
 * @brief Initializes an already allocated OFHTTPRequest with the specified URL.
 *
 * @param URL The URL for the request
 * @return An initialized OFHTTPRequest
 */
- initWithURL: (OFURL*)URL;

/*!
 * @brief Sets the URL of the HTTP request.
 *
 * @param URL The URL of the HTTP request
 */
- (void)setURL: (OFURL*)URL;

/*!
 * @brief Returns the URL of the HTTP request.
 *
 * @return The URL of the HTTP request
 */
- (OFURL*)URL;

/*!
 * @brief Sets the request type of the HTTP request.
 *
 * @param requestType The request type of the HTTP request
 */
- (void)setRequestType: (of_http_request_type_t)requestType;

/*!
 * @brief Returns the request type of the HTTP request.
 *
 * @return The request type of the HTTP request
 */
- (of_http_request_type_t)requestType;

/*!
 * @brief Sets a dictionary with headers for the HTTP request.
 *
 * @param headers A dictionary with headers for the HTTP request
 */
- (void)setHeaders: (OFDictionary*)headers;

/*!
 * @brief Retrusn a dictionary with headers for the HTTP request.
 *
 * @return A dictionary with headers for the HTTP request.
 */
- (OFDictionary*)headers;

/*!
 * @brief Sets the POST data of the HTTP request.
 *
 * @param POSTData The POST data of the HTTP request
 */
- (void)setPOSTData: (OFDataArray*)postData;

/*!
 * @brief Returns the POST data of the HTTP request.
 *
 * @return The POST data of the HTTP request
 */
- (OFDataArray*)POSTData;

/*!
 * @brief Sets the MIME type for the POST data.
 *
 * @param MIMEType The MIME type for the POST data
 */
- (void)setMIMEType: (OFString*)MIMEType;

/*!
 * @brief Returns the MIME type for the POST data.
 *
 * @return The MIME type for the POST data
 */
- (OFString*)MIMEType;
@end

/*!
 * @brief A class for storing the result of an HTTP request.
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

/*!
 * @brief Creates a new OFHTTPRequestResult.
 *
 * @param status The HTTP status code replied to the request
 * @param headers The headers replied to the request
 * @param data The data replied to the request
 * @return A new OFHTTPRequestResult
 */
+ resultWithStatusCode: (short)status
	       headers: (OFDictionary*)headers
		  data: (OFDataArray*)data;

/*!
 * @brief Initializes an already allocated OFHTTPRequestResult.
 *
 * @param status The HTTP status code replied to the request
 * @param headers The headers replied to the request
 * @param data The data replied to the request
 * @return An initialized OFHTTPRequestResult
 */
- initWithStatusCode: (short)status
	     headers: (OFDictionary*)headers
		data: (OFDataArray*)data;

/*!
 * @brief Returns the state code of the result of the HTTP request.
 *
 * @return The status code of the result of the HTTP request
 */
- (short)statusCode;

/*!
 * @brief Returns the headers of the result of the HTTP request.
 *
 * @return The headers of the result of the HTTP request
 */
- (OFDictionary*)headers;

/*!
 * @brief Returns the data received for the HTTP request.
 *
 * @return The data received for the HTTP request
 */
- (OFDataArray*)data;
@end
