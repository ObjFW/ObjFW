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
@end
