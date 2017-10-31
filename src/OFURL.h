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

@class OFArray OF_GENERIC(ObjectType);
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
	OFString *_Nullable _query, *_Nullable _fragment;
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
 * The path of the URL split into components.
 *
 * The first component must always be empty to designate the root.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFArray OF_GENERIC(OFString *) *pathComponents;

/*!
 * The last path component of the URL.
 *
 * Returns the empty string if the path is the root.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *lastPathComponent;

/*!
 * The query part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *query;

/*!
 * The fragment part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *fragment;

/*!
 * The URL as a string.
 */
@property (readonly, nonatomic) OFString *string;

/*!
 * The local file system representation for a file URL.
 *
 * @note This only exists for URLs with the file scheme and throws an exception
 *	 otherwise.
 *
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OFString *fileSystemRepresentation;

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

#ifdef OF_HAVE_FILES
/*!
 * @brief Creates a new URL with the specified local file path.
 *
 * If a directory exists at the specified path, a slash is appended if there is
 * no slash yet.
 *
 * @param path The local file path
 * @return A new, autoreleased OFURL
 */
+ (instancetype)fileURLWithPath: (OFString *)path;
#endif

/*!
 * @brief Creates a new URL with the specified local file path.
 *
 * @param path The local file path
 * @param isDirectory Whether the path is a directory, in which case a slash is
 *		      appened if there is no slash yet
 * @return An Initialized OFURL
 */
- (instancetype)initFileURLWithPath: (OFString *)path
			isDirectory: (bool)isDirectory;

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

#ifdef OF_HAVE_FILES
/*!
 * @brief Initializes an already allocated OFURL with the specified local file
 *	  path.
 *
 * If a directory exists at the specified path, a slash is appended if there is
 * no slash yet.
 *
 * @param path The local file path
 * @return An initialized OFURL
 */
- (instancetype)initFileURLWithPath: (OFString *)path;

/*!
 * @brief Initializes an already allocated OFURL with the specified local file
 *	  path.
 *
 * @param path The local file path
 * @param isDirectory Whether the path is a directory, in which case a slash is
 *		      appened if there is no slash yet
 * @return An Initialized OFURL
 */
+ (instancetype)fileURLWithPath: (OFString *)path
		    isDirectory: (bool)isDirectory;
#endif
@end

OF_ASSUME_NONNULL_END

#import "OFMutableURL.h"
