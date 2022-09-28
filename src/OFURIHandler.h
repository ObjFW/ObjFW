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

#import "OFFileManager.h"
#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDate;
@class OFStream;
@class OFURI;

/**
 * @class OFURIHandler OFURIHandler.h ObjFW/OFURIHandler.h
 *
 * @brief A handler for a URI scheme.
 */
@interface OFURIHandler: OFObject
{
	OFString *_scheme;
	OF_RESERVE_IVARS(OFURIHandler, 4)
}

/**
 * @brief The scheme this OFURIHandler handles.
 */
@property (readonly, nonatomic) OFString *scheme;

/**
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
+ (bool)registerClass: (Class)class_ forScheme: (OFString *)scheme;

/**
 * @brief Returns the handler for the specified URI.
 *
 * @return The handler for the specified URI.
 */
+ (OFURIHandler *)handlerForURI: (OFURI *)URI;

/**
 * @brief Opens the item at the specified URI.
 *
 * @param URI The URI of the item which should be opened
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
 * @return The opened stream if it was successfully opened
 * @throw OFOpenItemFailedException Opening the item failed
 */
+ (OFStream *)openItemAtURI: (OFURI *)URI mode: (OFString *)mode;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes the handler for the specified scheme.
 *
 * @param scheme The scheme to initialize for
 * @return An initialized URI handler
 */
- (instancetype)initWithScheme: (OFString *)scheme OF_DESIGNATED_INITIALIZER;

/**
 * @brief Opens the item at the specified URI.
 *
 * @param URI The URI of the item which should be opened
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
 * @return The opened stream if it was successfully opened
 * @throw OFOpenItemFailedException Opening the item failed
 */
- (OFStream *)openItemAtURI: (OFURI *)URI mode: (OFString *)mode;

/**
 * @brief Returns the attributes for the item at the specified URI.
 *
 * @param URI The URI to return the attributes for
 * @return A dictionary of attributes for the specified URI, with the keys of
 *	   type @ref OFFileAttributeKey
 */
- (OFFileAttributes)attributesOfItemAtURI: (OFURI *)URI;

/**
 * @brief Sets the attributes for the item at the specified URI.
 *
 * All attributes not part of the dictionary are left unchanged.
 *
 * @param attributes The attributes to set for the specified URI
 * @param URI The URI of the item to set the attributes for
 */
- (void)setAttributes: (OFFileAttributes)attributes ofItemAtURI: (OFURI *)URI;

/**
 * @brief Checks whether a file exists at the specified URI.
 *
 * @param URI The URI to check
 * @return A boolean whether there is a file at the specified URI
 */
- (bool)fileExistsAtURI: (OFURI *)URI;

/**
 * @brief Checks whether a directory exists at the specified URI.
 *
 * @param URI The URI to check
 * @return A boolean whether there is a directory at the specified URI
 */
- (bool)directoryExistsAtURI: (OFURI *)URI;

/**
 * @brief Creates a directory at the specified URI.
 *
 * @param URI The URI of the directory to create
 */
- (void)createDirectoryAtURI: (OFURI *)URI;

/**
 * @brief Returns an array with the URIs of the items in the specified
 *	  directory.
 *
 * @note `.` and `..` are not part of the returned array.
 *
 * @param URI The URI to the directory whose items should be returned
 * @return An array with the URIs of the items in the specified directory
 */
- (OFArray OF_GENERIC(OFURI *) *)contentsOfDirectoryAtURI: (OFURI *)URI;

/**
 * @brief Removes the item at the specified URI.
 *
 * If the item at the specified URI is a directory, it is removed recursively.
 *
 * @param URI The URI to the item which should be removed
 */
- (void)removeItemAtURI: (OFURI *)URI;

/**
 * @brief Creates a hard link for the specified item.
 *
 * The destination URI must have a full path, which means it must include the
 * name of the item.
 *
 * This method is not available for all URIs.
 *
 * @param source The URI to the item for which a link should be created
 * @param destination The URI to the item which should link to the source
 */
- (void)linkItemAtURI: (OFURI *)source toURI: (OFURI *)destination;

/**
 * @brief Creates a symbolic link for an item.
 *
 * The destination URI must have a full path, which means it must include the
 * name of the item.
 *
 * This method is not available for all URIs.
 *
 * @note On Windows, this requires at least Windows Vista and administrator
 *	 privileges!
 *
 * @param URI The URI to the item which should symbolically link to the target
 * @param target The target of the symbolic link
 */
- (void)createSymbolicLinkAtURI: (OFURI *)URI
	    withDestinationPath: (OFString *)target;

/**
 * @brief Tries to efficiently copy an item. If a copy would only be possible
 *	  by reading the entire item and then writing it, it returns false.
 *
 * The destination URI must have a full path, which means it must include the
 * name of the item.
 *
 * If an item already exists, the copy operation fails. This is also the case
 * if a directory is copied and an item already exists in the destination
 * directory.
 *
 * @param source The file, directory or symbolic link to copy
 * @param destination The destination URI
 * @return True if an efficient copy was performed, false if an efficient copy
 *	   was not possible. Note that errors while performing a copy are
 *	   reported via exceptions and not by returning false!
 */
- (bool)copyItemAtURI: (OFURI *)source toURI: (OFURI *)destination;

/**
 * @brief Tries to efficiently move an item. If a move would only be possible
 *	  by copying the source and deleting it, it returns false.
 *
 * The destination URI must have a full path, which means it must include the
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
- (bool)moveItemAtURI: (OFURI *)source toURI: (OFURI *)destination;
@end

OF_ASSUME_NONNULL_END
