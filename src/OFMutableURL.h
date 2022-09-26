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

#import "OFURL.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableURL OFMutableURL.h ObjFW/OFMutableURL.h
 *
 * @brief A class for parsing URLs and accessing parts of it.
 */
@interface OFMutableURL: OFURL
{
	OF_RESERVE_IVARS(OFMutableURL, 4)
}

/**
 * @brief The scheme part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *scheme;

/**
 * @brief The scheme part of the URL in URL-encoded form.
 *
 * Setting this retains the original URL-encoding used - if more characters
 * than necessary are URL-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The scheme being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *URLEncodedScheme;

/**
 * @brief The host part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *host;

/**
 * @brief The host part of the URL in URL-encoded form.
 *
 * Setting this retains the original URL-encoding used - if more characters
 * than necessary are URL-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The host being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *URLEncodedHost;

/**
 * @brief The port part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFNumber *port;

/**
 * @brief The user part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *user;

/**
 * @brief The user part of the URL in URL-encoded form.
 *
 * Setting this retains the original URL-encoding used - if more characters
 * than necessary are URL-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The user being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *URLEncodedUser;

/**
 * @brief The password part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *password;

/**
 * @brief The password part of the URL in URL-encoded form.
 *
 * Setting this retains the original URL-encoding used - if more characters
 * than necessary are URL-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The password being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *URLEncodedPassword;

/**
 * @brief The path part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *path;

/**
 * @brief The path part of the URL in URL-encoded form.
 *
 * Setting this retains the original URL-encoding used - if more characters
 * than necessary are URL-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The path being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *URLEncodedPath;

/**
 * @brief The path of the URL split into components.
 *
 * The first component must always be empty to designate the root.
 *
 * @throw OFInvalidFormatException The path components being set are not in the
 *				   correct format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFArray OF_GENERIC(OFString *) *pathComponents;

/**
 * @brief The query part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *query;

/**
 * @brief The query part of the URL in URL-encoded form.
 *
 * Setting this retains the original URL-encoding used - if more characters
 * than necessary are URL-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The query being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *URLEncodedQuery;

/**
 * @brief The query part of the URL as a dictionary.
 *
 * For example, a query like `key1=value1&key2=value2` would correspond to the
 * following dictionary:
 *
 *     @{
 *         @"key1": @"value1",
 *         @"key2": @"value2"
 *     }
 *
 * @throw OFInvalidFormatException The query is not in the correct format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFDictionary OF_GENERIC(OFString *, OFString *) *queryDictionary;

/**
 * @brief The fragment part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *fragment;

/**
 * @brief The fragment part of the URL in URL-encoded form.
 *
 * Setting this retains the original URL-encoding used - if more characters
 * than necessary are URL-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The fragment being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *URLEncodedFragment;

/**
 * @brief Creates a new mutable URL.
 *
 * @return A new, autoreleased OFMutableURL
 */
+ (instancetype)URL;

/**
 * @brief Appends the specified path component.
 *
 * @param component The component to append
 */
- (void)appendPathComponent: (OFString *)component;

/**
 * @brief Appends the specified path component.
 *
 * @param component The component to append
 * @param isDirectory Whether the path is a directory, in which case a slash is
 *		      appened if there is no slash yet
 */
- (void)appendPathComponent: (OFString *)component
		isDirectory: (bool)isDirectory;

/**
 * @brief Resolves relative subpaths.
 */
- (void)standardizePath;

/**
 * @brief Converts the mutable URL to an immutable URL.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
