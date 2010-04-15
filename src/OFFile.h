/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <sys/types.h>

#import "OFSeekableStream.h"

@class OFString;
@class OFArray;

/**
 * \brief A class which provides functions to read, write and manipulate files.
 */
@interface OFFile: OFSeekableStream
{
	int fd;
	BOOL closable;
	BOOL eos;
}

/**
 * \param path The path to the file to open as a string
 * \param mode The mode in which the file should be opened as a string
 * \return A new autoreleased OFFile
 */
+ fileWithPath: (OFString*)path
	  mode: (OFString*)mode;

/**
 * \param fd A file descriptor, returned from for example open().
 *	     It is not closed when the OFFile object is deallocated!
 * \return A new autoreleased OFFile
 */
+ fileWithFileDescriptor: (int)fd;

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

#ifndef _WIN32
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
		  toOwner: (uid_t)owner
		    group: (gid_t)group;
#endif

/**
 * Renames a file.
 *
 * \param from The file to rename
 * \param to The new name
 */
+ (void)renameFileWithPath: (OFString*)from
		    toPath: (OFString*)to;

/**
 * Deletes a file.
 *
 * \param path The path to the file of which should be deleted as a string
 */
+ (void)deleteFileWithPath: (OFString*)path;

#ifndef _WIN32
/**
 * Hardlinks a file.
 *
 * Not available on Windows.
 *
 * \param src The path to the file of which should be linked as a string
 * \param dest The path to where the file should be linked as a string
 */
+ (void)linkFileWithPath: (OFString*)src
		  toPath: (OFString*)dest;

/**
 * Symlinks a file.
 *
 * Not available on Windows.
 *
 * \param src The path to the file of which should be symlinked as a string
 * \param dest The path to where the file should be symlinked as a string
 */
+ (void)symlinkFileWithPath: (OFString*)src
		     toPath: (OFString*)dest;
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
 * \param fd A file descriptor, returned from for example open().
 *	     It is not closed when the OFFile object is deallocated!
 */
- initWithFileDescriptor: (int)fd;
@end

/// An OFFile object for stdin
extern OFFile *of_stdin;
/// An OFFile object for stdout
extern OFFile *of_stdout;
/// An OFFile object for stderr
extern OFFile *of_stderr;
