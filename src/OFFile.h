/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <sys/types.h>
#include <sys/stat.h>

#import "OFSeekableStream.h"

OF_ASSUME_NONNULL_BEGIN

#if defined(OF_WINDOWS)
typedef struct __stat64 of_stat_t;
#elif defined(OF_HAVE_OFF64_T)
typedef struct stat64 of_stat_t;
#else
typedef struct stat of_stat_t;
#endif

/*!
 * @class OFFile OFFile.h ObjFW/OFFile.h
 *
 * @brief A class which provides functions to read and write files.
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

OF_ASSUME_NONNULL_END
