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

#import "OFEnumerator.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @protocol OFCollection OFCollection.h ObjFW/ObjFW.h
 *
 * @brief A protocol with methods common for all collections.
 */
@protocol OFCollection <OFEnumeration, OFFastEnumeration>
/**
 * @brief The number of objects in the collection
 */
@property (readonly, nonatomic) size_t count;

/**
 * @brief Checks whether the collection contains an object equal to the
 *	  specified object.
 *
 * @param object The object which is checked for being in the collection
 * @return A boolean whether the collection contains the specified object
 */
- (bool)containsObject: (id)object;
@end

OF_ASSUME_NONNULL_END
