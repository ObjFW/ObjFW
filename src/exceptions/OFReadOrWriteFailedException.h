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

#import "OFException.h"

@class OFStream;

/*!
 * @brief An exception indicating a read or write to a stream failed.
 */
@interface OFReadOrWriteFailedException: OFException
{
	OFStream *stream;
	size_t	 requestedLength;
@public
	int	 errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFStream *stream;
@property (readonly) size_t requestedLength;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased read or write failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param stream The stream which caused the read or write failed exception
 * @param length The requested length of the data that couldn't be read /
 *		 written
 * @return A new, autoreleased read or write failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			    stream: (OFStream*)stream
		   requestedLength: (size_t)length;

/*!
 * @brief Initializes an already allocated read or write failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param stream The stream which caused the read or write failed exception
 * @param length The requested length of the data that couldn't be read /
 *		 written
 * @return A new open file failed exception
 */
-   initWithClass: (Class)class_
	   stream: (OFStream*)stream
  requestedLength: (size_t)length;

/*!
 * @brief Returns the stream which caused the read or write failed exception.
 *
 * @return The stream which caused the read or write failed exception
 */
- (OFStream*)stream;

/*!
 * @brief Returns the requested length of the data that couldn't be read /
 *	  written.
 *
 * @return The requested length of the data that couldn't be read / written
 */
- (size_t)requestedLength;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
