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

#include <sys/types.h>

#import "OFException.h"

@class OFSeekableStream;

/*!
 * @brief An exception indicating that seeking in a stream failed.
 */
@interface OFSeekFailedException: OFException
{
	OFSeekableStream *_stream;
	off_t _offset;
	int _whence, _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFSeekableStream *stream;
@property (readonly) off_t offset;
@property (readonly) int whence, errNo;
#endif

/*!
 * @brief Creates a new, autoreleased seek failed exception.
 *
 * @param stream The stream for which seeking failed
 * @param offset The offset to which seeking failed
 * @param whence To what the offset is relative
 * @return A new, autoreleased seek failed exception
 */
+ (instancetype)exceptionWithStream: (OFSeekableStream*)stream
			     offset: (off_t)offset
			     whence: (int)whence;

/*!
 * @brief Initializes an already allocated seek failed exception.
 *
 * @param stream The stream for which seeking failed
 * @param offset The offset to which seeking failed
 * @param whence To what the offset is relative
 * @return An initialized seek failed exception
 */
- initWithStream: (OFSeekableStream*)stream
	  offset: (off_t)offset
	  whence: (int)whence;

/*!
 * @brief Returns the stream for which seeking failed.
 *
 * @return The stream for which seeking failed
 */
- (OFSeekableStream*)stream;

/*!
 * @brief Returns the offset to which seeking failed.
 *
 * @return The offset to which seeking failed
 */
- (off_t)offset;

/*!
 * @brief Returns to what the offset is relative.
 *
 * @return To what the offset is relative
 */
- (int)whence;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
