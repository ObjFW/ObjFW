/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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
#import "OFSerialization.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/*!
 * @class OFURL OFURL.h ObjFW/OFURL.h
 *
 * @brief A class for parsing URLs and accessing parts of it.
 */
@interface OFURL: OFObject <OFCopying, OFSerialization>
{
	OFString *_scheme, *_host;
	uint16_t _port;
	OFString *_user, *_password, *_path, *_parameters, *_query, *_fragment;
}

/*!
 * The scheme part of the URL.
 */
@property (copy) OFString *scheme;

/*!
 * The host part of the URL.
 */
@property (copy) OFString *host;

/*!
 * The port part of the URL.
 */
@property uint16_t port;

/*!
 * The user part of the URL.
 */
@property OF_NULLABLE_PROPERTY (copy) OFString *user;

/*!
 * The password part of the URL.
 */
@property OF_NULLABLE_PROPERTY (copy) OFString *password;

/*!
 * The path part of the URL.
 */
@property (copy) OFString *path;

/*!
 * The parameters part of the URL.
 */
@property OF_NULLABLE_PROPERTY (copy) OFString *parameters;

/*!
 * The query part of the URL.
 */
@property OF_NULLABLE_PROPERTY (copy) OFString *query;

/*!
 * The fragment part of the URL.
 */
@property OF_NULLABLE_PROPERTY (copy) OFString *fragment;

/*!
 * Creates a new URL.
 *
 * @return A new, autoreleased OFURL
 */
+ (instancetype)URL;

/*!
 * Creates a new URL with the specified string.
 *
 * @param string A string describing a URL
 * @return A new, autoreleased OFURL
 */
+ (instancetype)URLWithString: (OFString*)string;

/*!
 * Creates a new URL with the specified string relative to the specified URL.
 *
 * @param string A string describing a URL
 * @param URL An URL to which the string is relative
 * @return A new, autoreleased OFURL
 */
+ (instancetype)URLWithString: (OFString*)string
		relativeToURL: (OFURL*)URL;

/*!
 * @brief Initializes an already allocated OFURL with the specified string.
 *
 * @param string A string describing a URL
 * @return An initialized OFURL
 */
- initWithString: (OFString*)string;

/*!
 * @brief Initializes an already allocated OFURL with the specified string and
 *	  relative URL.
 *
 * @param string A string describing a URL
 * @param URL A URL to which the string is relative
 * @return An initialized OFURL
 */
- initWithString: (OFString*)string
   relativeToURL: (OFURL*)URL;

/*!
 * @brief Returns the URL as a string.
 *
 * @return The URL as a string
 */
- (OFString*)string;
@end

OF_ASSUME_NONNULL_END
