/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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
	OFSeekableStream *stream;
	off_t		 offset;
	int		 whence;
	int		 errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFSeekableStream *stream;
@property (readonly) off_t offset;
@property (readonly) int whence;
@property (readonly) int errNo;
#endif

/*!
 * @param stream The stream for which seeking failed
 * @param offset The offset to which seeking failed
 * @param whence To what the offset is relative
 * @return A new seek failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			    stream: (OFSeekableStream*)stream
			    offset: (off_t)offset
			    whence: (int)whence;

/*!
 * Initializes an already allocated seek failed exception.
 *
 * @param stream The stream for which seeking failed
 * @param offset The offset to which seeking failed
 * @param whence To what the offset is relative
 * @return An initialized seek failed exception
 */
- initWithClass: (Class)class_
	 stream: (OFSeekableStream*)stream
	 offset: (off_t)offset
	 whence: (int)whence;

/*!
 * @return The stream for which seeking failed
 */
- (OFSeekableStream*)stream;

/*!
 * @return The offset to which seeking failed
 */
- (off_t)offset;

/*!
 * @return To what the offset is relative
 */
- (int)whence;

/*!
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
