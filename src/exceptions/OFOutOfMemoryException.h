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

#import "OFException.h"

/*!
 * @class OFOutOfMemoryException \
 *	  OFOutOfMemoryException.h ObjFW/OFOutOfMemoryException.h
 *
 * @brief An exception indicating there is not enough memory available.
 */
@interface OFOutOfMemoryException: OFException
{
	size_t _requestedSize;
}

/*!
 * The size of the memory that could not be allocated.
 */
@property (readonly) size_t requestedSize;

/*!
 * @brief Creates a new, autoreleased no memory exception.
 *
 * @param requestedSize The size of the memory that could not be allocated
 * @return A new, autoreleased no memory exception
 */
+ (instancetype)exceptionWithRequestedSize: (size_t)requestedSize;

/*!
 * @brief Initializes an already allocated no memory exception.
 *
 * @param requestedSize The size of the memory that could not be allocated
 * @return An initialized no memory exception
 */
- initWithRequestedSize: (size_t)requestedSize;
@end
