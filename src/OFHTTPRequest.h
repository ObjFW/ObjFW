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
	OFString *remoteAddress;
}

#ifdef OF_HAVE_PROPERTIES
@property (copy) OFURL *URL;
@property of_http_request_type_t requestType;
@property (copy) OFDictionary *headers;
@property (retain) OFDataArray *POSTData;
@property (copy) OFString *MIMEType;
@property (copy) OFString *remoteAddress;
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

/*!
 * @brief Sets the remote address from which the request originates.
 *
 * @param remoteAddress The remote address from which the request originates
 */
- (void)setRemoteAddress: (OFString*)remoteAddress;

/*!
 * @brief Returns the remote address from which the request originates.
 *
 * @return The remote address from which the request originates
 */
- (OFString*)remoteAddress;
@end
