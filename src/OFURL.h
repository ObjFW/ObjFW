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
#import "OFSerialization.h"

OF_ASSUME_NONNULL_BEGIN

@class OFNumber;
@class OFString;

/*!
 * @class OFURL OFURL.h ObjFW/OFURL.h
 *
 * @brief A class for parsing URLs and accessing parts of it.
 */
@interface OFURL: OFObject <OFCopying, OFMutableCopying, OFSerialization>
{
	OFString *_Nullable _scheme, *_Nullable _host;
	OFNumber *_Nullable _port;
	OFString *_Nullable _user, *_Nullable _password, *_path;
	OFString *_Nullable _parameters, *_Nullable _query;
	OFString *_Nullable _fragment;
}

/*!
 * The scheme part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *scheme;

/*!
 * The host part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *host;

/*!
 * The port part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFNumber *port;

/*!
 * The user part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *user;

/*!
 * The password part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *password;

/*!
 * The path part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *path;

/*!
 * The parameters part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *parameters;

/*!
 * The query part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *query;

/*!
 * The fragment part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *fragment;

/*!
 * @brief Creates a new URL with the specified string.
 *
 * @param string A string describing a URL
 * @return A new, autoreleased OFURL
 */
+ (instancetype)URLWithString: (OFString *)string;

/*!
 * @brief Creates a new URL with the specified string relative to the
 *	  specified URL.
 *
 * @param string A string describing a URL
 * @param URL An URL to which the string is relative
 * @return A new, autoreleased OFURL
 */
+ (instancetype)URLWithString: (OFString *)string
		relativeToURL: (OFURL *)URL;

/*!
 * @brief Creates a new URL with the specified local file path.
 *
 * @param path The local file path
 * @return A new, autoreleased OFURL
 */
+ (instancetype)fileURLWithPath: (OFString *)path;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFURL with the specified string.
 *
 * @param string A string describing a URL
 * @return An initialized OFURL
 */
- (instancetype)initWithString: (OFString *)string;

/*!
 * @brief Initializes an already allocated OFURL with the specified string and
 *	  relative URL.
 *
 * @param string A string describing a URL
 * @param URL A URL to which the string is relative
 * @return An initialized OFURL
 */
- (instancetype)initWithString: (OFString *)string
		 relativeToURL: (OFURL *)URL;

/*!
 * @brief Returns the URL as a string.
 *
 * @return The URL as a string
 */
- (OFString *)string;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableURL.h"
