/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

OF_ASSUME_NONNULL_BEGIN

@class OFDictionary OF_GENERIC(KeyType, ObjectType);

/*!
 * @class OFHTTPResponse OFHTTPResponse.h ObjFW/OFHTTPResponse.h
 *
 * @brief A class for representing an HTTP request reply as a stream.
 */
@interface OFHTTPResponse: OFStream
{
	of_http_request_protocol_version_t _protocolVersion;
	short _statusCode;
	OFDictionary OF_GENERIC(OFString*, OFString*) *_headers;
}

/*!
 * The status code of the reply to the HTTP request.
 */
@property short statusCode;

/*!
 * The headers of the reply to the HTTP request.
 */
@property OF_NULLABLE_PROPERTY (copy)
    OFDictionary OF_GENERIC(OFString*, OFString*) *headers;

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

OF_ASSUME_NONNULL_END
