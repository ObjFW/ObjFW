/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

/**
 * \brief A class which provides functions to read, write and manipulate files.
 */
@interface OFFile: OFSeekableStream
{
	int  fileDescriptor;
	BOOL closable;
	BOOL isAtEndOfStream;
}

/**
 * \param path The path to the file to open as a string
 * \param mode The mode in which the file should be opened as a string
 * \return A new autoreleased OFFile
 */
+ fileWithPath: (OFString*)path
	  mode: (OFString*)mode;

/**
 * \param fileDescriptor A file descriptor, returned from for example open().
 *			 It is not closed when the OFFile object is deallocated!
 * \return A new autoreleased OFFile
 */
+ fileWithFileDescriptor: (int)fileDescriptor;

/**
 * \return The path of the current working directory
 */
+ (OFString*)currentDirectoryPath;

/**
 * \param path The path to check
 * \return A boolean whether there is a file at the specified path
 */
+ (BOOL)fileExistsAtPath: (OFString*)path;

/**
 * \param path The path to check
 * \return A boolean whether there is a directory at the specified path
 */
+ (BOOL)directoryExistsAtPath: (OFString*)path;

/**
 * Creates a directory at the specified path.
 *
 * \param path The path of the directory
 */
+ (void)createDirectoryAtPath: (OFString*)path;

/**
 * \param path The path of the directory
 * \return An array of OFStrings with the files at the specified path
 */
+ (OFArray*)filesInDirectoryAtPath: (OFString*)path;

/**
 * Changes the current working directory.
 *
 * \param path The new directory to change to
 */
+ (void)changeToDirectory: (OFString*)path;

/**
 * \return The date of the last modification of the file
 */
+ (OFDate*)modificationDateOfFile: (OFString*)path;

#ifndef _PSP
/**
 * Changes the mode of a file.
 *
 * Only changes read-only flag on Windows.
 *
 * \param path The path to the file of which the mode should be changed as a
 *	       string
 * \param mode The new mode for the file
 */
+ (void)changeModeOfFile: (OFString*)path
		  toMode: (mode_t)mode;
#endif

#if !defined(_WIN32) && !defined(_PSP)
/**
 * Changes the owner of a file.
 *
 * Not available on Windows.
 *
 * \param path The path to the file of which the owner should be changed as a
 *	       string
 * \param owner The new owner for the file
 * \param group The new group for the file
 */
+ (void)changeOwnerOfFile: (OFString*)path
		  toOwner: (OFString*)owner
		    group: (OFString*)group;
#endif

/**
 * Copies a file.
 *
 * \param source The file to copy
 * \param destination The destination path
 */
+ (void)copyFileAtPath: (OFString*)source
		toPath: (OFString*)destination;

/**
 * Renames a file.
 *
 * \param source The file to rename
 * \param destination The new name
 */
+ (void)renameFileAtPath: (OFString*)source
		  toPath: (OFString*)destination;

/**
 * Deletes a file.
 *
 * \param path The path to the file of which should be deleted as a string
 */
+ (void)deleteFileAtPath: (OFString*)path;

/**
 * Deletes an empty directory.
 *
 * \param path The path to the directory which should be deleted as a string
 */
+ (void)deleteDirectoryAtPath: (OFString*)path;

#ifndef _WIN32
/**
 * Hardlinks a file.
 *
 * Not available on Windows.
 *
 * \param source The path to the file of which should be linked as a string
 * \param destination The path to where the file should be linked as a string
 */
+ (void)linkFileAtPath: (OFString*)source
		toPath: (OFString*)destination;
#endif

#if !defined(_WIN32) && !defined(_PSP)
/**
 * Symlinks a file.
 *
 * Not available on Windows.
 *
 * \param source The path to the file of which should be symlinked as a string
 * \param destination The path to where the file should be symlinked as a string
 */
+ (void)symlinkFileAtPath: (OFString*)source
		   toPath: (OFString*)destination;
#endif

/**
 * Initializes an already allocated OFFile.
 *
 * \param path The path to the file to open as a string
 * \param mode The mode in which the file should be opened as a string
 * \return An initialized OFFile
 */
- initWithPath: (OFString*)path
	  mode: (OFString*)mode;

/**
 * Initializes an already allocated OFFile.
 *
 * \param fileDescriptor A file descriptor, returned from for example open().
 *			 It is not closed when the OFFile object is deallocated!
 */
- initWithFileDescriptor: (int)fileDescriptor;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern OFFile *of_stdin;
extern OFFile *of_stdout;
extern OFFile *of_stderr;
#ifdef __cplusplus
}
#endif
