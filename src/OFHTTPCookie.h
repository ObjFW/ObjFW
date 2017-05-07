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
#import "OFDate.h"
#import "OFArray.h"

/*!
 * @class OFHTTPCookie OFHTTPCookie.h ObjFW/OFHTTPCookie.h
 *
 * @brief A class for storing and manipulating HTTP cookies.
 */
@interface OFHTTPCookie: OFObject <OFCopying>
{
	OFString *_name, *_value;
	OFDate *_expires;
	OFString *_domain, *_path;
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
 * The date when the cookie expires.
 */
@property (nonatomic, copy) OFDate *expires;

/*!
 * The domain for the cookie.
 */
@property (nonatomic, copy) OFString *domain;

/*!
 * The path for the cookie.
 */
@property (nonatomic, copy) OFString *path;

/*!
 * Whether the cookie is only to be used with HTTPS.
 */
@property (getter=isSecure) bool secure;

/*!
 * Whether the cookie is only to be accessed through HTTP.
 */
@property (getter=isHTTPOnly) bool HTTPOnly;

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
 * @return A new, autoreleased OFHTTPCookie
 */
+ (instancetype)cookieWithName: (OFString *)name
			 value: (OFString *)value;

/*!
 * @brief Parses the specified string and returns an array of cookies.
 *
 * @param string The cookie string to parse
 * @return An array of cookies
 */
+ (OFArray OF_GENERIC(OFHTTPCookie *) *)cookiesForString: (OFString *)string;

- init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated new cookie with the specified name
 *	  and value.
 *
 * @param name The name of the cookie
 * @param value The value of the cookie
 * @return An initialized OFHTTPCookie
 */
- initWithName: (OFString *)name
	 value: (OFString *)value;
@end
