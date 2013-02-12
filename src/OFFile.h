/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "OFSeekableStream.h"

@class OFArray;
@class OFDate;

#ifdef __cplusplus
extern "C" {
#endif
extern void of_log(OFConstantString*, ...);
#ifdef __cplusplus
}
#endif

/*!
 * @brief A class which provides functions to read, write and manipulate files.
 */
@interface OFFile: OFSeekableStream
{
	int  _fd;
	BOOL _closable;
	BOOL _atEndOfStream;
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
+ (BOOL)fileExistsAtPath: (OFString*)path;

/*!
 * @brief Checks whether a directory exists at the specified path.
 *
 * @param path The path to check
 * @return A boolean whether there is a directory at the specified path
 */
+ (BOOL)directoryExistsAtPath: (OFString*)path;

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
		createParents: (BOOL)createParents;

/*!
 * @brief Returns an array with the files in the specified directory.
 *
 * @param path The path of the directory
 * @return An array of OFStrings with the files at the specified path
 */
+ (OFArray*)filesInDirectoryAtPath: (OFString*)path;

/*!
 * @brief Changes the current working directory.
 *
 * @param path The new directory to change to
 */
+ (void)changeToDirectoryAtPath: (OFString*)path;

/*!
 * @brief Returns the size of the specified file.
 *
 * @return The size of the specified file
 */
+ (off_t)sizeOfFileAtPath: (OFString*)path;

/*!
 * @brief Returns the date of the last modification of the file.
 *
 * @return The date of the last modification of the file
 */
+ (OFDate*)modificationDateOfFileAtPath: (OFString*)path;

#ifndef _PSP
/*!
 * @brief Changes the mode of a file.
 *
 * Only changes read-only flag on Windows.
 *
 * @param path The path to the file of which the mode should be changed as a
 *	       string
 * @param mode The new mode for the file
 */
+ (void)changeModeOfFileAtPath: (OFString*)path
			  mode: (mode_t)mode;
#endif

#if !defined(_WIN32) && !defined(_PSP)
/*!
 * @brief Changes the owner of a file.
 *
 * Not available on Windows.
 *
 * @param path The path to the file of which the owner should be changed as a
 *	       string
 * @param owner The new owner for the file
 * @param group The new group for the file
 */
+ (void)changeOwnerOfFileAtPath: (OFString*)path
			  owner: (OFString*)owner
			  group: (OFString*)group;
#endif

/*!
 * @brief Copies a file.
 *
 * @param source The file to copy
 * @param destination The destination path
 */
+ (void)copyFileAtPath: (OFString*)source
		toPath: (OFString*)destination;

/*!
 * @brief Renames a file.
 *
 * @param source The file to rename
 * @param destination The new name
 */
+ (void)renameFileAtPath: (OFString*)source
		  toPath: (OFString*)destination;

/*!
 * @brief Deletes a file.
 *
 * @param path The path to the file of which should be deleted as a string
 */
+ (void)deleteFileAtPath: (OFString*)path;

/*!
 * @brief Deletes an empty directory.
 *
 * @param path The path to the directory which should be deleted as a string
 */
+ (void)deleteDirectoryAtPath: (OFString*)path;

#ifndef _WIN32
/*!
 * @brief Creates a hard link for a file.
 *
 * Not available on Windows.
 *
 * @param source The path to the file of which should be linked as a string
 * @param destination The path to where the file should be linked as a string
 */
+ (void)linkFileAtPath: (OFString*)source
		toPath: (OFString*)destination;
#endif

#if !defined(_WIN32) && !defined(_PSP)
/*!
 * @brief Creates a symbolink link for a file.
 *
 * Not available on Windows.
 *
 * @param source The path to the file of which should be symlinked as a string
 * @param destination The path to where the file should be symlinked as a string
 */
+ (void)symlinkFileAtPath: (OFString*)source
		   toPath: (OFString*)destination;
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
/*! @file */

/*!
 * @brief The standard input stream.
 */
extern OFStream *of_stdin;

/*!
 * @brief The standard output stream.
 */
extern OFStream *of_stdout;

/*!
 * @brief The standard error stream.
 */
extern OFStream *of_stderr;
#ifdef __cplusplus
}
#endif
