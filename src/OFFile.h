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

#import "OFSeekableStream.h"

OF_ASSUME_NONNULL_BEGIN

#if defined(OF_MORPHOS) && !defined(OF_IXEMUL)
typedef long BPTR;
#endif

/*!
 * @class OFFile OFFile.h ObjFW/OFFile.h
 *
 * @brief A class which provides methods to read and write files.
 */
@interface OFFile: OFSeekableStream
{
#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
	int _fd;
#else
	BPTR _handle;
	bool _append;
#endif
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
+ (instancetype)fileWithPath: (OFString *)path
			mode: (OFString *)mode;

#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
/*!
 * @brief Creates a new OFFile with the specified file descriptor.
 *
 * @param fd A file descriptor, returned from for example open().
 *	     It is closed when the OFFile object is deallocated!
 * @return A new autoreleased OFFile
 */
+ (instancetype)fileWithFileDescriptor: (int)fd;
#else
/*!
 * @brief Creates a new OFFile with the specified handle.
 *
 * @param handle A handle, returned from for example Open().
 *		 It is closed when the OFFile object is deallocated!
 * @return A new autoreleased OFFile
 */
+ (instancetype)fileWithHandle: (BPTR)handle;
#endif

- init OF_UNAVAILABLE;

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
- initWithPath: (OFString *)path
	  mode: (OFString *)mode;

#if !defined(OF_MORPHOS) || defined(OF_IXEMUL)
/*!
 * @brief Initializes an already allocated OFFile.
 *
 * @param fd A file descriptor, returned from for example open().
 *	     It is closed when the OFFile object is deallocated!
 * @return An initialized OFFile
 */
- initWithFileDescriptor: (int)fd;
#else
/*!
 * @brief Initializes an already allocated OFFile.
 *
 * @param handle A handle, returned from for example Open().
 *		 It is closed when the OFFile object is deallocated!
 * @return An initialized OFFile
 */
- initWithHandle: (BPTR)handle;
#endif
@end

OF_ASSUME_NONNULL_END
