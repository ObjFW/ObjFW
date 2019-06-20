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

OF_ASSUME_NONNULL_BEGIN

/*! @file */

@class OFArray OF_GENERIC(ObjectType);

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
 *
 * @note Subclasses must implement @ref count, @ref containsObject: and
 *	 @ref objectEnumerator.
 */
@interface OFSet OF_GENERIC(ObjectType): OFObject <OFCollection, OFCopying,
    OFMutableCopying, OFSerialization>
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define ObjectType id
#endif
/*!
 * @brief An array of all objects in the set.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(ObjectType) *allObjects;

/*!
 * @brief An arbitrary object in the set.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) ObjectType anyObject;

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
+ (instancetype)setWithSet: (OFSet OF_GENERIC(ObjectType) *)set;

/*!
 * @brief Creates a new set with the specified array.
 *
 * @param array The array to initialize the set with
 * @return A new, autoreleased set with the specified array
 */
+ (instancetype)setWithArray: (OFArray OF_GENERIC(ObjectType) *)array;

/*!
 * @brief Creates a new set with the specified objects.
 *
 * @param firstObject The first object for the set
 * @return A new, autoreleased set with the specified objects
 */
+ (instancetype)setWithObjects: (ObjectType)firstObject, ...;

/*!
 * @brief Creates a new set with the specified objects.
 *
 * @param objects An array of objects for the set
 * @param count The number of objects in the specified array
 * @return A new, autoreleased set with the specified objects
 */
+ (instancetype)setWithObjects: (ObjectType const _Nonnull *_Nonnull)objects
			 count: (size_t)count;

/*!
 * @brief Initializes an already allocated set with the specified set.
 *
 * @param set The set to initialize the set with
 * @return An initialized set with the specified set
 */
- (instancetype)initWithSet: (OFSet OF_GENERIC(ObjectType) *)set;

/*!
 * @brief Initializes an already allocated set with the specified array.
 *
 * @param array The array to initialize the set with
 * @return An initialized set with the specified array
 */
- (instancetype)initWithArray: (OFArray OF_GENERIC(ObjectType) *)array;

/*!
 * @brief Initializes an already allocated set with the specified objects.
 *
 * @param firstObject The first object for the set
 * @return An initialized set with the specified objects
 */
- (instancetype)initWithObjects: (ObjectType)firstObject, ... OF_SENTINEL;

/*!
 * @brief Initializes an already allocated set with the specified objects.
 *
 * @param objects An array of objects for the set
 * @param count The number of objects in the specified array
 * @return An initialized set with the specified objects
 */
- (instancetype)initWithObjects: (ObjectType const _Nonnull *_Nonnull)objects
			  count: (size_t)count;

/*!
 * @brief Initializes an already allocated set with the specified object and
 *	  va_list.
 *
 * @param firstObject The first object for the set
 * @param arguments A va_list with the other objects
 * @return An initialized set with the specified object and va_list
 */
- (instancetype)initWithObject: (ObjectType)firstObject
		     arguments: (va_list)arguments;

/*!
 * @brief Returns whether the receiver is a subset of the specified set.
 *
 * @return Whether the receiver is a subset of the specified set
 */
- (bool)isSubsetOfSet: (OFSet OF_GENERIC(ObjectType) *)set;

/*!
 * @brief Returns whether the receiver and the specified set have at least one
 *	  object in common.
 *
 * @return Whether the receiver and the specified set have at least one object
 *	   in common
 */
- (bool)intersectsSet: (OFSet OF_GENERIC(ObjectType) *)set;

/*!
 * @brief Creates a new set which contains the objects which are in the
 *	  receiver, but not in the specified set.
 *
 * @param set The set whose objects will not be in the new set
 */
- (OFSet OF_GENERIC(ObjectType) *)setBySubtractingSet:
    (OFSet OF_GENERIC(ObjectType) *)set;

/*!
 * @brief Creates a new set by creating the intersection of the receiver and
 *	  the specified set.
 *
 * @param set The set to intersect with
 */
- (OFSet OF_GENERIC(ObjectType) *)setByIntersectingWithSet:
    (OFSet OF_GENERIC(ObjectType) *)set;

/*!
 * @brief Creates a new set by creating the union of the receiver and the
 *	  specified set.
 *
 * @param set The set to create the union with
 */
- (OFSet OF_GENERIC(ObjectType) *)setByAddingSet:
    (OFSet OF_GENERIC(ObjectType) *)set;

/*!
 * @brief Checks whether the set contains an object equal to the specified
 *	  object.
 *
 * @param object The object which is checked for being in the set
 * @return A boolean whether the set contains the specified object
 */
- (bool)containsObject: (ObjectType)object;

/*!
 * @brief Returns the value for the specified key
 *
 * A new set with the value for the specified key for each object is returned.
 *
 * The special key `@count` can be used to retrieve the count as an OFNumber.
 *
 * @note Unlike with @ref OFArray, any nil values are removed!
 *
 * @param key The key of the value to return
 * @return The value for the specified key
 */
- (nullable id)valueForKey: (OFString *)key;

/*!
 * @brief Set the value for the specified key
 *
 * @ref setValue:forKey: is called for each object.
 *
 * @note A @ref OFNull value is translated to nil!
 *
 * @param value The value for the specified key
 * @param key The key of the value to set
 */
- (void)setValue: (nullable id)value
	  forKey: (OFString *)key;

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
- (OFSet OF_GENERIC(ObjectType) *)filteredSetUsingBlock:
    (of_set_filter_block_t)block;
#endif
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END

#import "OFMutableSet.h"
