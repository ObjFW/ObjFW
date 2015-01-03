/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <sys/types.h>
#include <sys/stat.h>

#import "OFSeekableStream.h"

@class OFArray;
@class OFDate;

#ifndef _WIN32
typedef struct stat of_stat_t;
#else
typedef struct _stat of_stat_t;
#endif

/*!
 * @class OFFile OFFile.h ObjFW/OFFile.h
 *
 * @brief A class which provides functions to read, write and manipulate files.
 */
@interface OFFile: OFSeekableStream
{
	int  _fd;
	bool _atEndOfStream;
}

/*!
 * @brief Creates a new OFFile with the specified path and mode.
 *
 * @param path The path to the file to open as a string
 * @param mode The mode in which the file should be opened.@n
 *	       Possible modes are:
 *	       Mode           | Description
 *	       ---------------|-------------------------------------
 *	       `r`            | read-only
 *	       `rb`           | read-only, binary
 *	       `r+`           | read-write
 *	       `rb+` or `r+b` | read-write, binary
 *	       `w`            | write-only, create, truncate
 *	       `wb`           | write-only, create, truncate, binary
 *	       `w`            | read-write, create, truncate
 *	       `wb+` or `w+b` | read-write, create, truncate, binary
 *	       `a`            | write-only, create, append
 *	       `ab`           | write-only, create, append, binary
 *	       `a+`           | read-write, create, append
 *	       `ab+` or `a+b` | read-write, create, append, binary
 * @return A new autoreleased OFFile
 */
+ (instancetype)fileWithPath: (OFString*)path
			mode: (OFString*)mode;

/*!
 * @brief Creates a new OFFile with the specified file descriptor.
 *
 * @param fd A file descriptor, returned from for example open().
 *	     It is not closed when the OFFile object is deallocated!
 * @return A new autoreleased OFFile
 */
+ (instancetype)fileWithFileDescriptor: (int)fd;

/*!
 * @brief Returns the path fo the current working directory.
 *
 * @return The path of the current working directory
 */
+ (OFString*)currentDirectoryPath;

/*!
 * @brief Checks whether a file exists at the specified path.
 *
 * @param path The path to check
 * @return A boolean whether there is a file at the specified path
 */
+ (bool)fileExistsAtPath: (OFString*)path;

/*!
 * @brief Checks whether a directory exists at the specified path.
 *
 * @param path The path to check
 * @return A boolean whether there is a directory at the specified path
 */
+ (bool)directoryExistsAtPath: (OFString*)path;

#ifdef OF_HAVE_SYMLINK
/*!
 * @brief Checks whether a symbolic link exists at the specified path.
 *
 * @param path The path to check
 * @return A boolean whether there is a symbolic link at the specified path
 */
+ (bool)symbolicLinkExistsAtPath: (OFString*)path;
#endif

/*!
 * @brief Creates a directory at the specified path.
 *
 * @param path The path of the directory
 */
+ (void)createDirectoryAtPath: (OFString*)path;

/*!
 * @brief Creates a directory at the specified path.
 *
 * @param path The path of the directory
 * @param createParents Whether to create the parents of the directory
 */
+ (void)createDirectoryAtPath: (OFString*)path
		createParents: (bool)createParents;

/*!
 * @brief Returns an array with the items in the specified directory.
 *
 * @note `.` and `..` are not part of the returned array.
 *
 * @param path The path to the directory whose items should be returned
 * @return An array of OFStrings with the items in the specified directory
 */
+ (OFArray*)contentsOfDirectoryAtPath: (OFString*)path;

/*!
 * @brief Changes the current working directory.
 *
 * @param path The new directory to change to
 */
+ (void)changeCurrentDirectoryPath: (OFString*)path;

/*!
 * @brief Returns the size of the specified file.
 *
 * @return The size of the specified file
 */
+ (of_offset_t)sizeOfFileAtPath: (OFString*)path;

/*!
 * @brief Returns the date of the last modification of the file.
 *
 * @return The date of the last modification of the file
 */
