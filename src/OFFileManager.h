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
#import "OFSeekableStream.h"

OF_ASSUME_NONNULL_BEGIN

#if defined(OF_HAVE_CHMOD) && !defined(OF_MORPHOS)
# define OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
#endif
#if defined(OF_HAVE_CHOWN) && !defined(OF_MORPHOS)
# define OF_FILE_MANAGER_SUPPORTS_OWNER
#endif
#if (defined(OF_HAVE_LINK) && !defined(OF_MORPHOS)) || defined(OF_WINDOWS)
# define OF_FILE_MANAGER_SUPPORTS_LINKS
#endif
#if (defined(OF_HAVE_SYMLINK) && !defined(OF_MORPHOS)) || defined(OF_WINDOWS)
# define OF_FILE_MANAGER_SUPPORTS_SYMLINKS
#endif

@class OFArray OF_GENERIC(ObjectType);
@class OFDate;

/*!
 * @class OFFileManager OFFileManager.h ObjFW/OFFileManager.h
 *
 * @brief A class which provides management for files, e.g. reading contents of
 *	  directories, deleting files, renaming files, etc.
 */
@interface OFFileManager: OFObject
/*!
 * @brief Returns the default file manager.
 */
+ (OFFileManager *)defaultManager;

/*!
 * @brief Returns the path for the current working directory.
 *
 * @return The path of the current working directory
 */
- (OFString *)currentDirectoryPath;

/*!
 * @brief Checks whether a file exists at the specified path.
 *
 * @param path The path to check
 * @return A boolean whether there is a file at the specified path
 */
- (bool)fileExistsAtPath: (OFString *)path;

/*!
 * @brief Checks whether a directory exists at the specified path.
 *
 * @param path The path to check
 * @return A boolean whether there is a directory at the specified path
 */
- (bool)directoryExistsAtPath: (OFString *)path;

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
/*!
 * @brief Checks whether a symbolic link exists at the specified path.
 *
 * @param path The path to check
 * @return A boolean whether there is a symbolic link at the specified path
 */
- (bool)symbolicLinkExistsAtPath: (OFString *)path;
#endif

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
 * @brief Returns an array with the items in the specified directory.
 *
 * @note `.` and `..` are not part of the returned array.
 *
 * @param path The path to the directory whose items should be returned
 * @return An array of OFString with the items in the specified directory
 */
- (OFArray OF_GENERIC(OFString *) *)contentsOfDirectoryAtPath: (OFString *)path;

/*!
 * @brief Changes the current working directory.
 *
 * @param path The new directory to change to
 */
- (void)changeCurrentDirectoryPath: (OFString *)path;

/*!
 * @brief Returns the size of the specified file.
 *
 * @param path The path to the file whose size should be returned
 *
 * @return The size of the specified file
 */
- (of_offset_t)sizeOfFileAtPath: (OFString *)path;

/*!
 * @brief Returns the last access time of the specified item.
 *
 * @param path The path to the item whose last access time should be returned
 *
 * @return The last access time of the specified item
 */
- (OFDate *)accessTimeOfItemAtPath: (OFString *)path;

/*!
 * @brief Returns the last modification date of the specified item.
 *
 * @param path The path to the item whose last modification date should be
 *	       returned
 *
 * @return The last modification date of the specified item
 */
- (OFDate *)modificationDateOfItemAtPath: (OFString *)path;

/*!
 * @brief Returns the last status change time of the specified item.
 *
 * @param path The path to the item whose last status change time should be
 *	       returned
 *
 * @return The last status change time of the specified item
 */
- (OFDate *)statusChangeTimeOfItemAtPath: (OFString *)path;

#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
/*!
 * @brief Returns the permissions of the specified item.
 *
 * This returns only the permissions, meaning read, write and execute for
 * owner, user and group, along with the sticky, setuid and setgid bit. In
 * other words, only bits that match the mask 07777.
 *
 * @param path The path to the item whose permissions should be returned
 *
 * @return The permissions of the specified item
 */
- (uint16_t)permissionsOfItemAtPath: (OFString *)path;

/*!
 * @brief Changes the permissions of an item.
 *
 * This only changes the permissions, meaning read, write and execute for
 * owner, user and group. For security reasons, it ignores all other bits. In
 * other words, the permissions are masked with 0777.
 *
 * This method only changes the read-only flag on Windows.
 *
 * @param path The path to the item whose permissions should be changed
 * @param permissions The new permissions for the item
 */
- (void)changePermissionsOfItemAtPath: (OFString *)path
			  permissions: (uint16_t)permissions;
#endif

#ifdef OF_FILE_MANAGER_SUPPORTS_OWNER
/*!
 * @brief Get the UID and GID of the specified item.
 *
 * @param UID A pointer to an uint16_t to store the UID, or NULL
 * @param GID A pointer to an uint16_t to store the GID, or NULL
 * @param path The path to the item whose UID and GID should be retrieved
 */
- (void)getUID: (nullable uint16_t *)UID
	   GID: (nullable uint16_t *)GID
  ofItemAtPath: (OFString *)path;

/*!
 * @brief Get the owner and group of the specified item.
 *
 * @param owner A pointer to an `OFString *` to store the owner, or NULL
 * @param group A pointer to an `OFString *` to store the group, or NULL
 * @param path The path to the item whose owner and group should be retrieved
 */
- (void)getOwner: (OFString *__autoreleasing _Nonnull *_Nullable)owner
	   group: (OFString *__autoreleasing _Nonnull *_Nullable)group
    ofItemAtPath: (OFString *)path;

/*!
 * @brief Changes the owner of an item.
 *
 * This method is not available on some systems, most notably Windows.
 *
 * @param path The path to the item whose owner should be changed
 * @param owner The new owner for the item
 * @param group The new group for the item
 */
- (void)changeOwnerOfItemAtPath: (OFString *)path
			  owner: (OFString *)owner
			  group: (OFString *)group;
#endif

/*!
 * @brief Copies a file, directory or symlink (if supported by the OS).
 *
 * The destination path must be a full path, which means it must include the
 * name of the item.
 *
 * If an item already exists, the copy operation fails. This is also the case
 * if a directory is copied and an item already exists in the destination
 * directory.
 *
 * @param source The file, directory or symlink to copy
 * @param destination The destination path
 */
- (void)copyItemAtPath: (OFString *)source
		toPath: (OFString *)destination;

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
 * @brief Removes the item at the specified path.
 *
 * If the item at the specified path is a directory, it is removed recursively.
 *
 * @param path The path to the item which should be removed
 */
- (void)removeItemAtPath: (OFString *)path;

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
 * @param destination The path to the item which should symbolically link to the
 *		      source
 * @param source The path to the item for which a symbolic link should be
 *		 created
 */
- (void)createSymbolicLinkAtPath: (OFString *)destination
	     withDestinationPath: (OFString *)source;

/*!
 * @brief Returns the destination of the symbolic link at the specified path.
 *
 * @param path The path to the symbolic link
 *
 * @note On Windows, at least Windows Vista is required.
 *
 * @return The destination of the symbolic link at the specified path
 */
- (OFString *)destinationOfSymbolicLinkAtPath: (OFString *)path;
#endif
@end

OF_ASSUME_NONNULL_END
