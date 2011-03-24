/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

/**
 * \brief An exception indicating a read or write to a stream failed.
 */
@interface OFReadOrWriteFailedException: OFException
{
	size_t requestedSize;
@public
	int    errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) size_t requestedSize;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \return A new open file failed exception
 */
+  newWithClass: (Class)class_
  requestedSize: (size_t)size;

/**
 * Initializes an already allocated read or write failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \return A new open file failed exception
 */
- initWithClass: (Class)class_
  requestedSize: (size_t)size;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The requested size of the data that couldn't be read / written
 */
- (size_t)requestedSize;
@end
