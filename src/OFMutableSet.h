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

#import "OFSet.h"

/**
 * \brief An mutable unordered set of unique objects.
 */
@interface OFMutableSet: OFSet
/**
 * \brief Adds the specified object to the set.
 *
 * \param object The object to add to the set
 */
- (void)addObject: (id)object;

/**
 * \brief Removes the specified object from the set.
 *
 * \param object The object to remove from the set
 */
- (void)removeObject: (id)object;

/**
 * \brief Removes all objects from the receiver that are in the specified set.
 *
 * \param set The set whose objects will be removed from the receiver
 */
- (void)minusSet: (OFSet*)set;

/**
 * \brief Removes all objects from the receiver that are not in the specified
 *	  set.
 *
 * \param set The set to intersect
 */
- (void)intersectSet: (OFSet*)set;

/**
 * \brief Creates a union of the receiver and the specified set.
 *
 * \param set The set to create the union with
 */
- (void)unionSet: (OFSet*)set;

/**
 * \brief Converts the mutable set to an immutable set.
 */
- (void)makeImmutable;
@end

@interface OFMutableSet_placeholder: OFMutableSet
@end
