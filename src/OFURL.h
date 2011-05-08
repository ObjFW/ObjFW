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
#import "OFSerialization.h"

@class OFString;

/**
 * \brief A class for parsing URLs and accessing parts of it.
 */
@interface OFURL: OFObject <OFCopying, OFSerialization>
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
@property (copy) OFString *scheme;
@property (copy) OFString *host;
@property (assign) uint16_t port;
@property (copy) OFString *user;
@property (copy) OFString *password;
@property (copy) OFString *path;
@property (copy) OFString *parameters;
@property (copy) OFString *query;
@property (copy) OFString *fragment;
#endif

/**
 * \param string A string describing a URL
 * \return A new, autoreleased OFURL
 */
+ URLWithString: (OFString*)string;

/**
 * \param string A string describing a URL
 * \param URL An URL to which the string is relative
 * \return A new, autoreleased OFURL
 */
+ URLWithString: (OFString*)string
  relativeToURL: (OFURL*)URL;

/**
 * Initializes an already allocated OFURL.
 *
 * \param string A string describing a URL
 * \return An initialized OFURL
 */
- initWithString: (OFString*)string;

/**
 * Initializes an already allocated OFURL.
 *
 * \param string A string describing a URL
 * \param URL A URL to which the string is relative
 * \return An initialized OFURL
 */
- initWithString: (OFString*)string
   relativeToURL: (OFURL*)url;

/**
 * \return The scheme part of the URL
 */
- (OFString*)scheme;

/**
 * Set the scheme part of the URL.
 *
 * \param scheme The scheme part of the URL to set
 */
- (void)setScheme: (OFString*)scheme;

/**
 * \return The host part of the URL
 */
- (OFString*)host;

/**
 * Set the host part of the URL.
 *
 * \param host The host part of the URL to set
 */
- (void)setHost: (OFString*)host;

/**
 * \return The port part of the URL
 */
- (uint16_t)port;

/**
 * Set the port part of the URL.
 *
 * \param port The port part of the URL to set
 */
- (void)setPort: (uint16_t)port;

/**
 * \return The user part of the URL
 */
- (OFString*)user;

/**
 * Set the user part of the URL.
 *
 * \param user The user part of the URL to set
 */
- (void)setUser: (OFString*)user;

/**
 * \return The password part of the URL
 */
- (OFString*)password;

/**
 * Set the password part of the URL.
 *
 * \param password The password part of the URL to set
 */
- (void)setPassword: (OFString*)password;

/**
 * \return The path part of the URL
 */
- (OFString*)path;

/**
 * Set the path part of the URL.
 *
 * \param path The path part of the URL to set
 */
- (void)setPath: (OFString*)path;

/**
 * \return The parameters part of the URL
 */
- (OFString*)parameters;

/**
 * Set the parameters part of the URL.
 *
 * \param parameters The parameters part of the URL to set
 */
- (void)setParameters: (OFString*)parameters;

/**
 * \return The query part of the URL
 */
- (OFString*)query;

/**
 * Set the query part of the URL.
 *
 * \param query The query part of the URL to set
 */
- (void)setQuery: (OFString*)query;

/**
 * \return The fragment part of the URL
 */
- (OFString*)fragment;

/**
 * Set the fragment part of the URL.
 *
 * \param fragment The fragment part of the URL to set
 */
- (void)setFragment: (OFString*)fragment;

/**
 * \brief Returns the URL as a string.
 *
 * \return The URL as a string
 */
- (OFString*)string;
@end
