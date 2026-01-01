/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFStream.h"
#import "OFHTTPRequest.h"

OF_ASSUME_NONNULL_BEGIN

@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFArray OF_GENERIC(ObjectType);

/**
 * @class OFHTTPResponse OFHTTPResponse.h ObjFW/ObjFW.h
 *
 * @brief A class for representing an HTTP request response as a stream.
 */
#if !defined(OF_HTTP_CLIENT_M) && !defined(OF_HTTP_SERVER_M)
OF_SUBCLASSING_RESTRICTED
#endif
@interface OFHTTPResponse: OFStream
{
	OFHTTPRequestProtocolVersion _protocolVersion;
	short _statusCode;
	OFDictionary OF_GENERIC(OFString *, OFString *) *_headers;
}

/**
 * @brief The protocol version of the HTTP request response.
 *
 * @throw OFUnsupportedVersionException The specified version cannot be set
 *					because it is not supported
 */
@property (nonatomic) OFHTTPRequestProtocolVersion protocolVersion;

/**
 * @brief The protocol version of the HTTP request response as a string.
 *
 * @throw OFUnsupportedVersionException The specified version cannot be set
 *					because it is not supported
 * @throw OFInvalidFormatException The specified version cannot be set because
 *				   it is not in a valid format
 */
@property (copy, nonatomic) OFString *protocolVersionString;

/**
 * @brief The status code of the response to the HTTP request.
 */
@property (nonatomic) short statusCode;

/**
 * @brief The headers of the response to the HTTP request.
 */
@property (copy, nonatomic) OFDictionary OF_GENERIC(OFString *, OFString *)
    *headers;

/**
 * @brief Read the response as a string, trying to detect the encoding and
 *	  falling back to the specified encoding if not detectable.
 *
 * @return The response as a string
 */
- (OFString *)readString;

/**
 * @brief Read the response as a string, trying to detect the encoding and
 *	  falling back to the specified encoding if not detectable.
 *
 * @return The response as a string
 */
- (OFString *)readStringWithEncoding: (OFStringEncoding)encoding;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Returns a description string for the specified HTTP status code.
 *
 * @param code The HTTP status code to return a description string for
 * @return A description string for the specified HTTP status code
 */
extern OFString *_Nonnull OFHTTPStatusCodeString(short code);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
