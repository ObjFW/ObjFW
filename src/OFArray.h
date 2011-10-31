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

#include <stdarg.h>

#import "OFObject.h"
#import "OFCollection.h"
#import "OFEnumerator.h"
#import "OFSerialization.h"

@class OFString;

#ifdef OF_HAVE_BLOCKS
typedef void (^of_array_enumeration_block_t)(id object, size_t index,
    BOOL *stop);
typedef BOOL (^of_array_filter_block_t)(id odject, size_t index);
typedef id (^of_array_map_block_t)(id object, size_t index);
typedef id (^of_array_fold_block_t)(id left, id right);
#endif

/**
 * \brief An abstract class for storing objects in an array.
 */
@interface OFArray: OFObject <OFCopying, OFMutableCopying, OFCollection,
    OFSerialization>
/**
 * \brief Creates a new OFArray.
 *
 * \return A new autoreleased OFArray
 */
+ array;

/**
 * \brief Creates a new OFArray with the specified object.
 *
 * \param object An object
 * \return A new autoreleased OFArray
 */
+ arrayWithObject: (id)object;

/**
 * \brief Creates a new OFArray with the specified objects, terminated by nil.
 *
 * \param firstObject The first object in the array
 * \return A new autoreleased OFArray
 */
+ arrayWithObjects: (id)firstObject, ...;

/**
 * \brief Creates a new OFArray with the objects from the specified array.
 *
 * \param array An array
 * \return A new autoreleased OFArray
 */
+ arrayWithArray: (OFArray*)array;

/**
 * \brief Creates a new OFArray with the objects from the specified C array.
 *
 * \param objects A C array of objects, terminated with nil
 * \return A new autoreleased OFArray
 */
+ arrayWithCArray: (id*)objects;

/**
 * \brief Creates a new OFArray with the objects from the specified C array of
 *	  the specified length.
 *
 * \param objects A C array of objects
 * \param length The length of the C array
 * \return A new autoreleased OFArray
 */
+ arrayWithCArray: (id*)objects
	   length: (size_t)length;

/**
 * \brief Initializes an OFArray with the specified object.
 *
 * \param object An object
 * \return An initialized OFArray
 */
- initWithObject: (id)object;

/**
 * \brief Initializes an OFArray with the specified objects.
 *
 * \param firstObject The first object
 * \return An initialized OFArray
 */
- initWithObjects: (id)firstObject, ...;

/**
 * \brief Initializes an OFArray with the specified object and a va_list.
 *
 * \param firstObject The first object
 * \param arguments A va_list
 * \return An initialized OFArray
 */
- initWithObject: (id)firstObject
       arguments: (va_list)arguments;

/**
 * \brief Initializes an OFArray with the objects from the specified array.
 *
 * \param array An array
 * \return An initialized OFArray
 */
- initWithArray: (OFArray*)array;

/**
 * \brief Initializes an OFArray with the objects from the specified C array.
 *
 * \param objects A C array of objects, terminated with nil
 * \return An initialized OFArray
 */
- initWithCArray: (id*)objects;

/**
 * \brief Initializes an OFArray with the objects from the specified C array of
 *	  the specified length.
 *
 * \param objects A C array of objects
 * \param length The length of the C array
 * \return An initialized OFArray
 */
- initWithCArray: (id*)objects
	  length: (size_t)length;

/**
 * \brief Returns a specified object of the array.
 *
 * The returned object is <i>not</i> retained and autoreleased for performance
 * reasons!
 *
 * \param index The number of the object to return
 * \return The specified object of the OFArray
 */
- (id)objectAtIndex: (size_t)index;

/**
 * \brief Copies the objects at the specified range to the specified buffer.
 *
 * \param buffer The buffer to copy the objects to
 * \param range The range to copy
 */
- (void)getObjects: (id*)buffer
	   inRange: (of_range_t)range;

/**
 * \brief Returns the objects of the array as a C array.
 *
 * \return The objects of the array as a C array
 */
- (id*)cArray;

