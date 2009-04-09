/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
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

#import "OFObject.h"
#import "OFStream.h"

/**
 * The OFFile class provides functions to read, write and manipulate files.
 */
@interface OFFile: OFObject <OFStream>
{
	FILE *fp;
}

/**
 * \param path The path to the file to open as a C string
 * \param mode The mode in which the file should be opened as a C string
 * \return A new autoreleased OFFile
 */
+ fileWithPath: (const char*)path
       andMode: (const char*)mode;
/**
 * Changes the mode of a file.
 *
 * Not available on Windows.
 *
 * \param path The path to the file of which the mode should be changed as a
 *	  C string
 * \param mode The new mode for the file
 * \return A boolean whether the operation succeeded
 */
+ (void)changeModeOfFile: (const char*)path
		  toMode: (mode_t)mode;

/**
 * Changes the owner of a file.
 *
 * Not available on Windows.
 *
 * \param path The path to the file of which the owner should be changed as a
 *	  C string
 * \param owner The new owner for the file
 * \param group The new group for the file
 * \return A boolean whether the operation succeeded
 */
+ (void)changeOwnerOfFile: (const char*)path
		  toOwner: (uid_t)owner
		 andGroup: (gid_t)group;

/**
 * Deletes a file.
 *
 * \param path The path to the file of which should be deleted as a C string
 * \return A boolean whether the operation succeeded
 */
+ (void)delete: (const char*)path;

/**
 * Hardlinks a file.
 *
 * Not available on Windows.
 *
 * \param src The path to the file of which should be linked as a C string
 * \param dest The path to where the file should be linked as a C string
 * \return A boolean whether the operation succeeded
 */
+ (void)link: (const char*)src
	  to: (const char*)dest;

/**
 * Symlinks a file.
 *
 * Not available on Windows.
 *
 * \param src The path to the file of which should be symlinked as a C string
 * \param dest The path to where the file should be symlinked as a C string
 * \return A boolean whether the operation succeeded
 */
+ (void)symlink: (const char*)src
	     to: (const char*)dest;

/**
 * Initializes an already allocated OFFile.
 *
 * \param path The path to the file to open as a C string
 * \param mode The mode in which the file should be opened as a C string
 * \return An initialized OFFile
 */
- initWithPath: (const char*)path
       andMode: (const char*)mode;

- free;

/**
 * \return A boolean whether the end of the file has been reached
 */
- (BOOL)atEndOfFile;

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
