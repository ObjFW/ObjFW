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
 * \brief An exception indicating there is not enough memory available.
 */
@interface OFOutOfMemoryException: OFException
{
	size_t requestedSize;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) size_t requestedSize;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param size The size of the memory that couldn't be allocated
 * \return A new no memory exception
 */
+  newWithClass: (Class)class_
  requestedSize: (size_t)size;

/**
 * Initializes an already allocated no memory exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param size The size of the memory that couldn't be allocated
 * \return An initialized no memory exception
 */
- initWithClass: (Class)class_
  requestedSize: (size_t)size;

/**
 * \return The size of the memoory that couldn't be allocated
 */
- (size_t)requestedSize;
@end
