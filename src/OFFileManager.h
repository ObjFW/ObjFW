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
#import "OFURLHandler.h"

OF_ASSUME_NONNULL_BEGIN

#if defined(OF_HAVE_CHMOD) && !defined(OF_AMIGAOS)
# define OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
#endif
#if defined(OF_HAVE_CHOWN) && !defined(OF_AMIGAOS)
# define OF_FILE_MANAGER_SUPPORTS_OWNER
#endif
#if (defined(OF_HAVE_LINK) && !defined(OF_AMIGAOS)) || defined(OF_WINDOWS)
# define OF_FILE_MANAGER_SUPPORTS_LINKS
#endif
#if (defined(OF_HAVE_SYMLINK) && !defined(OF_AMIGAOS)) || defined(OF_WINDOWS)
# define OF_FILE_MANAGER_SUPPORTS_SYMLINKS
#endif

@class OFArray OF_GENERIC(ObjectType);
@class OFDate;
@class OFURL;

/*!
 * @class OFFileManager OFFileManager.h ObjFW/OFFileManager.h
 *
 * @brief A class which provides management for files, e.g. reading contents of
 *	  directories, deleting files, renaming files, etc.
 */
@interface OFFileManager: OFObject
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) OFFileManager *defaultManager;
#endif

/*!
 * @brief The path of the current working directory.
 */
@property (readonly, nonatomic) OFString *currentDirectoryPath;

/*!
 * @brief The URL of the current working directory.
 */
@property (readonly, nonatomic) OFURL *currentDirectoryURL;

/*!
 * @brief Returns the default file manager.
 */
+ (OFFileManager *)defaultManager;

/*!
 * @brief Returns the attributes for the item at the specified path.
 *
 * @param path The path to return the attributes for
 * @return A dictionary of attributes for the specified path, with the keys of
 *	   type @ref of_file_attribute_key_t
 */
- (of_file_attributes_t)attributesOfItemAtPath: (OFString *)path;

/*!
 * @brief Returns the attributes for the item at the specified URL.
 *
 * @param URL The URL to return the attributes for
 * @return A dictionary of attributes for the specified URL, with the keys of
 *	   type @ref of_file_attribute_key_t
 */
- (of_file_attributes_t)attributesOfItemAtURL: (OFURL *)URL;

/*!
 * @brief Sets the attributes for the item at the specified path.
 *
 * All attributes not part of the dictionary are left unchanged.
 *
 * @param attributes The attributes to set for the specified path
 * @param path The path of the item to set the attributes for
 */
- (void)setAttributes: (of_file_attributes_t)attributes
	 ofItemAtPath: (OFString *)path;

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
 * @brief Checks whether a file exists at the specified path.
 *
 * @param path The path to check
 * @return A boolean whether there is a file at the specified path
 */
- (bool)fileExistsAtPath: (OFString *)path;

/*!
 * @brief Checks whether a file exists at the specified URL.
 *
 * @param URL The URL to check
 * @return A boolean whether there is a file at the specified URL
 */
- (bool)fileExistsAtURL: (OFURL *)URL;

/*!
 * @brief Checks whether a directory exists at the specified path.
 *
 * @param path The path to check
 * @return A boolean whether there is a directory at the specified path
 */
- (bool)directoryExistsAtPath: (OFString *)path;

/*!
 * @brief Checks whether a directory exists at the specified URL.
 *
 * @param URL The URL to check
 * @return A boolean whether there is a directory at the specified URL
 */
- (bool)directoryExistsAtURL: (OFURL *)URL;

/*!
 * @brief Creates a directory at the specified path.
 *
 * @param path The path of the directory to create
 */
- (void)createDirectoryAtPath: (OFString *)path;

/*!
 * @brief Creates a directory at the specified path.
 *
 * @param path The path of the directory to create
 * @param createParents Whether to create the parents of the directory
 */
- (void)createDirectoryAtPath: (OFString *)path
		createParents: (bool)createParents;

/*!
 * @brief Creates a directory at the specified URL.
 *
 * @param URL The URL of the directory to create
 */
