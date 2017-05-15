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
	OFDate *_expires;
	bool _secure, _HTTPOnly;
	OFMutableArray OF_GENERIC(OFString *) *_extensions;
}

/*!
 * The name of the cookie.
 */
@property (nonatomic, copy) OFString *name;

/*!
 * The value of the cookie.
 */
@property (nonatomic, copy) OFString *value;

/*!
 * The domain for the cookie.
 */
@property (nonatomic, copy) OFString *domain;

/*!
 * The path for the cookie.
 */
@property (nonatomic, copy) OFString *path;

/*!
 * The date when the cookie expires.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFDate *expires;

/*!
 * Whether the cookie is only to be used with HTTPS.
 */
@property (nonatomic, getter=isSecure) bool secure;

/*!
 * Whether the cookie is only to be accessed through HTTP.
 */
@property (nonatomic, getter=isHTTPOnly) bool HTTPOnly;

/*!
 * An array of other attributes.
 */
@property (readonly, nonatomic)
    OFMutableArray OF_GENERIC(OFString *) *extensions;

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

/*!
 * @brief Parses the specified string and returns an array of cookies.
 *
 * @param headers The headers to parse
 * @param URL The URL for the cookies to parse
 * @return An array of cookies
 */
+ (OFArray OF_GENERIC(OFHTTPCookie *) *)cookiesFromHeaders:
    (OFDictionary OF_GENERIC(OFString *, OFString *) *)headers
    forURL: (OFURL *)URL;

- init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated new cookie with the specified name
 *	  and value.
 *
 * @param name The name of the cookie
 * @param value The value of the cookie
 * @param domain The domain for the cookie
 * @return An initialized OFHTTPCookie
 */
- initWithName: (OFString *)name
	 value: (OFString *)value
	domain: (OFString *)domain OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
