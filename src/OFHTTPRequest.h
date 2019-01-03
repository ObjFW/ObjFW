/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
#import "OFString.h"

#import "socket.h"

OF_ASSUME_NONNULL_BEGIN

@class OFURL;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFData;
@class OFString;

/*! @file */

/*!
 * @brief The type of an HTTP request.
 */
typedef enum {
	/*! OPTIONS */
	OF_HTTP_REQUEST_METHOD_OPTIONS,
	/*! GET */
	OF_HTTP_REQUEST_METHOD_GET,
	/*! HEAD */
	OF_HTTP_REQUEST_METHOD_HEAD,
	/*! POST */
	OF_HTTP_REQUEST_METHOD_POST,
	/*! PUT */
	OF_HTTP_REQUEST_METHOD_PUT,
	/*! DELETE */
	OF_HTTP_REQUEST_METHOD_DELETE,
	/*! TRACE */
	OF_HTTP_REQUEST_METHOD_TRACE,
	/*! CONNECT */
	OF_HTTP_REQUEST_METHOD_CONNECT
} of_http_request_method_t;

/*!
 * @struct of_http_request_protocol_version_t \
 *	   OFHTTPRequest.h ObjFW/OFHTTPRequest.h
 *
 * @brief The HTTP version of the HTTP request.
 */
typedef struct OF_BOXABLE {
	/*! The major of the HTTP version */
	uint8_t major;
	/*! The minor of the HTTP version */
	uint8_t minor;
} of_http_request_protocol_version_t;

/*!
 * @class OFHTTPRequest OFHTTPRequest.h ObjFW/OFHTTPRequest.h
 *
 * @brief A class for storing HTTP requests.
 */
@interface OFHTTPRequest: OFObject <OFCopying>
{
	OFURL *_URL;
	of_http_request_method_t _method;
	of_http_request_protocol_version_t _protocolVersion;
	OFDictionary OF_GENERIC(OFString *, OFString *) *_Nullable _headers;
	of_socket_address_t _remoteAddress;
}

/*!
 * @brief The URL of the HTTP request.
 */
@property (copy, nonatomic) OFURL *URL;

/*!
 * @brief The protocol version of the HTTP request.
 */
@property (nonatomic) of_http_request_protocol_version_t protocolVersion;

/*!
 * @brief The protocol version of the HTTP request as a string.
 */
@property (copy, nonatomic) OFString *protocolVersionString;

/*!
 * @brief The request method of the HTTP request.
 */
@property (nonatomic) of_http_request_method_t method;

/*!
 * @brief The headers for the HTTP request.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic)
    OFDictionary OF_GENERIC(OFString *, OFString *) *headers;

/*!
 * @brief The remote address from which the request originates.
 */
@property OF_NULLABLE_PROPERTY (nonatomic)
    const of_socket_address_t *remoteAddress;

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
+ (instancetype)requestWithURL: (OFURL *)URL;

/*!
 * @brief Initializes an already allocated OFHTTPRequest with the specified URL.
 *
 * @param URL The URL for the request
 * @return An initialized OFHTTPRequest
 */
- (instancetype)initWithURL: (OFURL *)URL;
@end

#ifdef __cplusplus
extern "C" {
#endif
/*!
 * @brief Returns a C string describing the specified request method.
 *
 * @param method The request method which should be described as a C string
 * @return A C string describing the specified request method
 */
extern const char *_Nullable of_http_request_method_to_string(
    of_http_request_method_t method);

/*!
 * @brief Returns the request method for the specified string.
 *
 * @param string The string for which the request method should be returned
 * @return The request method for the specified string
 */
extern of_http_request_method_t of_http_request_method_from_string(
    const char *string);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
