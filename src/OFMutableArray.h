/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFArray.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block for replacing values in an OFMutableArray.
 *
 * @param object The object to replace
 * @param index The index of the object to replace
 * @return The object to replace the object with
 */
typedef id _Nonnull (^of_array_replace_block_t)(id object, size_t index);
#endif

/*!
 * @class OFMutableArray OFArray.h ObjFW/OFArray.h
 *
 * @brief An abstract class for storing, adding and removing objects in an
 *	  array.
 *
 * @note Subclasses must implement @ref insertObject:atIndex:,
 *	 @ref replaceObjectAtIndex:withObject:, @ref removeObjectAtIndex: as
 *	 well as all methods of @ref OFArray that need to be implemented.
 */
@interface OFMutableArray OF_GENERIC(ObjectType): OFArray OF_GENERIC(ObjectType)
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define ObjectType id
#endif
/*!
 * @brief Creates a new OFMutableArray with enough memory to hold the specified
 *	  number of objects.
 *
 * @param capacity The initial capacity for the OFMutableArray
 * @return A new autoreleased OFMutableArray
 */
+ (instancetype)arrayWithCapacity: (size_t)capacity;

/*!
 * @brief Initializes an already allocated OFMutableArray with enough memory to
 *	  hold the specified number of objects.
 *
 * @param capacity The initial capacity for the OFMutableArray
 * @return An initialized OFMutableArray
 */
- (instancetype)initWithCapacity: (size_t)capacity;

/*!
 * @brief Adds an object to the end of the array.
 *
 * @param object An object to add
 */
- (void)addObject: (ObjectType)object;

/*!
 * @brief Adds the objects from the specified OFArray to the end of the array.
 *
 * @param array An array of objects to add
 */
- (void)addObjectsFromArray: (OFArray OF_GENERIC(ObjectType) *)array;

/*!
 * @brief Inserts an object to the OFArray at the specified index.
 *
 * @param object An object to add
 * @param index The index where the object should be inserted
 */
- (void)insertObject: (ObjectType)object
	     atIndex: (size_t)index;

/*!
 * @brief Inserts the objects from the specified OFArray at the specified index.
 *
 * @param array An array of objects
 * @param index The index where the objects should be inserted
 */
- (void)insertObjectsFromArray: (OFArray OF_GENERIC(ObjectType) *)array
		       atIndex: (size_t)index;

/*!
 * @brief Replaces the first object equivalent to the specified object with the
 *	  other specified object.
 *
 * @param oldObject The object to replace
 * @param newObject The replacement object
 */
- (void)replaceObject: (ObjectType)oldObject
	   withObject: (ObjectType)newObject;

/*!
 * @brief Replaces the object at the specified index with the specified object.
 *
 * @param index The index of the object to replace
 * @param object The replacement object
 */
- (void)replaceObjectAtIndex: (size_t)index
		  withObject: (ObjectType)object;

/*!
 * @brief Replaces the object at the specified index with the specified object.
 *
 * This method is the same as @ref replaceObjectAtIndex:withObject:.
 *
 * This method is also used by the subscripting syntax.
 *
 * @param index The index of the object to replace
 * @param object The replacement object
 */
-    (void)setObject: (ObjectType)object
  atIndexedSubscript: (size_t)index;

/*!
 * @brief Replaces the first object that has the same address as the specified
 *	  object with the other specified object.
 *
 * @param oldObject The object to replace
 * @param newObject The replacement object
 */
- (void)replaceObjectIdenticalTo: (ObjectType)oldObject
		      withObject: (ObjectType)newObject;

/*!
 * @brief Removes the first object equivalent to the specified object.
 *
 * @param object The object to remove
 */
- (void)removeObject: (ObjectType)object;

/*!
 * @brief Removes the first object that has the same address as the specified
 *	  object.
 *
 * @param object The object to remove
 */
- (void)removeObjectIdenticalTo: (ObjectType)object;

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
 * @brief Sorts the array in ascending order.
 */
- (void)sort;

/*!
 * @brief Sorts the array using the specified selector and options.
 *
 * @param selector The selector to use to sort the array. It's signature
 *		   should be the same as that of @ref OFComparing#compare:.
 * @param options The options to use when sorting the array.@n
 *		  Possible values are:
 *		  Value                      | Description
 *		  ---------------------------|-------------------------
 *		  `OF_ARRAY_SORT_DESCENDING` | Sort in descending order
 */
- (void)sortUsingSelector: (SEL)selector
		  options: (int)options;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Sorts the array using the specified comparator and options.
 *
 * @param comparator The comparator to use to sort the array
 * @param options The options to use when sorting the array.@n
 *		  Possible values are:
 *		  Value                      | Description
 *		  ---------------------------|-------------------------
 *		  `OF_ARRAY_SORT_DESCENDING` | Sort in descending order
 */
- (void)sortUsingComparator: (of_comparator_t)comparator
		    options: (int)options;
#endif

/*!
 * @brief Reverts the order of the objects in the array.
 */
- (void)reverse;

/*!
 * @brief Converts the mutable array to an immutable array.
 */
- (void)makeImmutable;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END
