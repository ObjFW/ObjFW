/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#include <errno.h>

#import "OFException.h"

/*!
 * @brief An exception indicating that reading from or writing to an object
 *	  failed.
 */
@interface OFReadOrWriteFailedException: OFException
{
	id _object;
	size_t _requestedLength;
@public
	int _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain) id object;
@property (readonly) size_t requestedLength;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased read or write failed exception.
 *
 * @param object The object from which reading or to which writing failed
 * @param requestedLength The requested length of the data that couldn't be
 *			  read / written
 * @return A new, autoreleased read or write failed exception
 */
+ (instancetype)exceptionWithObject: (id)object
		    requestedLength: (size_t)requestedLength;

/*!
 * @brief Initializes an already allocated read or write failed exception.
 *
 * @param object The object from which reading or to which writing failed
 * @param requestedLength The requested length of the data that couldn't be
 *			  read / written
 * @return A new open file failed exception
 */
-  initWithObject: (id)object
  requestedLength: (size_t)requestedLength;

/*!
 * @brief Returns the object from which reading or to which writing failed
 *
 * @return The stream which caused the read or write failed exception
 */
- (id)object;

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
