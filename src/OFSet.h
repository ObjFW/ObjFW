/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <stdarg.h>

#import "OFObject.h"
#import "OFCollection.h"
#import "OFSerialization.h"

/*! @file */

@class OFArray;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block for enumerating an OFSet.
 *
 * @param object The current object
 * @param stop A pointer to a variable that can be set to true to stop the
 *             enumeration
 */
typedef void (^of_set_enumeration_block_t)(id object, bool *stop);

/*!
 * @brief A block for filtering an OFSet.
 *
 * @param object The object to inspect
 * @return Whether the object should be in the filtered set
 */
typedef bool (^of_set_filter_block_t)(id object);
#endif

/*!
 * @class OFSet OFSet.h ObjFW/OFSet.h
 *
 * @brief An abstract class for an unordered set of unique objects.
 *
 * @warning Do not mutate objects that are in a set! Changing the hash of
 *	    objects in a set breaks the internal representation of the set!
 */
@interface OFSet: OFObject <OFCollection, OFCopying, OFMutableCopying,
    OFSerialization>
/*!
 * @brief Creates a new set.
 *
 * @return A new, autoreleased set
 */
+ (instancetype)set;

/*!
 * @brief Creates a new set with the specified set.
 *
 * @param set The set to initialize the set with
 * @return A new, autoreleased set with the specified set
 */
+ (instancetype)setWithSet: (OFSet*)set;

/*!
 * @brief Creates a new set with the specified array.
 *
 * @param array The array to initialize the set with
 * @return A new, autoreleased set with the specified array
 */
+ (instancetype)setWithArray: (OFArray*)array;

/*!
 * @brief Creates a new set with the specified objects.
 *
 * @param firstObject The first object for the set
 * @return A new, autoreleased set with the specified objects
 */
+ (instancetype)setWithObjects: (id)firstObject, ...;

/*!
 * @brief Creates a new set with the specified objects.
 *
 * @param objects An array of objects for the set
 * @param count The number of objects in the specified array
 * @return A new, autoreleased set with the specified objects
 */
+ (instancetype)setWithObjects: (id const*)objects
			 count: (size_t)count;

/*!
 * @brief Initializes an already allocated set with the specified set.
 *
 * @param set The set to initialize the set with
 * @return An initialized set with the specified set
 */
- initWithSet: (OFSet*)set;

/*!
 * @brief Initializes an already allocated set with the specified array.
 *
 * @param array The array to initialize the set with
 * @return An initialized set with the specified array
 */
- initWithArray: (OFArray*)array;

/*!
 * @brief Initializes an already allocated set with the specified objects.
 *
 * @param firstObject The first object for the set
 * @return An initialized set with the specified objects
 */
- initWithObjects: (id)firstObject, ...;

/*!
 * @brief Initializes an already allocated set with the specified objects.
 *
 * @param objects An array of objects for the set
 * @param count The number of objects in the specified array
 * @return An initialized set with the specified objects
 */
- initWithObjects: (id const*)objects
	    count: (size_t)count;

/*!
 * @brief Initializes an already allocated set with the specified object and
 *	  va_list.
 *
 * @param firstObject The first object for the set
 * @param arguments A va_list with the other objects
 * @return An initialized set with the specified object and va_list
 */
- initWithObject: (id)firstObject
       arguments: (va_list)arguments;

/*!
 * @brief Returns whether the receiver is a subset of the specified set.
 *
 * @return Whether the receiver is a subset of the specified set
 */
- (bool)isSubsetOfSet: (OFSet*)set;

/*!
 * @brief Returns whether the receiver and the specified set have at least one
 *	  object in common.
 *
 * @return Whether the receiver and the specified set have at least one object
 *	   in common
 */
- (bool)intersectsSet: (OFSet*)set;

/*!
 * @brief Creates a new set which contains the objects which are in the
 *	  receiver, but not in the specified set.
 *
 * @param set The set whose objects will not be in the new set
 */
- (OFSet*)setBySubtractingSet: (OFSet*)set;

/*!
 * @brief Creates a new set by creating the intersection of the receiver and
 *	  the specified set.
 *
 * @param set The set to intersect with
 */
- (OFSet*)setByIntersectingWithSet: (OFSet*)set;

/*!
 * @brief Creates a new set by creating the union of the receiver and the
 *	  specified set.
 *
 * @param set The set to create the union with
 */
- (OFSet*)setByAddingSet: (OFSet*)set;

/*!
 * @brief Returns an array of all objects in the set.
 *
 * @return An array of all objects in the set
 */
- (OFArray*)allObjects;

/*!
 * @brief Returns an arbitrary object in the set.
 *
 * @return An arbitrary object in the set
 */
- (id)anyObject;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Executes a block for each object in the set.
 *
 * @param block The block to execute for each object in the set
 */
- (void)enumerateObjectsUsingBlock: (of_set_enumeration_block_t)block;

/*!
 * @brief Creates a new set, only containing the objects for which the block
 *	  returns true.
 *
 * @param block A block which determines if the object should be in the new set
 * @return A new, autoreleased OFSet
 */
- (OFSet*)filteredSetUsingBlock: (of_set_filter_block_t)block;
#endif
@end

#import "OFMutableSet.h"
