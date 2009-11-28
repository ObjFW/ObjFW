/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
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
	 argList: (va_list)args;

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
- (id*)cArray;

/**
 * Returns a specific object of the OFArray.
 *
 * \param index The number of the object to return
 * \return The specified object of the OFArray
 */
- (id)objectAtIndex: (size_t)index;

/**
 * Returns the index of the first object that is equivalent to the specified
 * object.
 *
 * \param obj The object whose index is returned
 * \return The index of the first object equivalent to the specified object
 */
- (size_t)indexOfObject: (id)obj;

/**
 * Returns the index of the first object that has the same address as the
 * specified object.
 *
 * \param obj The object whose index is returned
 * \return The index of the first object that has the same aaddress as
 *	   the specified object
 */
- (size_t)indexOfObjectIdenticalTo: (id)obj;

/**
 * \return The first object of the OFArray or nil
 */
- (id)firstObject;

/**
 * \return The last object of the OFArray or nil
 */
- (id)lastObject;

- addObject: (OFObject*)obj;
- removeObject: (id)obj;
- removeObjectIdenticalTo: (id)obj;
- removeObjectAtIndex: (size_t)index;
- removeNObjects: (size_t)nobjects;
- removeNObjects: (size_t)nobjects
	 atIndex: (size_t)index;
@end

#import "OFMutableArray.h"