/**
 * \brief Returns the index of the first object that is equivalent to the
 *	  specified object or OF_INVALID_INDEX if it was not found.
 *
 * \param object The object whose index is returned
 * \return The index of the first object equivalent to the specified object
 *	   or OF_INVALID_INDEX if it was not found
 */
- (size_t)indexOfObject: (id)object;

/**
 * \brief Returns the index of the first object that has the same address as the
 *	  specified object or OF_INVALID_INDEX if it was not found.
 *
 * \param object The object whose index is returned
 * \return The index of the first object that has the same aaddress as
 *	   the specified object or OF_INVALID_INDEX if it was not found
 */
- (size_t)indexOfObjectIdenticalTo: (id)object;

/**
 * \brief Checks whether the array contains an object with the specified
 *	  address.
 *
 * \param object The object which is checked for being in the array
 * \return A boolean whether the array contains an object with the specified
 *	   address.
 */
- (BOOL)containsObjectIdenticalTo: (id)object;

/**
 * \brief Returns the first object of the array or nil.
 *
 * The returned object is <i>not</i> retained and autoreleased for performance
 * reasons!
 *
 * \return The first object of the array or nil
 */
- (id)firstObject;

/**
 * \brief Returns the last object of the array or nil.
 *
 * The returned object is <i>not</i> retained and autoreleased for performance
 * reasons!
 *
 * \return The last object of the array or nil
 */
- (id)lastObject;

/**
 * \brief Returns the objects in the specified range as a new OFArray.
 *
 * \param range The range for the subarray
 * \return The subarray as a new autoreleased OFArray
 */
- (OFArray*)objectsInRange: (of_range_t)range;

/**
 * \brief Creates a string by joining all objects of the array.
 *
 * \param separator The string with which the objects should be joined
 * \return A string containing all objects joined by the separator
 */
- (OFString*)componentsJoinedByString: (OFString*)separator;

/**
 * \brief Performs the specified selector on all objects in the array.
 *
 * \param selector The selector to perform on all objects in the array
 */
- (void)makeObjectsPerformSelector: (SEL)selector;

/**
 * \brief Performs the specified selector on all objects in the array with the
 *	  specified object.
 *
 * \param selector The selector to perform on all objects in the array
 * \param object The object to perform the selector with on all objects in the
 *	      array
 */
- (void)makeObjectsPerformSelector: (SEL)selector
			withObject: (id)object;

#ifdef OF_HAVE_BLOCKS
/**
 * \brief Executes a block for each object.
 *
 * \param block The block to execute for each object
 */
- (void)enumerateObjectsUsingBlock: (of_array_enumeration_block_t)block;

/**
 * \brief Creates a new array, mapping each object using the specified block.
 *
 * \param block A block which maps an object for each object
 * \return A new, autoreleased OFArray
 */
- (OFArray*)mappedArrayUsingBlock: (of_array_map_block_t)block;

/**
 * \brief Creates a new array, only containing the objects for which the block
 *	  returns YES.
 *
 * \param block A block which determines if the object should be in the new
 *		array
 * \return A new, autoreleased OFArray
 */
- (OFArray*)filteredArrayUsingBlock: (of_array_filter_block_t)block;

/**
 * \brief Folds the array to a single object using the specified block.
 *
 * If the array is empty, it will return nil.
 *
 * If there is only one object in the array, that object will be returned and
 * the block will not be invoked.
 *
 * If there are at least two objects, the block is invoked for each object
 * except the first, where left is always to what the array has already been
 * folded and right what should be added to left.
 *
 * \param block A block which folds two objects into one, which is called for
 *		all objects except the first
 * \return The array folded to a single object
 */
- (id)foldUsingBlock: (of_array_fold_block_t)block;
#endif
@end

@interface OFArrayEnumerator: OFEnumerator
{
	OFArray	      *array;
	size_t	      count;
	unsigned long mutations;
	unsigned long *mutationsPtr;
	size_t	      position;
}

- initWithArray: (OFArray*)data
   mutationsPtr: (unsigned long*)mutationsPtr;
@end

#import "OFMutableArray.h"
