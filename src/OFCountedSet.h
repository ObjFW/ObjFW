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

/*! @file */

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block for enumerating an OFCountedSet.
 *
 * @param object The current object
 * @param count The count of the object
 * @param stop A pointer to a variable that can be set to true to stop the
 *	       enumeration
 */
typedef void (^of_counted_set_enumeration_block_t)(id object, size_t count,
    bool *stop);
#endif

/*!
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
/*!
 * @brief Returns how often the object is in the set.
 *
 * @return How often the object is in the set
 */
- (size_t)countForObject: (ObjectType)object;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Executes a block for each object in the set.
 *
 * @param block The block to execute for each object in the set
 */
- (void)enumerateObjectsAndCountUsingBlock:
    (of_counted_set_enumeration_block_t)block;
#endif
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END
