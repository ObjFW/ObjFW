/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
#import "OFSocket.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFURI;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFData;
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
 * @struct OFHTTPRequestProtocolVersion OFHTTPRequest.h ObjFW/OFHTTPRequest.h
 *
 * @brief The HTTP version of the HTTP request.
 */
typedef struct OF_BOXABLE {
	/** The major of the HTTP version */
	unsigned char major;
	/** The minor of the HTTP version */
	unsigned char minor;
} OFHTTPRequestProtocolVersion;

/**
 * @class OFHTTPRequest OFHTTPRequest.h ObjFW/OFHTTPRequest.h
 *
 * @brief A class for storing HTTP requests.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFHTTPRequest: OFObject <OFCopying>
{
	OFURI *_URI;
	OFHTTPRequestMethod _method;
	OFHTTPRequestProtocolVersion _protocolVersion;
	OFDictionary OF_GENERIC(OFString *, OFString *) *_Nullable _headers;
	OFSocketAddress _remoteAddress;
	bool _hasRemoteAddress;
}

/**
 * @brief The URI of the HTTP request.
 */
@property (copy, nonatomic) OFURI *URI;

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
 * @brief Creates a new OFHTTPRequest with the specified URI.
 *
 * @param URI The URI for the request
 * @return A new, autoreleased OFHTTPRequest
 */
+ (instancetype)requestWithURI: (OFURI *)URI;

/**
 * @brief Initializes an already allocated OFHTTPRequest with the specified URI.
 *
 * @param URI The URI for the request
 * @return An initialized OFHTTPRequest
 */
- (instancetype)initWithURI: (OFURI *)URI;

- (instancetype)init OF_UNAVAILABLE;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Returns a C string describing the specified request method.
 *
 * @param method The request method which should be described as a C string
 * @return A C string describing the specified request method
 */
extern const char *_Nullable OFHTTPRequestMethodName(
    OFHTTPRequestMethod method);

/**
 * @brief Returns the request method for the specified string.
 *
 * @param string The string for which the request method should be returned
 * @return The request method for the specified string
 * @throw OFInvalidFormatException The specified string is not a valid HTTP
 *				   request method
 */
extern OFHTTPRequestMethod OFHTTPRequestMethodParseName(OFString *string);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
