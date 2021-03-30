/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
 * @brief A class for representing an HTTP request reply as a stream.
 */
@interface OFHTTPResponse: OFStream
{
	of_http_request_protocol_version_t _protocolVersion;
	short _statusCode;
	OFDictionary OF_GENERIC(OFString *, OFString *) *_headers;
	OF_RESERVE_IVARS(OFHTTPResponse, 4)
}

/**
 * @brief The protocol version of the HTTP request reply.
 */
@property (nonatomic) of_http_request_protocol_version_t protocolVersion;

/**
 * @brief The protocol version of the HTTP request reply as a string.
 */
@property (copy, nonatomic) OFString *protocolVersionString;

/**
 * @brief The status code of the reply to the HTTP request.
 */
@property (nonatomic) short statusCode;

/**
 * @brief The headers of the reply to the HTTP request.
 */
@property (copy, nonatomic) OFDictionary OF_GENERIC(OFString *, OFString *)
    *headers;

/**
 * @brief The reply as a string, trying to detect the encoding.
 */
@property (readonly, nonatomic) OFString *string;

/**
 * @brief Returns the reply as a string, trying to detect the encoding and
 *	  falling back to the specified encoding if not detectable.
 *
 * @return The reply as a string
 */
- (OFString *)stringWithEncoding: (of_string_encoding_t)encoding;
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
extern OFString *_Nonnull of_http_status_code_to_string(short code);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
