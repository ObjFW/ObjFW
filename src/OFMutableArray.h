/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFArray.h"

#ifdef OF_HAVE_BLOCKS
typedef id (^of_array_replace_block_t)(id obj, size_t idx, BOOL *stop);
#endif

/**
 * \brief A class for storing, adding and removing objects in an array.
 */
@interface OFMutableArray: OFArray
{
	unsigned long mutations;
}

/**
 * Adds an object to the OFArray.
 *
 * \param obj An object to add
 */
- (void)addObject: (id)obj;

/**
 * Adds an object to the OFArray at the specified index.
 *
 * \param obj An object to add
 * \param index The index where the object should be added
 */
- (void)addObject: (id)obj
	  atIndex: (size_t)index;

/**
 * Replaces all objects equivalent to the first specified object with the
 * second specified object.
 *
 * \param old The object to replace
 * \param new The replacement object
 */
- (void)replaceObject: (id)old
	   withObject: (id)new;

/**
 * Replaces the object at the specified index with the specified object.
 *
 * \param index The index of the object to replace
 * \param obj The replacement object
 * \return The old object, autoreleased
 */
- (id)replaceObjectAtIndex: (size_t)index
		withObject: (id)obj;

/**
 * Replaces all objects that have the same address as the first specified object
 * with the second specified object.
 *
 * \param old The object to replace
 * \param new The replacement object
 */
- (void)replaceObjectIdenticalTo: (id)old
		      withObject: (id)new;

/**
 * Removes all objects equivalent to the specified object.
 *
 * \param obj The object to remove
 */
- (void)removeObject: (id)obj;

/**
 * Removes all objects that have the same address as the specified object.
 *
 * \param obj The object to remove
 */
- (void)removeObjectIdenticalTo: (id)obj;

/**
 * Removes the object at the specified index.
 *
 * \param index The index of the object to remove
 * \return The object that was at the index, autoreleased
 */
- (id)removeObjectAtIndex: (size_t)index;

/**
 * Removes the specified amount of objects from the end of the OFArray.
 *
 * \param nobjects The number of objects to remove
 */
- (void)removeNObjects: (size_t)nobjects;

/**
 * Removes the specified amount of objects at the specified index.
 *
 * \param nobjects The number of objects to remove
 * \param index The index at which the objects are removed
 */
- (void)removeNObjects: (size_t)nobjects
	       atIndex: (size_t)index;

#ifdef OF_HAVE_BLOCKS
/**
 * Replaces each object with the object returned by the block.
 *
 * \param block The block which returns a new object for each object
 */
- (void)replaceObjectsUsingBlock: (of_array_replace_block_t)block;
#endif
@end
