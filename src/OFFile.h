/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFSeekableStream.h"
#import "OFKernelEventObserver.h"

#ifndef OF_AMIGAOS
# define OF_FILE_HANDLE_IS_FD
typedef int OFFileHandle;
static const OFFileHandle OFInvalidFileHandle = -1;
#else
typedef struct _OFFileHandle *OFFileHandle;
static const OFFileHandle OFInvalidFileHandle = NULL;
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFFile OFFile.h ObjFW/ObjFW.h
 *
 * @brief A class which provides methods to read and write files.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFFile: OFSeekableStream
#ifdef OF_FILE_HANDLE_IS_FD
    <OFReadyForReadingObserving, OFReadyForWritingObserving>
#endif
{
	OFFileHandle _handle;
	bool _initialized, _atEndOfStream;
}

/**
 * @brief Creates a new OFFile with the specified path and mode.
 *
 * @param path The path to the file to open as a string
 * @param mode The mode in which the file should be opened.
 *             @n
 *	       Possible modes are:
 *	       Mode           | Description
 *	       ---------------|-------------------------------------
 *	       `r`            | Read-only
 *	       `r+`           | Read-write
 *	       `w`            | Write-only, create or truncate
 *	       `wx`           | Write-only, create or fail, exclusive
 *	       `w+`           | Read-write, create or truncate
 *	       `w+x`          | Read-write, create or fail, exclusive
 *	       `a`            | Write-only, create or append
 *	       `a+`           | Read-write, create or append
 * @return A new autoreleased OFFile
 * @throw OFOpenItemFailedException Opening the file failed
 */
+ (instancetype)fileWithPath: (OFString *)path mode: (OFString *)mode;

/**
 * @brief Creates a new OFFile with the specified native file handle.
 *
 * @param handle A native file handle. If OF_FILE_HANDLE_IS_FD is defined, this
 *		 is a file descriptor. The handle is closed when the OFFile
 *		 object is deallocated!
 * @return A new autoreleased OFFile
 */
+ (instancetype)fileWithHandle: (OFFileHandle)handle;

/**
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
 * @throw OFOpenItemFailedException Opening the file failed
 */
- (instancetype)initWithPath: (OFString *)path mode: (OFString *)mode;

/**
 * @brief Initializes an already allocated OFFile.
 *
 * @param handle A native file handle. If OF_FILE_HANDLE_IS_FD is defined, this
 *		 is a file descriptor. The handle is closed when the OFFile
 *		 object is deallocated!
 * @return An initialized OFFile
 */
- (instancetype)initWithHandle: (OFFileHandle)handle OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
