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

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFHTTPCookie;
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFURL;

/*!
 * @class OFHTTPCookieManager OFHTTPCookieManager.h ObjFW/OFHTTPCookieManager.h
 *
 * @brief A class for managing cookies for multiple domains.
 */
@interface OFHTTPCookieManager: OFObject
{
	OFMutableArray OF_GENERIC(OFHTTPCookie *) *_cookies;
}

/*!
 * @brief All cookies known to the cookie manager.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OFHTTPCookie *) *cookies;

/*!
 * @brief Create a new cookie manager.
 *
 * @return A new, autoreleased OFHTTPCookieManager
 */
+ (instancetype)manager;

/*!
 * @brief Adds the specified cookie for the specified URL.
 *
 * @warning This modifies the cookie (e.g. it sets the domain if it is unset)!
 *	    If you do not want this, pass a copy!
 *
 * @param cookie The cookie to add to the manager
 * @param URL The URL for which the cookie should be added
 */
- (void)addCookie: (OFHTTPCookie *)cookie
	   forURL: (OFURL *)URL;

/*!
 * @brief Adds the specified cookies for the specified URL.
 *
 * @warning This modifies the cookies (e.g. it sets the domain if it is unset)!
 *	    If you do not want this, pass copies!
 *
 * @param cookies An array of cookies to add to the manager
 * @param URL The URL for which the cookies should be added
 */
- (void)addCookies: (OFArray OF_GENERIC(OFHTTPCookie *) *)cookies
	    forURL: (OFURL *)URL;

/*!
 * @brief Returns the cookies for the specified URL.
 *
 * @param URL The URL for which the cookies should be returned
 * @return The cookies for the specified URL
 */
- (OFArray OF_GENERIC(OFHTTPCookie *) *)cookiesForURL: (OFURL *)URL;

/*!
 * @brief Purges all expired cookies.
 */
- (void)purgeExpiredCookies;
@end

OF_ASSUME_NONNULL_END