+ (OFDate*)modificationDateOfFileAtPath: (OFString*)path;

#ifdef OF_HAVE_CHMOD
/*!
 * @brief Changes the permissions of an item.
 *
 * This method only changes the read-only flag on Windows.
 *
 * @param path The path to the item whose permissions should be changed
 * @param permissions The new permissions for the item
 */
+ (void)changePermissionsOfItemAtPath: (OFString*)path
			  permissions: (mode_t)permissions;
#endif

#ifdef OF_HAVE_CHOWN
/*!
 * @brief Changes the owner of an item.
 *
 * This method is not available on some systems, most notably Windows.
 *
 * @param path The path to the item whose owner should be changed
 * @param owner The new owner for the item
 * @param group The new group for the item
 */
+ (void)changeOwnerOfItemAtPath: (OFString*)path
			  owner: (OFString*)owner
			  group: (OFString*)group;
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
+ (void)copyItemAtPath: (OFString*)source
		toPath: (OFString*)destination;

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
+ (void)moveItemAtPath: (OFString*)source
		toPath: (OFString*)destination;

/*!
 * @brief Removes the item at the specified path.
 *
 * If the item at the specified path is a directory, it is removed recursively.
 *
 * @param path The path to the item which should be removed
 */
+ (void)removeItemAtPath: (OFString*)path;

#ifdef OF_HAVE_LINK
/*!
 * @brief Creates a hard link for the specified item.
 *
 * The destination path must be a full path, which means it must include the
 * name of the item.
 *
 * This method is not available on some systems, most notably Windows.
 *
 * @param source The path of the item for which a link should be created
 * @param destination The path of the item which should link to the source
 */
+ (void)linkItemAtPath: (OFString*)source
		toPath: (OFString*)destination;
#endif

#ifdef OF_HAVE_SYMLINK
/*!
 * @brief Creates a symbolic link for an item.
 *
 * The destination path must be a full path, which means it must include the
 * name of the item.
 *
 * This method is not available on some systems, most notably Windows.
 *
 * @param destination The path of the item which should symbolically link to the
 *		      source
 * @param source The path of the item for which a symbolic link should be
 *		 created
 */
+ (void)createSymbolicLinkAtPath: (OFString*)destination
	     withDestinationPath: (OFString*)source;

/*!
 * @brief Returns the destination of the symbolic link at the specified path.
 *
 * @param path The path to the symbolic link
 * @return The destination of the symbolic link at the specified path
 */
+ (OFString*)destinationOfSymbolicLinkAtPath: (OFString*)path;
#endif

/*!
 * @brief Initializes an already allocated OFFile.
 *
 * @param path The path to the file to open as a string
 * @param mode The mode in which the file should be opened.@n
 *	       Possible modes are:
 *	       Mode           | Description
 *	       ---------------|-------------------------------------
 *	       `r`            | read-only
 *	       `rb`           | read-only, binary
 *	       `r+`           | read-write
 *	       `rb+` or `r+b` | read-write, binary
 *	       `w`            | write-only, create, truncate
 *	       `wb`           | write-only, create, truncate, binary
 *	       `w`            | read-write, create, truncate
 *	       `wb+` or `w+b` | read-write, create, truncate, binary
 *	       `a`            | write-only, create, append
 *	       `ab`           | write-only, create, append, binary
 *	       `a+`           | read-write, create, append
 *	       `ab+` or `a+b` | read-write, create, append, binary
 * @return An initialized OFFile
 */
- initWithPath: (OFString*)path
	  mode: (OFString*)mode;

/*!
 * @brief Initializes an already allocated OFFile.
 *
 * @param fd A file descriptor, returned from for example open().
 *	     It is not closed when the OFFile object is deallocated!
 */
- initWithFileDescriptor: (int)fd;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern int of_stat(OFString *path, of_stat_t *buffer);
extern int of_lstat(OFString *path, of_stat_t *buffer);
#ifdef __cplusplus
}
#endif
