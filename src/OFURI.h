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
#import "OFCharacterSet.h"
#import "OFSerialization.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFNumber;
@class OFPair OF_GENERIC(FirstType, SecondType);
@class OFString;

/**
 * @class OFURI OFURI.h ObjFW/OFURI.h
 *
 * @brief A class for parsing URIs and accessing parts of it.
 */
@interface OFURI: OFObject <OFCopying, OFMutableCopying, OFSerialization>
{
	OFString *_Nullable _percentEncodedScheme;
	OFString *_Nullable _percentEncodedHost;
	OFNumber *_Nullable _port;
	OFString *_Nullable _percentEncodedUser;
	OFString *_Nullable _percentEncodedPassword;
	OFString *_Nullable _percentEncodedPath;
	OFString *_Nullable _percentEncodedQuery;
	OFString *_Nullable _percentEncodedFragment;
	OF_RESERVE_IVARS(OFURI, 4)
}

/**
 * @brief The scheme part of the URI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *scheme;

/**
 * @brief The scheme part of the URI in percent-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *percentEncodedScheme;

/**
 * @brief The host part of the URI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *host;

/**
 * @brief The host part of the URI in percent-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *percentEncodedHost;

/**
 * @brief The port part of the URI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFNumber *port;

/**
 * @brief The user part of the URI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *user;

/**
 * @brief The user part of the URI in percent-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *percentEncodedUser;

/**
 * @brief The password part of the URI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *password;

/**
 * @brief The password part of the URI in percent-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *percentEncodedPassword;

/**
 * @brief The path part of the URI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *path;

/**
 * @brief The path part of the URI in percent-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *percentEncodedPath;

/**
 * @brief The path of the URI split into components.
 *
 * The first component must always be `/` to designate the root.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFArray OF_GENERIC(OFString *) *pathComponents;

/**
 * @brief The last path component of the URI.
 *
 * Returns the empty string if the path is the root.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *lastPathComponent;

/**
 * @brief The query part of the URI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *query;

/**
 * @brief The query part of the URI in percent-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *percentEncodedQuery;

/**
 * @brief The query part of the URI as an array.
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
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, OFString *) *) *queryItems;

/**
 * @brief The fragment part of the URI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *fragment;

/**
 * @brief The fragment part of the URI in URI-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *percentEncodedFragment;

/**
 * @brief The URI as a string.
 */
@property (readonly, nonatomic) OFString *string;

/**
 * @brief The URI with relative subpaths resolved.
 */
@property (readonly, nonatomic) OFURI *URIByStandardizingPath;

#ifdef OF_HAVE_FILES
/**
 * @brief The local file system representation for a file URI.
 *
 * @note This only exists for URIs with the file scheme and throws an exception
 *	 otherwise.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OFString *fileSystemRepresentation;
#endif

/**
 * @brief Creates a new URI with the specified string.
 *
 * @param string A string describing a URI
 * @return A new, autoreleased OFURI
 * @throw OFInvalidFormatException The specified string is not a valid URI
 *				   string
 */
+ (instancetype)URIWithString: (OFString *)string;

/**
 * @brief Creates a new URI with the specified string relative to the
 *	  specified URI.
 *
 * @param string A string describing a relative or absolute URI
 * @param URI An URI to which the string is relative
 * @return A new, autoreleased OFURI
 * @throw OFInvalidFormatException The specified string is not a valid URI
 *				   string
 */
+ (instancetype)URIWithString: (OFString *)string relativeToURI: (OFURI *)URI;

#ifdef OF_HAVE_FILES
/**
 * @brief Creates a new URI with the specified local file path.
 *
 * If a directory exists at the specified path, a slash is appended if there is
 * no slash yet.
 *
 * @param path The local file path
 * @return A new, autoreleased OFURI
 */
+ (instancetype)fileURIWithPath: (OFString *)path;

/**
 * @brief Creates a new URI with the specified local file path.
 *
 * @param path The local file path
 * @param isDirectory Whether the path is a directory, in which case a slash is
 *		      appened if there is no slash yet
 * @return An initialized OFURI
 */
