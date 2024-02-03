/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "OFIRI.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableIRI OFMutableIRI.h ObjFW/OFMutableIRI.h
 *
 * @brief A class for representing IRIs, URIs, URLs and URNs, for parsing them,
 *	  accessing parts of them as well as modifying them.
 *
 * This class follows RFC 3976 and RFC 3987.
 */
@interface OFMutableIRI: OFIRI
{
	OF_RESERVE_IVARS(OFMutableIRI, 4)
}

/**
 * @brief The scheme part of the IRI.
 *
 * @throw OFInvalidFormatException The scheme being set is not in the correct
 *				   format
 */
@property (readwrite, copy, nonatomic) OFString *scheme;

/**
 * @brief The host part of the IRI.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *host;

/**
 * @brief The host part of the IRI in percent-encoded form.
 *
 * Setting this retains the original percent-encoding used - if more characters
 * than necessary are percent-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The host being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *percentEncodedHost;

/**
 * @brief The port part of the IRI.
 *
 * @throw OFInvalidArgumentException The port is not valid (e.g. negative or
 *				     too big)
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFNumber *port;

/**
 * @brief The user part of the IRI.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *user;

/**
 * @brief The user part of the IRI in percent-encoded form.
 *
 * Setting this retains the original percent-encoding used - if more characters
 * than necessary are percent-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The user being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *percentEncodedUser;

/**
 * @brief The password part of the IRI.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *password;

/**
 * @brief The password part of the IRI in percent-encoded form.
 *
 * Setting this retains the original percent-encoding used - if more characters
 * than necessary are percent-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The password being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *percentEncodedPassword;

/**
 * @brief The path part of the IRI.
 */
@property (readwrite, copy, nonatomic) OFString *path;

/**
 * @brief The path part of the IRI in percent-encoded form.
 *
 * Setting this retains the original percent-encoding used - if more characters
 * than necessary are percent-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The path being set is not in the correct
 *				   format
 */
@property (readwrite, copy, nonatomic) OFString *percentEncodedPath;

/**
 * @brief The path of the IRI split into components.
 *
 * The first component must always be empty to designate the root.
 *
 * @throw OFInvalidFormatException The path components being set are not in the
 *				   correct format
 */
@property (readwrite, copy, nonatomic)
    OFArray OF_GENERIC(OFString *) *pathComponents;

/**
 * @brief The query part of the IRI.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *query;

/**
 * @brief The query part of the IRI in percent-encoded form.
 *
 * Setting this retains the original percent-encoding used - if more characters
 * than necessary are percent-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The query being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *percentEncodedQuery;

/**
 * @brief The query part of the IRI as an array.
 *
 * For example, a query like `key1=value1&key2=value2` would correspond to the
 * following array:
 *
 *     @[
 *         [OFPair pairWithFirstObject: @"key1" secondObject: @"value1"],
 *         [OFPair pairWithFirstObject: @"key2" secondObject: @"value2"],
 *     ]
 *
 * @throw OFInvalidFormatException The query is not in the correct format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, OFString *) *) *queryItems;

/**
 * @brief The fragment part of the IRI.
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic) OFString *fragment;

/**
 * @brief The fragment part of the IRI in percent-encoded form.
 *
 * Setting this retains the original percent-encoding used - if more characters
 * than necessary are percent-encoded, it is kept this way.
 *
 * @throw OFInvalidFormatException The fragment being set is not in the correct
 *				   format
 */
@property OF_NULLABLE_PROPERTY (readwrite, copy, nonatomic)
    OFString *percentEncodedFragment;

/**
 * @brief Creates a new mutable IRI with the specified schemed.
 *
 * @param scheme The scheme for the IRI
 * @return A new, autoreleased OFMutableIRI
 */
+ (instancetype)IRIWithScheme: (OFString *)scheme;

/**
 * @brief Initializes an already allocated mutable IRI with the specified
 *	  schemed.
 *
 * @param scheme The scheme for the IRI
 * @return An initialized OFMutableIRI
 */
- (instancetype)initWithScheme: (OFString *)scheme;

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
 *		      appended if there is no slash yet
 */
- (void)appendPathComponent: (OFString *)component
		isDirectory: (bool)isDirectory;

/**
 * @brief Resolves relative subpaths.
 */
- (void)standardizePath;

/**
 * @brief Converts the mutable IRI to an immutable IRI.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
