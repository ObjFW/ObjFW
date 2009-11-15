/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <stdio.h>

#ifndef _WIN32
#include <sys/types.h>
#else
typedef int uid_t;
typedef int gid_t;
#endif

#import "OFStream.h"
#import "OFString.h"

/**
 * The OFFile class provides functions to read, write and manipulate files.
 */
@interface OFFile: OFStream
{
	FILE *fp;
	BOOL close;
}

/**
 * \param path The path to the file to open as a string
 * \param mode The mode in which the file should be opened as a string
 * \return A new autoreleased OFFile
 */
+ fileWithPath: (OFString*)path
	  mode: (OFString*)mode;

/**
 * \param fp A file pointer, returned from for example fopen().
 *	     It is not closed when the OFFile object is deallocated!
 * \return A new autoreleased OFFile
 */
+ fileWithFilePointer: (FILE*)fp;

/**
 * Changes the mode of a file.
 *
 * Not available on Windows.
 *
 * \param path The path to the file of which the mode should be changed as a
 *	       string
 * \param mode The new mode for the file
 */
+ (void)changeModeOfFile: (OFString*)path
		  toMode: (mode_t)mode;

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

/**
 * Renames a file.
 *
 * \param from The file to rename
 * \param to The new name
 */
+ (void)rename: (OFString*)from
	    to: (OFString*)to;

/**
 * Deletes a file.
 *
 * \param path The path to the file of which should be deleted as a string
 */
+ (void)delete: (OFString*)path;

/**
 * Hardlinks a file.
 *
 * Not available on Windows.
 *
 * \param src The path to the file of which should be linked as a string
 * \param dest The path to where the file should be linked as a string
 */
+ (void)link: (OFString*)src
	  to: (OFString*)dest;

/**
 * Symlinks a file.
 *
 * Not available on Windows.
 *
 * \param src The path to the file of which should be symlinked as a string
 * \param dest The path to where the file should be symlinked as a string
 */
+ (void)symlink: (OFString*)src
	     to: (OFString*)dest;

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
 * \param fp A file pointer, returned from for example fopen().
 *	     It is not closed when the OFFile object is deallocated!
 */
- initWithFilePointer: (FILE*)fp;

/**
 * Reads from the file into a buffer.
 *
 * \param buf The buffer into which the data is read
 * \param size The size of the data that should be read.
 *	  The buffer MUST be at least size * nitems big!
 * \param nitems nitem The number of items to read
 *	  The buffer MUST be at least size * nitems big!
 * \return The number of bytes read
 */
- (size_t)readNItems: (size_t)nitems
	      ofSize: (size_t)size
	  intoBuffer: (char*)buf;

/**
 * Writes from a buffer into the file.
 *
 * \param buf The buffer from which the data is written to the file
 * \param size The size of the data that should be written
 * \param nitem The number of items to write
 * \return The number of bytes written
 */
- (size_t)writeNItems: (size_t)nitems
	       ofSize: (size_t)size
	   fromBuffer: (const char*)buf;
@end

@interface OFFileSingleton: OFFile
@end

/// An OFFile object for stdin.
extern OFFile *of_stdin;
/// An OFFile object for stdout.
extern OFFile *of_stdout;
/// An OFFile object for stderr.
extern OFFile *of_stderr;
