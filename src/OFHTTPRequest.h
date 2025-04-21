/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"
#import "OFSocket.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFData;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFIRI;
@class OFString;

/** @file */

/**
 * @brief The type of an HTTP request.
 */
typedef enum {
	/** OPTIONS */
	OFHTTPRequestMethodOptions,
	/** GET */
	OFHTTPRequestMethodGet,
	/** HEAD */
	OFHTTPRequestMethodHead,
	/** POST */
	OFHTTPRequestMethodPost,
	/** PUT */
	OFHTTPRequestMethodPut,
	/** DELETE */
	OFHTTPRequestMethodDelete,
	/** TRACE */
	OFHTTPRequestMethodTrace,
	/** CONNECT */
	OFHTTPRequestMethodConnect
} OFHTTPRequestMethod;

/**
 * @struct OFHTTPRequestProtocolVersion OFHTTPRequest.h ObjFW/ObjFW.h
 *
 * @brief The HTTP version of the HTTP request.
 */
typedef struct OF_BOXABLE OFHTTPRequestProtocolVersion {
	/** The major of the HTTP version */
	unsigned char major;
	/** The minor of the HTTP version */
	unsigned char minor;
} OFHTTPRequestProtocolVersion;

/**
 * @class OFHTTPRequest OFHTTPRequest.h ObjFW/ObjFW.h
 *
 * @brief A class for storing HTTP requests.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFHTTPRequest: OFObject <OFCopying>
{
	OFIRI *_IRI;
	OFHTTPRequestMethod _method;
	OFHTTPRequestProtocolVersion _protocolVersion;
	OFDictionary OF_GENERIC(OFString *, OFString *) *_Nullable _headers;
	OFSocketAddress _remoteAddress;
	bool _hasRemoteAddress;
}

/**
 * @brief The IRI of the HTTP request.
 */
@property (copy, nonatomic) OFIRI *IRI;

/**
 * @brief The protocol version of the HTTP request.
 *
 * @throw OFUnsupportedVersionException The specified version cannot be set
 *					because it is not supported
 */
@property (nonatomic) OFHTTPRequestProtocolVersion protocolVersion;

/**
 * @brief The protocol version of the HTTP request as a string.
 *
 * @throw OFUnsupportedVersionException The specified version cannot be set
 *					because it is not supported
 * @throw OFInvalidFormatException The specified version cannot be set because
 *				   it is not in a valid format
 */
@property (copy, nonatomic) OFString *protocolVersionString;

/**
 * @brief The request method of the HTTP request.
 */
@property (nonatomic) OFHTTPRequestMethod method;

/**
 * @brief The headers for the HTTP request.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic)
    OFDictionary OF_GENERIC(OFString *, OFString *) *headers;

/**
 * @brief The remote address from which the request originates.
 *
 * @note The setter creates a copy of the remote address.
 */
@property OF_NULLABLE_PROPERTY (nonatomic) const OFSocketAddress *remoteAddress;

/**
 * @brief Creates a new OFHTTPRequest with the specified IRI.
 *
 * @param IRI The IRI for the request
 * @return A new, autoreleased OFHTTPRequest
 */
+ (instancetype)requestWithIRI: (OFIRI *)IRI;

/**
 * @brief Initializes an already allocated OFHTTPRequest with the specified IRI.
 *
 * @param IRI The IRI for the request
 * @return An initialized OFHTTPRequest
 */
- (instancetype)initWithIRI: (OFIRI *)IRI;

- (instancetype)init OF_UNAVAILABLE;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Returns a string describing the specified request method.
 *
 * @param method The request method which should be described as a string
 * @return A string describing the specified request method
 */
extern OFString *_Nullable OFHTTPRequestMethodString(
    OFHTTPRequestMethod method);

/**
 * @brief Returns the request method for the specified string.
 *
 * @param string The string for which the request method should be returned
 * @return The request method for the specified string
 * @throw OFInvalidFormatException The specified string is not a valid HTTP
 *				   request method
 */
extern OFHTTPRequestMethod OFHTTPRequestMethodParseString(OFString *string);

/**
 * @brief Returns a C string describing the specified request method.
 *
 * @deprecated Use @ref OFHTTPRequestMethodString instead.
 *
 * @param method The request method which should be described as a C string
 * @return A C string describing the specified request method
 */
extern const char *_Nullable OFHTTPRequestMethodName(OFHTTPRequestMethod method)
    OF_DEPRECATED(ObjFW, 1, 1, "Use OFHTTPRequestMethodString instead");

/**
 * @brief Returns the request method for the specified string.
 *
 * @deprecated Use @ref OFHTTPRequestMethodParseString instead.
 *
 * @param string The string for which the request method should be returned
 * @return The request method for the specified string
 * @throw OFInvalidFormatException The specified string is not a valid HTTP
 *				   request method
 */
extern OFHTTPRequestMethod OFHTTPRequestMethodParseName(OFString *string)
    OF_DEPRECATED(ObjFW, 1, 1, "Use OFHTTPRequestMethodParseString instead");
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
