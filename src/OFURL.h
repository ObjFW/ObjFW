/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
#import "OFCharacterSet.h"
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
	OFString *_Nullable _URLEncodedScheme, *_Nullable _URLEncodedHost;
	OFNumber *_Nullable _port;
	OFString *_Nullable _URLEncodedUser, *_Nullable _URLEncodedPassword;
	OFString *_Nullable _URLEncodedPath;
	OFString *_Nullable _URLEncodedQuery, *_Nullable _URLEncodedFragment;
}

/*!
 * @brief The scheme part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *scheme;

/*!
 * @brief The scheme part of the URL in URL-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *URLEncodedScheme;

/*!
 * @brief The host part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *host;

/*!
 * @brief The host part of the URL in URL-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *URLEncodedHost;

/*!
 * @brief The port part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFNumber *port;

/*!
 * @brief The user part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *user;

/*!
 * @brief The user part of the URL in URL-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *URLEncodedUser;

/*!
 * @brief The password part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *password;

/*!
 * @brief The password part of the URL in URL-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *URLEncodedPassword;

/*!
 * @brief The path part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *path;

/*!
 * @brief The path part of the URL in URL-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *URLEncodedPath;

/*!
 * @brief The path of the URL split into components.
 *
 * The first component must always be empty to designate the root.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFArray OF_GENERIC(OFString *) *pathComponents;

/*!
 * @brief The last path component of the URL.
 *
 * Returns the empty string if the path is the root.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *lastPathComponent;

/*!
 * @brief The query part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *query;

/*!
 * @brief The query part of the URL in URL-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *URLEncodedQuery;

/*!
 * @brief The fragment part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *fragment;

/*!
 * @brief The fragment part of the URL in URL-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *URLEncodedFragment;

/*!
 * @brief The URL as a string.
 */
@property (readonly, nonatomic) OFString *string;

#ifdef OF_HAVE_FILES
/*!
 * @brief The local file system representation for a file URL.
 *
 * @note This only exists for URLs with the file scheme and throws an exception
 *	 otherwise.
 *
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OFString *fileSystemRepresentation;
#endif

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

/*!
 * @brief Creates a new URL with the specified local file path.
 *
 * @param path The local file path
 * @param isDirectory Whether the path is a directory, in which case a slash is
 *		      appened if there is no slash yet
 * @return An Initialized OFURL
 */
+ (instancetype)fileURLWithPath: (OFString *)path
		    isDirectory: (bool)isDirectory;
#endif

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
- (instancetype)initFileURLWithPath: (OFString *)path
			isDirectory: (bool)isDirectory;
#endif

/*!
 * @brief Returns a new URL with the specified path component appended.
 *
 * If the URL is a file URL, the file system is queried whether the appended
 * component is a directory.
 *
 * @param component The path component to append. If it starts with the slash,
 *		    the component is not appended, but replaces the path
 *		    instead.
 * @return A new URL with the specified path component appended
 */
- (OFURL *)URLByAppendingPathComponent: (OFString *)component;

/*!
 * @brief Returns a new URL with the specified path component appended.
 *
 * @param component The path component to append. If it starts with the slash,
 *		    the component is not appended, but replaces the path
 *		    instead.
 * @param isDirectory Whether the appended component is a directory, meaning
 *		      that the URL path should have a trailing slash
 * @return A new URL with the specified path component appended
 */
- (OFURL *)URLByAppendingPathComponent: (OFString *)component
			   isDirectory: (bool)isDirectory;
@end

@interface OFCharacterSet (URLCharacterSets)
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic)
    OFCharacterSet *URLSchemeAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URLHostAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URLUserAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URLPasswordAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URLPathAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URLQueryAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URLFragmentAllowedCharacterSet;
#endif

/*!
 * @brief Returns the characters allowed in the scheme part of a URL.
 *
 * @return The characters allowed in the scheme part of a URL.
 */
+ (OFCharacterSet *)URLSchemeAllowedCharacterSet;

/*!
 * @brief Returns the characters allowed in the host part of a URL.
 *
 * @return The characters allowed in the host part of a URL.
 */
+ (OFCharacterSet *)URLHostAllowedCharacterSet;

/*!
 * @brief Returns the characters allowed in the user part of a URL.
 *
 * @return The characters allowed in the user part of a URL.
 */
+ (OFCharacterSet *)URLUserAllowedCharacterSet;

/*!
 * @brief Returns the characters allowed in the password part of a URL.
 *
 * @return The characters allowed in the password part of a URL.
 */
+ (OFCharacterSet *)URLPasswordAllowedCharacterSet;

/*!
 * @brief Returns the characters allowed in the path part of a URL.
 *
 * @return The characters allowed in the path part of a URL.
 */
+ (OFCharacterSet *)URLPathAllowedCharacterSet;

/*!
 * @brief Returns the characters allowed in the query part of a URL.
 *
 * @return The characters allowed in the query part of a URL.
 */
+ (OFCharacterSet *)URLQueryAllowedCharacterSet;

/*!
 * @brief Returns the characters allowed in the fragment part of a URL.
 *
 * @return The characters allowed in the fragment part of a URL.
 */
+ (OFCharacterSet *)URLFragmentAllowedCharacterSet;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableURL.h"
