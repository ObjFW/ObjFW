/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

/** @file */

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block for enumerating an OFCountedSet.
 *
 * @param object The current object
 * @param count The count of the object
 * @param stop A pointer to a variable that can be set to true to stop the
 *	       enumeration
 */
typedef void (^OFCountedSetEnumerationBlock)(id object, size_t count,
    bool *stop);
#endif

/**
 * @class OFCountedSet OFCountedSet.h ObjFW/OFCountedSet.h
 *
 * @brief An abstract class for a mutable unordered set of objects, counting how
 *	  often it contains an object.
 *
 * @note Subclasses must implement @ref countForObject: as well as all methods
 *	 of @ref OFSet and @ref OFMutableSet that need to be implemented.
 */
@interface OFCountedSet OF_GENERIC(ObjectType):
    OFMutableSet OF_GENERIC(ObjectType)
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define ObjectType id
#endif
/**
 * @brief Returns how often the object is in the set.
 *
 * @return How often the object is in the set
 */
- (size_t)countForObject: (ObjectType)object;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Executes a block for each object in the set.
 *
 * @param block The block to execute for each object in the set
 */
- (void)enumerateObjectsAndCountUsingBlock: (OFCountedSetEnumerationBlock)block;
#endif
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END
