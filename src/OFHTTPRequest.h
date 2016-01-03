/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFURL;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFDataArray;
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
typedef struct {
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
	OFDictionary OF_GENERIC(OFString*, OFString*) *_headers;
	OFDataArray *_body;
	OFString *_remoteAddress;
}

#ifdef OF_HAVE_PROPERTIES
@property (copy) OFURL *URL;
@property of_http_request_method_t method;
@property of_http_request_protocol_version_t protocolVersion;
@property OF_NULLABLE_PROPERTY (copy)
    OFDictionary OF_GENERIC(OFString*, OFString*) *headers;
@property OF_NULLABLE_PROPERTY (retain) OFDataArray *body;
@property OF_NULLABLE_PROPERTY (copy) OFString *remoteAddress;
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
 * @brief Sets the request method of the HTTP request.
 *
 * @param method The request method of the HTTP request
 */
- (void)setMethod: (of_http_request_method_t)method;

/*!
 * @brief Returns the request method of the HTTP request.
 *
 * @return The request method of the HTTP request
 */
- (of_http_request_method_t)method;

/*!
 * @brief Sets the protocol version of the HTTP request.
 *
 * @param protocolVersion The protocol version of the HTTP request
 */
- (void)setProtocolVersion: (of_http_request_protocol_version_t)protocolVersion;

/*!
 * @brief Returns the protocol version of the HTTP request.
 *
 * @return The protocol version of the HTTP request
 */
- (of_http_request_protocol_version_t)protocolVersion;

/*!
 * @brief Sets the protocol version of the HTTP request to the version
 *	  described by the specified string.
 *
 * @param string A string describing an HTTP version
 */
- (void)setProtocolVersionFromString: (OFString*)string;

/*!
 * @brief Returns the protocol version of the HTTP request as a string.
 *
 * @return The protocol version of the HTTP request as a string
 */
- (OFString*)protocolVersionString;

/*!
 * @brief Sets a dictionary with headers for the HTTP request.
 *
 * @param headers A dictionary with headers for the HTTP request
 */
- (void)setHeaders:
    (nullable OFDictionary OF_GENERIC(OFString*, OFString*)*)headers;

/*!
 * @brief Returns a dictionary with headers for the HTTP request.
 *
 * @return A dictionary with headers for the HTTP request.
 */
- (nullable OFDictionary OF_GENERIC(OFString*, OFString*)*)headers;

/*!
 * @brief Sets the entity body of the HTTP request.
 *
 * @param body The entity body of the HTTP request
 */
- (void)setBody: (nullable OFDataArray*)body;

/*!
 * @brief Sets the entity body of the HTTP request to the specified string
 *	  encoded in UTF-8.
 *
 * @param string The string to use for the entity body
 */
- (void)setBodyFromString: (nullable OFString*)string;

/*!
 * @brief Sets the entity body of the HTTP request to the specified string
 *	  encoded in the specified encoding.
 *
 * @param string The string to use for the entity body
 * @param encoding The encoding to encode the string with
 */
- (void)setBodyFromString: (nullable OFString*)string
		 encoding: (of_string_encoding_t)encoding;

/*!
 * @brief Returns the entity body of the HTTP request.
 *
 * @return The entity body of the HTTP request
 */
- (nullable OFDataArray*)body;

/*!
 * @brief Sets the remote address from which the request originates.
 *
 * @param remoteAddress The remote address from which the request originates
 */
- (void)setRemoteAddress: (nullable OFString*)remoteAddress;

/*!
 * @brief Returns the remote address from which the request originates.
 *
 * @return The remote address from which the request originates
 */
- (nullable OFString*)remoteAddress;
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
extern const char *OF_NULLABLE of_http_request_method_to_string(
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
