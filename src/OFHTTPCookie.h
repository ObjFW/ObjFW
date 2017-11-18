/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDate;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFURL;

/*!
 * @class OFHTTPCookie OFHTTPCookie.h ObjFW/OFHTTPCookie.h
 *
 * @brief A class for storing and manipulating HTTP cookies.
 */
@interface OFHTTPCookie: OFObject <OFCopying>
{
	OFString *_name, *_value, *_domain, *_path;
	OFDate *_Nullable _expires;
	bool _secure, _HTTPOnly;
	OFMutableArray OF_GENERIC(OFString *) *_extensions;
}

/*!
 * @brief The name of the cookie.
 */
@property (copy, nonatomic) OFString *name;

/*!
 * @brief The value of the cookie.
 */
@property (copy, nonatomic) OFString *value;

/*!
 * @brief The domain for the cookie.
 */
@property (copy, nonatomic) OFString *domain;

/*!
 * @brief The path for the cookie.
 */
@property (copy, nonatomic) OFString *path;

/*!
 * @brief The date when the cookie expires.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFDate *expires;

/*!
 * @brief Whether the cookie is only to be used with HTTPS.
 */
@property (nonatomic, getter=isSecure) bool secure;

/*!
 * @brief Whether the cookie is only to be accessed through HTTP.
 */
@property (nonatomic, getter=isHTTPOnly) bool HTTPOnly;

/*!
 * @brief An array of other attributes.
 */
@property (readonly, nonatomic)
    OFMutableArray OF_GENERIC(OFString *) *extensions;

/*!
 * @brief Parses the specified response header fields for the specified URL and
 *	  returns an array of cookies.
 *
 * @param headerFields The response header fields to parse
 * @param URL The URL for the response header fields to parse
 * @return An array of cookies
 */
+ (OFArray OF_GENERIC(OFHTTPCookie *) *)cookiesWithResponseHeaderFields:
    (OFDictionary OF_GENERIC(OFString *, OFString *) *)headerFields
    forURL: (OFURL *)URL;

/*!
 * @brief Returns the request header fields for the specified cookies.
 *
 * @param cookies The cookies to return the request header fields for
 * @return The request header fields for the specified cookies
 */
+ (OFDictionary *)requestHeaderFieldsWithCookies:
    (OFArray OF_GENERIC(OFHTTPCookie *) *)cookies;

/*!
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

/*!
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
