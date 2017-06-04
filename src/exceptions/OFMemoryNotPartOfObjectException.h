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

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFMemoryNotPartOfObjectException \
 *	  OFMemoryNotPartOfObjectException.h \
 *	  ObjFW/OFMemoryNotPartOfObjectException.h
 *
 * @brief An exception indicating the given memory is not part of the object.
 */
@interface OFMemoryNotPartOfObjectException: OFException
{
	void *_pointer;
	id _object;
}

/*!
 * A pointer to the memory which is not part of the object.
 */
@property (readonly, nonatomic) void *pointer;

/*!
 * The object which the memory is not part of.
 */
@property (readonly, nonatomic) id object;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased memory not part of object exception.
 *
 * @param pointer A pointer to the memory that is not part of the object
 * @param object The object which the memory is not part of
 * @return A new, autoreleased memory not part of object exception
 */
+ (instancetype)exceptionWithPointer: (void *)pointer
			      object: (id)object;

- init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated memory not part of object exception.
 *
 * @param pointer A pointer to the memory that is not part of the object
 * @param object The object which the memory is not part of
 * @return An initialized memory not part of object exception
 */
- initWithPointer: (void *)pointer
	   object: (id)object OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
