/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

/**
 * @class OFHTTPResponse OFHTTPResponse.h ObjFW/OFHTTPResponse.h
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
