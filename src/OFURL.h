/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

@class OFString;

/**
 * \brief A class for parsing URLs and accessing parts of it.
 */
@interface OFURL: OFObject <OFCopying>
{
	OFString *scheme;
	OFString *host;
	uint16_t port;
	OFString *user;
	OFString *password;
	OFString *path;
	OFString *parameters;
	OFString *query;
	OFString *fragment;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *scheme;
@property (readonly, copy) OFString *host;
@property (readonly, assign) uint16_t port;
@property (readonly, copy) OFString *user;
@property (readonly, copy) OFString *password;
@property (readonly, copy) OFString *path;
@property (readonly, copy) OFString *parameters;
@property (readonly, copy) OFString *query;
@property (readonly, copy) OFString *fragment;
#endif

/**
 * \param str A string describing an URL
 * \return A new, autoreleased OFURL
 */
+ URLWithString: (OFString*)str;

/**
 * Initializes an already allocated OFURL.
 *
 * \param str A string describing an URL
 * \return An initialized OFURL
 */
- initWithString: (OFString*)str;

/**
 * \return The scheme part of the URL
 */
- (OFString*)scheme;

/**
 * \return The host part of the URL
 */
- (OFString*)host;

/**
 * \return The port part of the URL
 */
- (uint16_t)port;

/**
 * \return The user part of the URL
 */
- (OFString*)user;

/**
 * \return The password part of the URL
 */
- (OFString*)password;

/**
 * \return The path part of the URL
 */
- (OFString*)path;

/**
 * \return The parameters part of the URL
 */
- (OFString*)parameters;

/**
 * \return The query part of the URL
 */
- (OFString*)query;

/**
 * \return The fragment part of the URL
 */
- (OFString*)fragment;
@end
