/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFObject.h"
#import "OFCharacterSet.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFNumber;
@class OFPair OF_GENERIC(FirstType, SecondType);
@class OFString;

/**
 * @class OFIRI OFIRI.h ObjFW/ObjFW.h
 *
 * @brief A class for representing IRIs, URIs, URLs and URNs, for parsing them
 *	  as well as accessing parts of them.
 *
 * This class follows RFC 3976 and RFC 3987.
 */
@interface OFIRI: OFObject <OFCopying, OFMutableCopying>
{
	OFString *_scheme;
	OFString *_Nullable _percentEncodedHost;
	OFNumber *_Nullable _port;
	OFString *_Nullable _percentEncodedUser;
	OFString *_Nullable _percentEncodedPassword;
	OFString *_percentEncodedPath;
	OFString *_Nullable _percentEncodedQuery;
	OFString *_Nullable _percentEncodedFragment;
	OF_RESERVE_IVARS(OFIRI, 4)
}

/**
 * @brief The scheme part of the IRI.
 */
@property (readonly, copy, nonatomic) OFString *scheme;

/**
 * @brief The host part of the IRI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *host;

/**
 * @brief The host part of the IRI in percent-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *percentEncodedHost;

/**
 * @brief The port part of the IRI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFNumber *port;

/**
 * @brief The user part of the IRI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *user;

/**
 * @brief The user part of the IRI in percent-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *percentEncodedUser;

/**
 * @brief The password part of the IRI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *password;

/**
 * @brief The password part of the IRI in percent-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *percentEncodedPassword;

/**
 * @brief The path part of the IRI.
 */
@property (readonly, copy, nonatomic) OFString *path;

/**
 * @brief The path part of the IRI in percent-encoded form.
 */
@property (readonly, copy, nonatomic) OFString *percentEncodedPath;

/**
 * @brief The path of the IRI split into components.
 *
 * The first component must always be `/` to designate the root.
 */
@property (readonly, copy, nonatomic)
    OFArray OF_GENERIC(OFString *) *pathComponents;

/**
 * @brief The last path component of the IRI.
 *
 * Returns the empty string if the path is the root.
 */
@property (readonly, copy, nonatomic) OFString *lastPathComponent;

/**
 * @brief The path extension of the IRI.
 */
@property (readonly, copy, nonatomic) OFString *pathExtension;

/**
 * @brief The query part of the IRI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *query;

/**
 * @brief The query part of the IRI in percent-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
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
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, OFString *) *) *queryItems;

/**
 * @brief The fragment part of the IRI.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic) OFString *fragment;

/**
 * @brief The fragment part of the IRI in percent-encoded form.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFString *percentEncodedFragment;

/**
 * @brief The IRI as a string.
 */
@property (readonly, nonatomic) OFString *string;

/**
 * @brief The IRI with relative subpaths resolved.
 */
@property (readonly, nonatomic) OFIRI *IRIByStandardizingPath;

/**
 * @brief The IRI with the last path component deleted.
 */
@property (readonly, nonatomic) OFIRI *IRIByDeletingLastPathComponent;

/**
 * @brief The IRI with the path extension deleted.
 */
@property (readonly, nonatomic) OFIRI *IRIByDeletingPathExtension;

/**
 * @brief The IRI with percent-encoding added for all Unicode characters.
 */
@property (readonly, nonatomic)
    OFIRI *IRIByAddingPercentEncodingForUnicodeCharacters;

#ifdef OF_HAVE_FILES
/**
 * @brief The local file system representation for a file IRI.
 *
 * @note This only exists for IRIs with the file scheme and throws an exception
 *	 otherwise.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OFString *fileSystemRepresentation;
#endif

/**
 * @brief Creates a new IRI with the specified string.
 *
 * @param string A string describing an IRI
 * @return A new, autoreleased OFIRI
 * @throw OFInvalidFormatException The specified string is not a valid IRI
 *				   string
 */
+ (instancetype)IRIWithString: (OFString *)string;

/**
 * @brief Creates a new IRI with the specified string relative to the
 *	  specified IRI.
 *
 * @param string A string describing a relative or absolute IRI
 * @param IRI An IRI to which the string is relative
 * @return A new, autoreleased OFIRI
 * @throw OFInvalidFormatException The specified string is not a valid IRI
 *				   string
 */
+ (instancetype)IRIWithString: (OFString *)string relativeToIRI: (OFIRI *)IRI;

#ifdef OF_HAVE_FILES
/**
 * @brief Creates a new IRI with the specified local file path.
 *
 * If a directory exists at the specified path, a slash is appended if there is
 * no slash yet.
 *
 * @param path The local file path
 * @return A new, autoreleased OFIRI
 * @throw OFInvalidFormatException The specified path is not a valid path
 */
+ (instancetype)fileIRIWithPath: (OFString *)path;

