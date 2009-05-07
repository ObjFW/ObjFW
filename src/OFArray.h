/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"
#import "OFDataArray.h"

/**
 * The OFArray class provides a class for storing objects in an array.
 */
@interface OFArray: OFObject
{
	OFDataArray *array;
}

/**
 * \return A new autoreleased OFArray
 */
+ array;

/**
 * \return The number of objects in the OFArray
 */
- (size_t)count;

/**
 * \return The objects of the array as a C array
 */
- (id*)data;

/**
 * Clones the OFArray, creating a new one.
 *
 * \return A new autoreleased copy of the OFArray
 */
- (id)copy;

/**
 * Returns a specific object of the OFDataArray.
 *
 * \param index The number of the object to return
 * \return The specified object of the OFArray
 */
- (id)object: (size_t)index;

/**
 * \return The last object of the OFDataArray
 */
- (id)last;

/**
 * Adds an object to the OFDataArray.
 *
 * \param obj An object to add
 */
- add: (OFObject*)obj;

/**
 * Removes the specified amount of object from the end of the OFDataArray.
 *
 * \param nobjects The number of objects to remove
 */
- removeNObjects: (size_t)nobjects;
@end
