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

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFHTTPCookie;
@class OFIRI;
@class OFMutableArray OF_GENERIC(ObjectType);

/**
 * @class OFHTTPCookieManager OFHTTPCookieManager.h ObjFW/ObjFW.h
 *
 * @brief A class for managing cookies for multiple domains.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFHTTPCookieManager: OFObject
{
	OFMutableArray OF_GENERIC(OFHTTPCookie *) *_cookies;
}

/**
 * @brief All cookies known to the cookie manager.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OFHTTPCookie *) *cookies;

/**
 * @brief Create a new cookie manager.
 *
 * @return A new, autoreleased OFHTTPCookieManager
 */
+ (instancetype)manager;

/**
 * @brief Adds the specified cookie for the specified IRI.
 *
 * @warning This modifies the cookie (e.g. it sets the domain if it is unset)!
 *	    If you do not want this, pass a copy!
 *
 * @param cookie The cookie to add to the manager
 * @param IRI The IRI for which the cookie should be added
 */
- (void)addCookie: (OFHTTPCookie *)cookie forIRI: (OFIRI *)IRI;

/**
 * @brief Adds the specified cookies for the specified IRI.
 *
 * @warning This modifies the cookies (e.g. it sets the domain if it is unset)!
 *	    If you do not want this, pass copies!
 *
 * @param cookies An array of cookies to add to the manager
 * @param IRI The IRI for which the cookies should be added
 */
- (void)addCookies: (OFArray OF_GENERIC(OFHTTPCookie *) *)cookies
	    forIRI: (OFIRI *)IRI;

/**
 * @brief Returns the cookies for the specified IRI.
 *
 * @param IRI The IRI for which the cookies should be returned
 * @return The cookies for the specified IRI
 */
- (OFArray OF_GENERIC(OFHTTPCookie *) *)cookiesForIRI: (OFIRI *)IRI;

/**
 * @brief Purges all expired cookies.
 */
- (void)purgeExpiredCookies;
@end

OF_ASSUME_NONNULL_END
