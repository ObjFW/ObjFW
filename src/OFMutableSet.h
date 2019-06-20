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

#import "OFSet.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFMutableSet OFSet.h ObjFW/OFSet.h
 *
 * @brief An abstract class for a mutable unordered set of unique objects.
 *
 * @note Subclasses must implement @ref addObject:, @ref removeObject: as well
 *	 as all methods of @ref OFSet that need to be implemented.
 */
@interface OFMutableSet OF_GENERIC(ObjectType): OFSet OF_GENERIC(ObjectType)
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define ObjectType id
#endif
/*!
 * @brief Creates a new OFMutableSet with enough memory to hold the specified
 *	  number of objects.
 *
 * @param capacity The initial capacity for the OFMutableSet
 * @return A new autoreleased OFMutableSet
 */
+ (instancetype)setWithCapacity: (size_t)capacity;

/*!
 * @brief Initializes an already allocated OFMutableSet with enough memory to
 *	  hold the specified number of objects.
 *
 * @param capacity The initial capacity for the OFMutableSet
 * @return An initialized OFMutableSet
 */
- (instancetype)initWithCapacity: (size_t)capacity;

/*!
 * @brief Adds the specified object to the set.
 *
 * @param object The object to add to the set
 */
- (void)addObject: (ObjectType)object;

/*!
 * @brief Removes the specified object from the set.
 *
 * @param object The object to remove from the set
 */
- (void)removeObject: (ObjectType)object;

/*!
 * @brief Removes all objects from the receiver which are in the specified set.
 *
 * @param set The set whose objects will be removed from the receiver
 */
- (void)minusSet: (OFSet OF_GENERIC(ObjectType) *)set;

/*!
 * @brief Removes all objects from the receiver which are not in the specified
 *	  set.
 *
 * @param set The set to intersect with
 */
- (void)intersectSet: (OFSet OF_GENERIC(ObjectType) *)set;

/*!
 * @brief Creates a union of the receiver and the specified set.
 *
 * @param set The set to create the union with
 */
- (void)unionSet: (OFSet OF_GENERIC(ObjectType) *)set;

/*!
 * @brief Removes all objects from the set.
 */
- (void)removeAllObjects;

/*!
 * @brief Converts the mutable set to an immutable set.
 */
- (void)makeImmutable;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END
