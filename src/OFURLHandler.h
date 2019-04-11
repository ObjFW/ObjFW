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

#import "OFFileManager.h"
#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDate;
@class OFStream;
@class OFURL;

/*!
 * @class OFURLHandler OFURLHandler.h ObjFW/OFURLHandler.h
 *
 * @brief A handler for a URL scheme.
 */
@interface OFURLHandler: OFObject
{
	OFString *_scheme;
}

/*!
 * @brief The scheme this OFURLHandler handles.
 */
@property (readonly, nonatomic) OFString *scheme;

/*!
 * @brief Registers the specified class as the handler for the specified scheme.
 *
 * If the same class is specified for two schemes, one instance of it is
 * created per scheme.
 *
 * @param class_ The class to register as the handler for the specified scheme
 * @param scheme The scheme for which to register the handler
 * @return Whether the class was successfully registered. If a handler for the
 *	   same scheme is already registered, registration fails.
 */
+ (bool)registerClass: (Class)class_
	    forScheme: (OFString *)scheme;

/*!
 * @brief Returns the handler for the specified URL.
 *
 * @return The handler for the specified URL.
 */
+ (nullable OF_KINDOF(OFURLHandler *))handlerForURL: (OFURL *)URL;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes the handler for the specified scheme.
 *
 * @param scheme The scheme to initialize for
 * @return An initialized URL handler
 */
- (instancetype)initWithScheme: (OFString *)scheme OF_DESIGNATED_INITIALIZER;

/*!
 * @brief Opens the item at the specified URL.
 *
 * @param URL The URL of the item which should be opened
 * @param mode The mode in which the file should be opened.@n
 *	       Possible modes are:
 *	       @n
 *	       Mode           | Description
 *	       ---------------|-------------------------------------
 *	       `r`            | Read-only
 *	       `r+`           | Read-write
 *	       `w`            | Write-only, create or truncate
 *	       `wx`           | Write-only, create or fail, exclusive
 *	       `w+`           | Read-write, create or truncate
 *	       `w+x`          | Read-write, create or fail, exclusive
 *	       `a`            | Write-only, create or append
 *	       `a+`           | Read-write, create or append
 *	       @n
 *	       The handler is allowed to not implement all modes and is also
 *	       allowed to implement additional, scheme-specific modes.
 */
- (OFStream *)openItemAtURL: (OFURL *)URL
		       mode: (OFString *)mode;

/*!
 * @brief Returns the attributes for the item at the specified URL.
 *
 * @param URL The URL to return the attributes for
 * @return A dictionary of attributes for the specified URL, with the keys of
 *	   type @ref of_file_attribute_key_t
 */
- (of_file_attributes_t)attributesOfItemAtURL: (OFURL *)URL;

/*!
 * @brief Sets the attributes for the item at the specified URL.
 *
 * All attributes not part of the dictionary are left unchanged.
 *
 * @param attributes The attributes to set for the specified URL
 * @param URL The URL of the item to set the attributes for
 */
- (void)setAttributes: (of_file_attributes_t)attributes
	  ofItemAtURL: (OFURL *)URL;

/*!
 * @brief Checks whether a file exists at the specified URL.
 *
 * @param URL The URL to check
 * @return A boolean whether there is a file at the specified URL
 */
- (bool)fileExistsAtURL: (OFURL *)URL;

/*!
 * @brief Checks whether a directory exists at the specified URL.
 *
 * @param URL The URL to check
 * @return A boolean whether there is a directory at the specified URL
 */
- (bool)directoryExistsAtURL: (OFURL *)URL;

/*!
 * @brief Creates a directory at the specified URL.
 *
 * @param URL The URL of the directory to create
 */
- (void)createDirectoryAtURL: (OFURL *)URL;

/*!
 * @brief Returns an array with the items in the specified directory.
 *
 * @note `.` and `..` are not part of the returned array.
 *
 * @param URL The URL to the directory whose items should be returned
 * @return An array of OFString with the items in the specified directory
 */
- (OFArray OF_GENERIC(OFString *) *)contentsOfDirectoryAtURL: (OFURL *)URL;

/*!
 * @brief Removes the item at the specified URL.
 *
 * If the item at the specified URL is a directory, it is removed recursively.
 *
 * @param URL The URL to the item which should be removed
 */
- (void)removeItemAtURL: (OFURL *)URL;

/*!
 * @brief Creates a hard link for the specified item.
 *
 * The destination URL must have a full path, which means it must include the
 * name of the item.
 *
 * This method is not available for all URLs.
 *
 * @param source The URL to the item for which a link should be created
 * @param destination The URL to the item which should link to the source
 */
- (void)linkItemAtURL: (OFURL *)source
		toURL: (OFURL *)destination;

/*!
 * @brief Creates a symbolic link for an item.
 *
 * The destination uRL must have a full path, which means it must include the
 * name of the item.
 *
 * This method is not available for all URLs.
 *
 * @note On Windows, this requires at least Windows Vista and administrator
 *	 privileges!
 *
 * @param URL The URL to the item which should symbolically link to the target
 * @param target The target of the symbolic link
 */
- (void)createSymbolicLinkAtURL: (OFURL *)URL
	    withDestinationPath: (OFString *)target;

/*!
 * @brief Tries to efficiently copy an item. If a copy would only be possible
 *	  by reading the entire item and then writing it, it returns false.
 *
 * The destination URL must have a full path, which means it must include the
 * name of the item.
 *
 * If an item already exists, the copy operation fails. This is also the case
 * if a directory is copied and an item already exists in the destination
 * directory.
 *
 * @param source The file, directory or symbolic link to copy
 * @param destination The destination URL
 * @return True if an efficient copy was performed, false if an efficient copy
 *	   was not possible. Note that errors while performing a copy are
 *	   reported via exceptions and not by returning false!
 */
- (bool)copyItemAtURL: (OFURL *)source
		toURL: (OFURL *)destination;

/*!
 * @brief Tries to efficiently move an item. If a move would only be possible
 *	  by copying the source and deleting it, it returns false.
 *
 * The destination URL must have a full path, which means it must include the
 * name of the item.
 *
 * If the destination is on a different logical device or uses a different
 * scheme, an efficient move is not possible and false is returned.
 *
 * @param source The item to rename
 * @param destination The new name for the item
 * @return True if an efficient move was performed, false if an efficient move
 *	   was not possible. Note that errors while performing a move are
 *	   reported via exceptions and not by returning false!
 */
- (bool)moveItemAtURL: (OFURL *)source
		toURL: (OFURL *)destination;
@end

OF_ASSUME_NONNULL_END
