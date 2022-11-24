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

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFHTTPCookie;
@class OFIRI;
@class OFMutableArray OF_GENERIC(ObjectType);

/**
 * @class OFHTTPCookieManager OFHTTPCookieManager.h ObjFW/OFHTTPCookieManager.h
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
