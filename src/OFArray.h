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

#include <stdarg.h>

#import "OFObject.h"
#import "OFDataArray.h"

/**
 * The OFArray class provides a class for storing objects in an array.
 */
@interface OFArray: OFObject <OFCopying, OFMutableCopying>
{
	OFDataArray *array;
}

/**
 * \return A new autoreleased OFArray
 */
+ array;

/**
 * \param obj An object
 * \return A new autoreleased OFArray
 */
+ arrayWithObject: (OFObject*)obj;

/**
 * \param first The first object in the array
 * \return A new autoreleased OFArray
 */
+ arrayWithObjects: (OFObject*)first, ...;

/**
 * \param objs A C array of objects.
 * \return A new autoreleased OFArray
 */
+ arrayWithCArray: (OFObject**)objs;

/**
 * Initializes an OFArray with the specified object.
 *
 * \param obj An object
 * \return An initialized OFArray
 */
- initWithObject: (OFObject*)obj;

/**
 * Initializes an OFArray with the specified objects.
 *
 * \param obj The first object
 * \return An initialized OFArray
 */
- initWithObjects: (OFObject*)first, ...;

/**
 * Initializes an OFArray with the specified object and a va_list.
 *
 * \param first The first object
 * \param args A va_list
 * \return An initialized OFArray
 */
- initWithObject: (OFObject*)first
      andArgList: (va_list)args;

/**
 * Initializes an OFArray with the objects from the specified C array.
 *
 * \param objs A C array of objects
 * \return An initialized OFArray
 */
- initWithCArray: (OFObject**)objs;

/**
 * \return The number of objects in the OFArray
 */
- (size_t)count;

/**
 * \return The objects of the array as a C array
 */
- (id*)data;

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

#import "OFMutableArray.h"
