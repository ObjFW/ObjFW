/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "OFArray.h"

#ifdef OF_HAVE_BLOCKS
typedef id (^of_array_replace_block_t)(id obj, size_t idx, BOOL *stop);
#endif

/*!
 * @brief An abstract class for storing, adding and removing objects in an
 *	  array.
 */
@interface OFMutableArray: OFArray
/*!
 * @brief Adds an object to the end of the array.
 *
 * @param object An object to add
 */
- (void)addObject: (id)object;

/*!
 * @brief Adds the objects from the specified OFArray to the end of the array.
 *
 * @brief array An array of objects to add
 */
- (void)addObjectsFromArray: (OFArray*)array;

/*!
 * @brief Inserts an object to the OFArray at the specified index.
 *
 * @param object An object to add
 * @param index The index where the object should be inserted
 */
- (void)insertObject: (id)object
	     atIndex: (size_t)index;

/*!
 * @brief Inserts the objects from the specified OFArray at the specified index.
 *
 * @param array An array of objects
 * @param index The index where the objects should be inserted
 */
- (void)insertObjectsFromArray: (OFArray*)array
		       atIndex: (size_t)index;

/*!
 * @brief Replaces the first object equivalent to the specified object with the
 *	  other specified object.
 *
 * @param oldObject The object to replace
 * @param newObject The replacement object
 */
- (void)replaceObject: (id)oldObject
	   withObject: (id)newObject;

/*!
 * @brief Replaces the object at the specified index with the specified object.
 *
 * @param index The index of the object to replace
 * @param object The replacement object
 */
- (void)replaceObjectAtIndex: (size_t)index
		  withObject: (id)object;
-    (void)setObject: (id)object
  atIndexedSubscript: (size_t)index;

/*!
 * @brief Replaces the first object that has the same address as the specified
 *	  object with the other specified object.
 *
 * @param oldObject The object to replace
 * @param newObject The replacement object
 */
- (void)replaceObjectIdenticalTo: (id)oldObject
		      withObject: (id)newObject;

/*!
 * @brief Removes the first object equivalent to the specified object.
 *
 * @param object The object to remove
 */
- (void)removeObject: (id)object;

/*!
 * @brief Removes the first object that has the same address as the specified
 *	  object.
 *
 * @param object The object to remove
 */
- (void)removeObjectIdenticalTo: (id)object;

/*!
 * @brief Removes the object at the specified index.
 *
 * @param index The index of the object to remove
 */
- (void)removeObjectAtIndex: (size_t)index;

/*!
 * @brief Removes the object in the specified range.
 *
 * @param range The range of the objects to remove
 */
- (void)removeObjectsInRange: (of_range_t)range;

/*!
 * @brief Removes the last object.
 */
- (void)removeLastObject;

/*!
 * @brief Removes all objects.
 */
- (void)removeAllObjects;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Replaces each object with the object returned by the block.
 *
 * @param block The block which returns a new object for each object
 */
- (void)replaceObjectsUsingBlock: (of_array_replace_block_t)block;
#endif

/*!
 * @brief Exchange the objects at the specified indices.
 *
 * @param index1 The index of the first object to exchange
 * @param index2 The index of the second object to exchange
 */
- (void)exchangeObjectAtIndex: (size_t)index1
	    withObjectAtIndex: (size_t)index2;

/*!
 * @brief Sorts the array.
 */
- (void)sort;

/*!
 * @brief Sorts the array.
 *
 * @param options The options to use when sorting the array.@n
 *		  Possible values are:
 *		  Value                      | Description
 *		  ---------------------------|-------------------------
 *		  OF_SORT_OPTIONS_DESCENDING | Sort in descending order
 */
- (void)sortWithOptions: (int)options;

/*!
 * @brief Reverts the order of the objects in the array.
 */
- (void)reverse;

/*!
 * @brief Converts the mutable array to an immutable array.
 */
- (void)makeImmutable;
@end
