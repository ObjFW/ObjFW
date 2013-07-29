/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "OFStream.h"
#import "OFHTTPRequest.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

@class OFDictionary;

/*!
 * @brief A class for representing an HTTP request reply as a stream.
 */
@interface OFHTTPResponse: OFStream
{
	of_http_request_protocol_version_t _protocolVersion;
	short _statusCode;
	OFDictionary *_headers;
}

#ifdef OF_HAVE_PROPERTIES
@property of_http_request_protocol_version_t protocolVersion;
@property short statusCode;
@property (copy) OFDictionary *headers;
#endif

/*!
 * @brief Sets the protocol version of the HTTP request reply.
 *
 * @param protocolVersion The protocol version of the HTTP request reply
 */
- (void)setProtocolVersion: (of_http_request_protocol_version_t)protocolVersion;

/*!
 * @brief Returns the protocol version of the HTTP request reply.
 *
 * @return The protocol version of the HTTP request reply
 */
- (of_http_request_protocol_version_t)protocolVersion;

/*!
 * @brief Sets the protocol version of the HTTP request reply to the version
 *	  described by the specified string.
 *
 * @param string A string describing an HTTP version
 */
- (void)setProtocolVersionFromString: (OFString*)string;

/*!
 * @brief Returns the protocol version of the HTTP request reply as a string.
 *
 * @return The protocol version of the HTTP request reply as a string
 */
- (OFString*)protocolVersionString;

/*!
 * @brief Returns the status code of the reply to the HTTP request.
 *
 * @return The status code of the reply to the HTTP request
 */
- (short)statusCode;

/*!
 * @brief Sets the status code of the reply to the HTTP request.
 *
 * @param statusCode The status code of the reply to the HTTP request
 */
- (void)setStatusCode: (short)statusCode;

/*!
 * @brief Returns the headers of the reply to the HTTP request.
 *
 * @return The headers of the reply to the HTTP request
 */
- (OFDictionary*)headers;

/*!
 * @brief Returns the headers of the reply to the HTTP request.
 *
 * @param headers The headers of the reply to the HTTP request
 */
- (void)setHeaders: (OFDictionary*)headers;

/*!
 * @brief Returns the reply as a string, trying to detect the encoding.
 *
 * @return The reply as a string
 */
- (OFString*)string;

/*!
 * @brief Returns the reply as a string, trying to detect the encoding and
 *	  falling back to the specified encoding if not detectable.
 *
 * @return The reply as a string
 */
- (OFString*)stringWithEncoding: (of_string_encoding_t)encoding;
@end
