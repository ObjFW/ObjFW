/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFSet.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableSet OFMutableSet.h ObjFW/ObjFW.h
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
/**
 * @brief Creates a new OFMutableSet with enough memory to hold the specified
 *	  number of objects.
 *
 * @param capacity The initial capacity for the OFMutableSet
 * @return A new autoreleased OFMutableSet
 */
+ (instancetype)setWithCapacity: (size_t)capacity;

/**
 * @brief Initializes an already allocated OFMutableSet to be empty.
 *
 * @return An initialized OFMutableSet
 */
- (instancetype)init OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated OFMutableSet with enough memory to
 *	  hold the specified number of objects.
 *
 * @param capacity The initial capacity for the OFMutableSet
 * @return An initialized OFMutableSet
 */
- (instancetype)initWithCapacity: (size_t)capacity OF_DESIGNATED_INITIALIZER;

/**
 * @brief Adds the specified object to the set.
 *
 * @param object The object to add to the set
 */
- (void)addObject: (ObjectType)object;

/**
 * @brief Removes the specified object from the set.
 *
 * @param object The object to remove from the set
 */
- (void)removeObject: (ObjectType)object;

/**
 * @brief Removes all objects from the receiver which are in the specified set.
 *
 * @param set The set whose objects will be removed from the receiver
 */
- (void)minusSet: (OFSet OF_GENERIC(ObjectType) *)set;

/**
 * @brief Removes all objects from the receiver which are not in the specified
 *	  set.
 *
 * @param set The set to intersect with
 */
- (void)intersectSet: (OFSet OF_GENERIC(ObjectType) *)set;

/**
 * @brief Creates a union of the receiver and the specified set.
 *
 * @param set The set to create the union with
 */
- (void)unionSet: (OFSet OF_GENERIC(ObjectType) *)set;

/**
 * @brief Removes all objects from the set.
 */
- (void)removeAllObjects;

/**
 * @brief Converts the mutable set to an immutable set.
 */
- (void)makeImmutable;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END
