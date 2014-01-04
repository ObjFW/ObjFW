/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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
#import "OFSerialization.h"

@class OFString;

/*!
 * @brief A class for parsing URLs and accessing parts of it.
 */
@interface OFURL: OFObject <OFCopying, OFSerialization>
{
	OFString *_scheme, *_host;
	uint16_t _port;
	OFString *_user, *_password, *_path, *_parameters, *_query, *_fragment;
}

#ifdef OF_HAVE_PROPERTIES
@property (copy) OFString *scheme;
@property (copy) OFString *host;
@property uint16_t port;
@property (copy) OFString *user;
@property (copy) OFString *password;
@property (copy) OFString *path;
@property (copy) OFString *parameters;
@property (copy) OFString *query;
@property (copy) OFString *fragment;
#endif

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
 * @brief Returns the scheme part of the URL.
 *
 * @return The scheme part of the URL
 */
- (OFString*)scheme;

/*!
 * @brief Set the scheme part of the URL.
 *
 * @param scheme The scheme part of the URL to set
 */
- (void)setScheme: (OFString*)scheme;

/*!
 * @brief Returns the host part of the URL.
 *
 * @return The host part of the URL
 */
- (OFString*)host;

/*!
 * @brief Set the host part of the URL.
 *
 * @param host The host part of the URL to set
 */
- (void)setHost: (OFString*)host;

/*!
 * @brief Returns the port part of the URL.
 *
 * @return The port part of the URL
 */
- (uint16_t)port;

/*!
 * @brief Set the port part of the URL.
 *
 * @param port The port part of the URL to set
 */
- (void)setPort: (uint16_t)port;

/*!
 * @brief Returns the user part of the URL.
 *
 * @return The user part of the URL
 */
- (OFString*)user;

/*!
 * @brief Set the user part of the URL.
 *
 * @param user The user part of the URL to set
 */
- (void)setUser: (OFString*)user;

/*!
 * @brief Returns the password part of the URL.
 *
 * @return The password part of the URL
 */
- (OFString*)password;

/*!
 * @brief Set the password part of the URL.
 *
 * @param password The password part of the URL to set
 */
- (void)setPassword: (OFString*)password;

/*!
 * @brief Returns the path part of the URL.
 *
 * @return The path part of the URL
 */
- (OFString*)path;

/*!
 * @brief Set the path part of the URL.
 *
 * @param path The path part of the URL to set
 */
- (void)setPath: (OFString*)path;

/*!
 * @brief Returns the parameters part of the URL.
 *
 * @return The parameters part of the URL
 */
- (OFString*)parameters;

/*!
 * @brief Set the parameters part of the URL.
 *
 * @param parameters The parameters part of the URL to set
 */
- (void)setParameters: (OFString*)parameters;

/*!
 * @brief Returns the query part of the URL.
 *
 * @return The query part of the URL
 */
- (OFString*)query;

/*!
 * @brief Set the query part of the URL.
 *
 * @param query The query part of the URL to set
 */
- (void)setQuery: (OFString*)query;

/*!
 * @brief Returns the fragment part of the URL.
 *
 * @return The fragment part of the URL
 */
- (OFString*)fragment;

/*!
 * @brief Set the fragment part of the URL.
 *
 * @param fragment The fragment part of the URL to set
 */
- (void)setFragment: (OFString*)fragment;

/*!
 * @brief Returns the URL as a string.
 *
 * @return The URL as a string
 */
- (OFString*)string;
@end
