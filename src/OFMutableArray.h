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

#import "OFArray.h"

/**
 * The OFMutableArray class provides a class for storing, adding and removing
 * objects in an array.
 */
@interface OFMutableArray: OFArray {}
/**
 * Adds an object to the OFArray.
 *
 * \param obj An object to add
 */
- addObject: (OFObject*)obj;

/**
 * Adds an object to the OFArray at the specified index.
 *
 * \param obj An object to add
 * \param index The index where the object should be added
 */
- addObject: (OFObject*)obj
    atIndex: (size_t)index;

/**
 * Removes the first object equivalent to the specified object.
 *
 * \param obj The object to remove
 */
- removeObject: (OFObject*)obj;

/**
 * Removes the first object that has the same address as the specified object.
 *
 * \param obj The object to remove
 */
- removeObjectIdenticalTo: (OFObject*)obj;

/**
 * Removes the object at the specified index.
 *
 * \param index The index of the object to remove
 */
- removeObjectAtIndex: (size_t)index;

/**
 * Removes the specified amount of objects from the end of the OFArray.
 *
 * \param nobjects The number of objects to remove
 */
- removeNObjects: (size_t)nobjects;

/**
 * Removes the specified amount of objects at the specified index.
 *
 * \param nobjects The number of objects to remove
 * \param index The index at which the objects are removed
 */
- removeNObjects: (size_t)nitems
	 atIndex: (size_t)index;
@end
