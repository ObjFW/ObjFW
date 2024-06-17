/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDate;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFIRI;
@class OFMutableArray OF_GENERIC(ObjectType);

/**
 * @class OFHTTPCookie OFHTTPCookie.h ObjFW/ObjFW.h
 *
 * @brief A class for storing and manipulating HTTP cookies.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFHTTPCookie: OFObject <OFCopying>
{
	OFString *_name, *_value, *_domain, *_path;
	OFDate *_Nullable _expires;
	bool _secure, _HTTPOnly;
	OFMutableArray OF_GENERIC(OFString *) *_extensions;
}

/**
 * @brief The name of the cookie.
 */
@property (copy, nonatomic) OFString *name;

/**
 * @brief The value of the cookie.
 */
@property (copy, nonatomic) OFString *value;

/**
 * @brief The domain for the cookie.
 */
@property (copy, nonatomic) OFString *domain;

/**
 * @brief The path for the cookie.
 */
@property (copy, nonatomic) OFString *path;

/**
 * @brief The date when the cookie expires.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFDate *expires;

/**
 * @brief Whether the cookie is only to be used with HTTPS.
 */
@property (nonatomic, getter=isSecure) bool secure;

/**
 * @brief Whether the cookie is only to be accessed through HTTP.
 */
@property (nonatomic, getter=isHTTPOnly) bool HTTPOnly;

/**
 * @brief An array of other attributes.
 */
@property (readonly, nonatomic)
    OFMutableArray OF_GENERIC(OFString *) *extensions;

/**
 * @brief Parses the specified response header fields for the specified IRI and
 *	  returns an array of cookies.
 *
 * @param headerFields The response header fields to parse
 * @param IRI The IRI for the response header fields to parse
 * @return An array of cookies
 * @throw OFInvalidFormatException The specified response header has an invalid
 *				   format
 */
+ (OFArray OF_GENERIC(OFHTTPCookie *) *)cookiesWithResponseHeaderFields:
    (OFDictionary OF_GENERIC(OFString *, OFString *) *)headerFields
    forIRI: (OFIRI *)IRI;

/**
 * @brief Returns the request header fields for the specified cookies.
 *
 * @param cookies The cookies to return the request header fields for
 * @return The request header fields for the specified cookies
 */
+ (OFDictionary *)requestHeaderFieldsWithCookies:
    (OFArray OF_GENERIC(OFHTTPCookie *) *)cookies;

/**
 * @brief Create a new cookie with the specified name and value.
 *
 * @param name The name of the cookie
 * @param value The value of the cookie
 * @param domain The domain for the cookie
 * @return A new, autoreleased OFHTTPCookie
 */
+ (instancetype)cookieWithName: (OFString *)name
			 value: (OFString *)value
			domain: (OFString *)domain;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated new cookie with the specified name
 *	  and value.
 *
 * @param name The name of the cookie
 * @param value The value of the cookie
 * @param domain The domain for the cookie
 * @return An initialized OFHTTPCookie
 */
- (instancetype)initWithName: (OFString *)name
		       value: (OFString *)value
		      domain: (OFString *)domain OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
