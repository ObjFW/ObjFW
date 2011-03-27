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

@class OFDataArray;
@class OFString;

#ifdef OF_HAVE_BLOCKS
typedef void (^of_array_enumeration_block_t)(id obj, size_t idx, BOOL *stop);
typedef BOOL (^of_array_filter_block_t)(id odj, size_t idx);
typedef id (^of_array_map_block_t)(id obj, size_t idx);
#endif

/**
 * \brief A class for storing objects in an array.
 */
@interface OFArray: OFObject <OFCopying, OFMutableCopying, OFCollection,
    OFFastEnumeration>
{
	OFDataArray *array;
}

/**
 * \return A new autoreleased OFArray
 */
+ array;

/**
 * Creates a new OFArray with the specified object.
 *
 * \param obj An object
 * \return A new autoreleased OFArray
 */
+ arrayWithObject: (id)obj;

/**
 * Creates a new OFArray with the specified objects, terminated by nil.
 *
 * \param first The first object in the array
 * \return A new autoreleased OFArray
 */
+ arrayWithObjects: (id)first, ...;

/**
 * Creates a new OFArray with the objects from the specified C array.
 *
 * \param objs A C array of objects, terminated with nil
 * \return A new autoreleased OFArray
 */
+ arrayWithCArray: (id*)objs;

/**
 * Creates a new OFArray with the objects from the specified C array of the
 * specified length.
 *
 * \param objs A C array of objects
 * \param len The length of the C array
 * \return A new autoreleased OFArray
 */
+ arrayWithCArray: (id*)objs
	   length: (size_t)len;

/**
 * Initializes an OFArray with the specified object.
 *
 * \param obj An object
 * \return An initialized OFArray
 */
- initWithObject: (id)obj;

/**
 * Initializes an OFArray with the specified objects.
 *
 * \param first The first object
 * \return An initialized OFArray
 */
- initWithObjects: (id)first, ...;

/**
 * Initializes an OFArray with the specified object and a va_list.
 *
 * \param first The first object
 * \param args A va_list
 * \return An initialized OFArray
 */
- initWithObject: (id)first
	 argList: (va_list)args;

/**
 * Initializes an OFArray with the objects from the specified C array.
 *
 * \param objs A C array of objects, terminated with nil
 * \return An initialized OFArray
 */
- initWithCArray: (id*)objs;

/**
 * Initializes an OFArray with the objects from the specified C array of the
 * specified length.
 *
 * \param objs A C array of objects
 * \param len The length of the C array
 * \return An initialized OFArray
 */
- initWithCArray: (id*)objs
	  length: (size_t)len;

/**
 * \return The objects of the array as a C array
 */
- (id*)cArray;

/**
 * Returns a specific object of the array.
 *
 * The returned object is <i>not</i> retained and autoreleased for performance
 * reasons!
 *
 * \param index The number of the object to return
 * \return The specified object of the OFArray
 */
- (id)objectAtIndex: (size_t)index;

/**
 * Returns the index of the first object that is equivalent to the specified
 * object or OF_INVALID_INDEX if it was not found.
 *
 * \param obj The object whose index is returned
 * \return The index of the first object equivalent to the specified object
 * 	   or OF_INVALID_INDEX if it was not found
 */
- (size_t)indexOfObject: (id)obj;

/**
 * Returns the index of the first object that has the same address as the
 * specified object or OF_INVALID_INDEX if it was not found.
 *
 * \param obj The object whose index is returned
 * \return The index of the first object that has the same aaddress as
 *	   the specified object or OF_INVALID_INDEX if it was not found
 */
- (size_t)indexOfObjectIdenticalTo: (id)obj;

/**
 * Returns the first object of the array or nil.
 *
 * The returned object is <i>not</i> retained and autoreleased for performance
 * reasons!
 *
 * \return The first object of the array or nil
 */
- (id)firstObject;

/**
 * Returns the last object of the array or nil.
 *
 * The returned object is <i>not</i> retained and autoreleased for performance
 * reasons!
 *
 * \return The last object of the array or nil
 */
- (id)lastObject;

/**
 * Returns the objects from the specified index to the specified index as a new
 * OFArray.
 *
 * \param start The index where the subarray starts
 * \param end The index where the subarray ends.
 *	      This points BEHIND the last object!
 * \return The subarray as a new autoreleased OFArray
 */
- (OFArray*)objectsFromIndex: (size_t)start
		     toIndex: (size_t)end;

/**
 * Returns the objects in the specified range as a new OFArray.
 * \param range The range for the subarray
 * \return The subarray as a new autoreleased OFArray
 */
- (OFArray*)objectsInRange: (of_range_t)range;

/**
 * Creates a string by joining all objects of the array.
 *
 * \param separator The string with which the objects should be joined
 * \return A string containing all objects joined by the separator
 */
- (OFString*)componentsJoinedByString: (OFString*)separator;

/**
 * Performs the specified selector on all objects in the array.
 *
 * \param selector The selector to perform on all objects in the array
 */
- (void)makeObjectsPerformSelector: (SEL)selector;

/**
 * Performs the specified selector on all objects in the array with the
 * specified object.
 *
 * \param selector The selector to perform on all objects in the array
 * \param obj The object to perform the selector with on all objects in the
 *	      array
 */
- (void)makeObjectsPerformSelector: (SEL)selector
			withObject: (id)obj;

#ifdef OF_HAVE_BLOCKS
/**
 * Executes a block for each object.
 *
 * \param block The block to execute for each object
 */
- (void)enumerateObjectsUsingBlock: (of_array_enumeration_block_t)block;

/**
 * Returns a new array, mapping each object using the specified block.
 *
 * \param block A block which maps an object for each object
 * \return A new, autoreleased OFArray
 */
- (OFArray*)mappedArrayUsingBlock: (of_array_map_block_t)block;

/**
 * Returns a new array, only containing the objects for which the block returns
 * YES.
 *
 * \param block A block which determines if the object should be in the new
 *		array
 * \return A new, autoreleased OFArray
 */
- (OFArray*)filteredArrayUsingBlock: (of_array_filter_block_t)block;
#endif
@end

@interface OFArrayEnumerator: OFEnumerator
{
	OFArray	      *array;
	OFDataArray   *dataArray;
	size_t	      count;
	unsigned long mutations;
	unsigned long *mutationsPtr;
	size_t	      pos;
}

-    initWithArray: (OFArray*)data
	 dataArray: (OFDataArray*)dataArray
  mutationsPointer: (unsigned long*)mutationsPtr;
@end

#import "OFMutableArray.h"