- (void)createDirectoryAtURL: (OFURL *)URL;

/*!
 * @brief Creates a directory at the specified URL.
 *
 * @param URL The URL of the directory to create
 * @param createParents Whether to create the parents of the directory
 */
- (void)createDirectoryAtURL: (OFURL *)URL
	       createParents: (bool)createParents;

/*!
 * @brief Returns an array with the items in the specified directory.
 *
 * @note `.` and `..` are not part of the returned array.
 *
 * @param path The path to the directory whose items should be returned
 * @return An array of OFString with the items in the specified directory
 */
- (OFArray OF_GENERIC(OFString *) *)contentsOfDirectoryAtPath: (OFString *)path;

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
 * @brief Changes the current working directory.
 *
 * @param path The new directory to change to
 */
- (void)changeCurrentDirectoryPath: (OFString *)path;

/*!
 * @brief Changes the current working directory.
 *
 * @param URL The new directory to change to
 */
- (void)changeCurrentDirectoryURL: (OFURL *)URL;

/*!
 * @brief Copies a file, directory or symbolic link (if supported by the OS).
 *
 * The destination path must be a full path, which means it must include the
 * name of the item.
 *
 * If an item already exists, the copy operation fails. This is also the case
 * if a directory is copied and an item already exists in the destination
 * directory.
 *
 * @param source The file, directory or symbolic link to copy
 * @param destination The destination path
 */
- (void)copyItemAtPath: (OFString *)source
		toPath: (OFString *)destination;

/*!
 * @brief Copies a file, directory or symbolic link (if supported by the OS).
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
 */
- (void)copyItemAtURL: (OFURL *)source
		toURL: (OFURL *)destination;

/*!
 * @brief Moves an item.
 *
 * The destination path must be a full path, which means it must include the
 * name of the item.
 *
 * If the destination is on a different logical device, the source will be
 * copied to the destination using @ref copyItemAtPath:toPath: and the source
 * removed using @ref removeItemAtPath:.
 *
 * @param source The item to rename
 * @param destination The new name for the item
 */
- (void)moveItemAtPath: (OFString *)source
		toPath: (OFString *)destination;

/*!
 * @brief Moves an item.
 *
 * The destination URL must have a full path, which means it must include the
 * name of the item.
 *
 * If the destination is on a different logical device or uses a different
 * scheme, the source will be copied to the destination using
 * @ref copyItemAtURL:toURL: and the source removed using @ref removeItemAtURL:.
 *
 * @param source The item to rename
 * @param destination The new name for the item
 */
- (void)moveItemAtURL: (OFURL *)source
		toURL: (OFURL *)destination;

/*!
 * @brief Removes the item at the specified path.
 *
 * If the item at the specified path is a directory, it is removed recursively.
 *
 * @param path The path to the item which should be removed
 */
- (void)removeItemAtPath: (OFString *)path;

/*!
 * @brief Removes the item at the specified URL.
 *
 * If the item at the specified URL is a directory, it is removed recursively.
 *
 * @param URL The URL to the item which should be removed
 */
- (void)removeItemAtURL: (OFURL *)URL;

#ifdef OF_FILE_MANAGER_SUPPORTS_LINKS
/*!
 * @brief Creates a hard link for the specified item.
 *
 * The destination path must be a full path, which means it must include the
 * name of the item.
 *
 * This method is not available on some systems.
 *
 * @param source The path to the item for which a link should be created
 * @param destination The path to the item which should link to the source
 */
- (void)linkItemAtPath: (OFString *)source
		toPath: (OFString *)destination;
#endif

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

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
/*!
 * @brief Creates a symbolic link for an item.
 *
 * The destination path must be a full path, which means it must include the
 * name of the item.
 *
 * This method is not available on some systems.
 *
 * @note On Windows, this requires at least Windows Vista and administrator
 *	 privileges!
 *
 * @param path The path to the item which should symbolically link to the target
 * @param target The target of the symbolic link
 */
- (void)createSymbolicLinkAtPath: (OFString *)path
	     withDestinationPath: (OFString *)target;
#endif

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
@end

OF_ASSUME_NONNULL_END
