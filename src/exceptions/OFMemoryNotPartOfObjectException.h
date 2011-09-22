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
 * \brief An exception indicating the given memory is not part of the object.
 */
@interface OFMemoryNotPartOfObjectException: OFException
{
	void *pointer;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) void *pointer;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param ptr A pointer to the memory that is not part of the object
 * \return A new memory not part of object exception
 */
+ exceptionWithClass: (Class)class_
	     pointer: (void*)ptr;

/**
 * Initializes an already allocated memory not part of object exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param ptr A pointer to the memory that is not part of the object
 * \return An initialized memory not part of object exception
 */
- initWithClass: (Class)class_
	pointer: (void*)ptr;

/**
 * \return A pointer to the memory which is not part of the object
 */
- (void*)pointer;
@end