/**
 * @brief Creates a new IRI with the specified local file path.
 *
 * @param path The local file path
 * @param isDirectory Whether the path is a directory, in which case a slash is
 *		      appended if there is no slash yet
 * @return An initialized OFIRI
 */
+ (instancetype)fileIRIWithPath: (OFString *)path
		    isDirectory: (bool)isDirectory;
#endif

/**
 * @brief Initializes an already allocated OFIRI with the specified string.
 *
 * @param string A string describing an IRI
 * @return An initialized OFIRI
 * @throw OFInvalidFormatException The specified string is not a valid IRI
 *				   string
 */
- (instancetype)initWithString: (OFString *)string;

/**
 * @brief Initializes an already allocated OFIRI with the specified string and
 *	  relative IRI.
 *
 * @param string A string describing a relative or absolute IRI
 * @param IRI An IRI to which the string is relative
 * @return An initialized OFIRI
 * @throw OFInvalidFormatException The specified string is not a valid IRI
 *				   string
 */
- (instancetype)initWithString: (OFString *)string relativeToIRI: (OFIRI *)IRI;

#ifdef OF_HAVE_FILES
/**
 * @brief Initializes an already allocated OFIRI with the specified local file
 *	  path.
 *
 * If a directory exists at the specified path, a slash is appended if there is
 * no slash yet.
 *
 * @param path The local file path
 * @return An initialized OFIRI
 * @throw OFInvalidFormatException The specified path is not a valid path
 */
- (instancetype)initFileIRIWithPath: (OFString *)path;

/**
 * @brief Initializes an already allocated OFIRI with the specified local file
 *	  path.
 *
 * @param path The local file path
 * @param isDirectory Whether the path is a directory, in which case a slash is
 *		      appended if there is no slash yet
 * @return An initialized OFIRI
 */
- (instancetype)initFileIRIWithPath: (OFString *)path
			isDirectory: (bool)isDirectory;
#endif

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Returns a new IRI with the specified path component appended.
 *
 * If the IRI is a file IRI, the file system is queried whether the appended
 * component is a directory.
 *
 * @param component The path component to append. If it starts with the slash,
 *		    the component is not appended, but replaces the path
 *		    instead.
 * @return A new IRI with the specified path component appended
 */
- (OFIRI *)IRIByAppendingPathComponent: (OFString *)component;

/**
 * @brief Returns a new IRI with the specified path component appended.
 *
 * @param component The path component to append. If it starts with the slash,
 *		    the component is not appended, but replaces the path
 *		    instead.
 * @param isDirectory Whether the appended component is a directory, meaning
 *		      that the IRI path should have a trailing slash
 * @return A new IRI with the specified path component appended
 */
- (OFIRI *)IRIByAppendingPathComponent: (OFString *)component
			   isDirectory: (bool)isDirectory;

/**
 * @brief Returns a new IRI with the specified path extension appended.
 *
 * @param extension The path extension to append
 * @return A new IRI with the specified path extension appended.
 */
- (OFIRI *)IRIByAppendingPathExtension: (OFString *)extension;
@end

@interface OFCharacterSet (IRICharacterSets)
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic)
    OFCharacterSet *IRISchemeAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *IRIHostAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *IRIUserAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *IRIPasswordAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *IRIPathAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *IRIQueryAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *IRIQueryKeyValueAllowedCharacterSet;
@property (class, readonly, nonatomic)
    OFCharacterSet *IRIFragmentAllowedCharacterSet;
#endif

/**
 * @brief Returns the characters allowed in the scheme part of an IRI.
 *
 * @return The characters allowed in the scheme part of an IRI.
 */
+ (OFCharacterSet *)IRISchemeAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the host part of an IRI.
 *
 * @return The characters allowed in the host part of an IRI.
 */
+ (OFCharacterSet *)IRIHostAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the user part of an IRI.
 *
 * @return The characters allowed in the user part of an IRI.
 */
+ (OFCharacterSet *)IRIUserAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the password part of an IRI.
 *
 * @return The characters allowed in the password part of an IRI.
 */
+ (OFCharacterSet *)IRIPasswordAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the path part of an IRI.
 *
 * @return The characters allowed in the path part of an IRI.
 */
+ (OFCharacterSet *)IRIPathAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the query part of an IRI.
 *
 * @return The characters allowed in the query part of an IRI.
 */
+ (OFCharacterSet *)IRIQueryAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in a key/value in the query part of a
 *	  IRI.
 *
 * @return The characters allowed in a key/value in the query part of an IRI.
 */
+ (OFCharacterSet *)IRIQueryKeyValueAllowedCharacterSet;

/**
 * @brief Returns the characters allowed in the fragment part of an IRI.
 *
 * @return The characters allowed in the fragment part of an IRI.
 */
+ (OFCharacterSet *)IRIFragmentAllowedCharacterSet;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableIRI.h"
