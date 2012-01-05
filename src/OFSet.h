/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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
#import "OFSerialization.h"

@class OFArray;

#ifdef OF_HAVE_BLOCKS
typedef void (^of_set_enumeration_block_t)(id object, BOOL *stop);
typedef BOOL (^of_set_filter_block_t)(id object);
#endif

/**
 * \brief An abstract class for an unordered set of unique objects.
 */
@interface OFSet: OFObject <OFCollection, OFCopying, OFMutableCopying,
    OFSerialization>
/**
 * \brief Creates a new set.
 *
 * \return A new, autoreleased set
 */
+ set;

/**
 * \brief Creates a new set with the specified set.
 *
 * \param set The set to initialize the set with
 * \return A new, autoreleased set with the specified set
 */
+ setWithSet: (OFSet*)set;

/**
 * \brief Creates a new set with the specified array.
 *
 * \param array The array to initialize the set with
 * \return A new, autoreleased set with the specified array
 */
+ setWithArray: (OFArray*)array;

/**
 * \brief Creates a new set with the specified objects.
 *
 * \param firstObject The first object for the set
 * \return A new, autoreleased set with the specified objects
 */
+ setWithObjects: (id)firstObject, ...;

/**
 * \brief Initializes an already allocated set with the specified set.
 *
 * \param set The set to initialize the set with
 * \return An initialized set with the specified set
 */
- initWithSet: (OFSet*)set;

/**
 * \brief Initializes an already allocated set with the specified array.
 *
 * \param array The array to initialize the set with
 * \return An initialized set with the specified array
 */
- initWithArray: (OFArray*)array;

/**
 * \brief Initializes an already allocated set with the specified objects.
 *
 * \param firstObject The first object for the set
 * \return An initialized set with the specified objects
 */
- initWithObjects: (id)firstObject, ...;

/**
 * \brief Initializes an already allocated set with the specified object and
 *	  va_list.
 *
 * \param firstObject The first object for the set
 * \param arguments A va_list with the other objects
 * \return An initialized set with the specified object and va_list
 */
- initWithObject: (id)firstObject
       arguments: (va_list)arguments;

/**
 * \brief Returns whether the receiver is a subset of the specified set.
 *
 * \return Whether the receiver is a subset of the specified set
 */
- (BOOL)isSubsetOfSet: (OFSet*)set;

/**
 * \brief Returns whether the receiver and the specified set have at least one
 *	  object in common.
 *
 * \return Whether the receiver and the specified set have at least one object
 *	   in common
 */
- (BOOL)intersectsSet: (OFSet*)set;

#ifdef OF_HAVE_BLOCKS
/**
 * \brief Executes a block for each object in the set.
 *
 * \param block The block to execute for each object in the set
 */
- (void)enumerateObjectsUsingBlock: (of_set_enumeration_block_t)block;

/**
 * \brief Creates a new set, only containing the objects for which the block
 *	  returns YES.
 *
 * \param block A block which determines if the object should be in the new set
 * \return A new, autoreleased OFSet
 */
- (OFSet*)filteredSetUsingBlock: (of_set_filter_block_t)block;
#endif
@end

#import "OFMutableSet.h"
