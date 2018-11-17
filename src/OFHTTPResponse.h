/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFStream.h"
#import "OFHTTPRequest.h"

OF_ASSUME_NONNULL_BEGIN

@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFArray OF_GENERIC(ObjectType);

/*!
 * @class OFHTTPResponse OFHTTPResponse.h ObjFW/OFHTTPResponse.h
 *
 * @brief A class for representing an HTTP request reply as a stream.
 */
@interface OFHTTPResponse: OFStream
{
	of_http_request_protocol_version_t _protocolVersion;
	short _statusCode;
	OFDictionary OF_GENERIC(OFString *, OFString *) *_headers;
}

/*!
 * @brief The protocol version of the HTTP request reply.
 */
@property (nonatomic) of_http_request_protocol_version_t protocolVersion;

/*!
 * @brief The protocol version of the HTTP request reply as a string.
 */
@property (copy, nonatomic) OFString *protocolVersionString;

/*!
 * @brief The status code of the reply to the HTTP request.
 */
@property (nonatomic) short statusCode;

/*!
 * @brief The headers of the reply to the HTTP request.
 */
@property (copy, nonatomic) OFDictionary OF_GENERIC(OFString *, OFString *)
    *headers;

/*!
 * @brief The reply as a string, trying to detect the encoding.
 */
@property (readonly, nonatomic) OFString *string;

/*!
 * @brief Returns the reply as a string, trying to detect the encoding and
 *	  falling back to the specified encoding if not detectable.
 *
 * @return The reply as a string
 */
- (OFString *)stringWithEncoding: (of_string_encoding_t)encoding;
@end

OF_ASSUME_NONNULL_END