+ (instancetype)fileURIWithPath: (OFString *)path
		    isDirectory: (bool)isDirectory;
#endif

/**
 * @brief Initializes an already allocated OFURI with the specified string.
 *
 * @param string A string describing a URI
 * @return An initialized OFURI
 * @throw OFInvalidFormatException The specified string is not a valid URI
 *				   string
 */
- (instancetype)initWithString: (OFString *)string;

/**
 * @brief Initializes an already allocated OFURI with the specified string and
 *	  relative URI.
 *
 * @param string A string describing a relative or absolute URI
 * @param URI A URI to which the string is relative
 * @return An initialized OFURI
 * @throw OFInvalidFormatException The specified string is not a valid URI
 *				   string
 */
- (instancetype)initWithString: (OFString *)string relativeToURI: (OFURI *)URI;

#ifdef OF_HAVE_FILES
/**
 * @brief Initializes an already allocated OFURI with the specified local file
 *	  path.
 *
 * If a directory exists at the specified path, a slash is appended if there is
 * no slash yet.
 *
 * @param path The local file path
 * @return An initialized OFURI
 */
- (instancetype)initFileURIWithPath: (OFString *)path;

/**
 * @brief Initializes an already allocated OFURI with the specified local file
 *	  path.
 *
 * @param path The local file path
 * @param isDirectory Whether the path is a directory, in which case a slash is
 *		      appened if there is no slash yet
 * @return An initialized OFURI
 */
- (instancetype)initFileURIWithPath: (OFString *)path
			isDirectory: (bool)isDirectory;
#endif

/**
 * @brief Returns a new URI with the specified path component appended.
 *
 * If the URI is a file URI, the file system is queried whether the appended
 * component is a directory.
 *
 * @param component The path component to append. If it starts with the slash,
 *		    the component is not appended, but replaces the path
 *		    instead.
 * @return A new URI with the specified path component appended
 */
- (OFURI *)URIByAppendingPathComponent: (OFString *)component;

/**
 * @brief Returns a new URI with the specified path component appended.
 *
 * @param component The path component to append. If it starts with the slash,
 *		    the component is not appended, but replaces the path
 *		    instead.
 * @param isDirectory Whether the appended component is a directory, meaning
 *		      that the URI path should have a trailing slash
 * @return A new URI with the specified path component appended
 */
- (OFURI *)URIByAppendingPathComponent: (OFString *)component
			   isDirectory: (bool)isDirectory;
@end

@interface OFCharacterSet (URICharacterSets)
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic)
    OFCharacterSet *URISchemeAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URIHostAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URIUserAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URIPasswordAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URIPathAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URIQueryAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URIQueryKeyValueAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *URIFragmentAllowedCharacterSet;
#endif

/**
 * @brief Returns the characters allowed in the scheme part of a URI.
 *
 * @return The characters allowed in the scheme part of a URI.
 */
+ (OFCharacterSet *)URISchemeAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the host part of a URI.
 *
 * @return The characters allowed in the host part of a URI.
 */
+ (OFCharacterSet *)URIHostAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the user part of a URI.
 *
 * @return The characters allowed in the user part of a URI.
 */
+ (OFCharacterSet *)URIUserAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the password part of a URI.
 *
 * @return The characters allowed in the password part of a URI.
 */
+ (OFCharacterSet *)URIPasswordAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the path part of a URI.
 *
 * @return The characters allowed in the path part of a URI.
 */
+ (OFCharacterSet *)URIPathAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the query part of a URI.
 *
 * @return The characters allowed in the query part of a URI.
 */
+ (OFCharacterSet *)URIQueryAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in a key/value in the query part of a
 *	  URI.
 *
 * @return The characters allowed in a key/value in the query part of a URI.
 */
+ (OFCharacterSet *)URIQueryKeyValueAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the fragment part of a URI.
 *
 * @return The characters allowed in the fragment part of a URI.
 */
+ (OFCharacterSet *)URIFragmentAllowedCharacterSet;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern bool OFURIIsIPv6Host(OFString *host);
extern void OFURIVerifyIsEscaped(OFString *, OFCharacterSet *);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END

#import "OFMutableURI.h"
