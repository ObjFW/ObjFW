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

#import "OFIndexSet.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A class storing and mutating a set of indexes as sorted ranges.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFMutableIndexSet: OFIndexSet
/**
 * @brief Adds the specified index to the index set.
 *
 * @param index The index to add
 */
- (void)addIndex: (size_t)index;

/**
 * @brief Adds the indexes in the specified range to the index set.
 *
 * @param range The range of indexes to add
 */
- (void)addIndexesInRange: (OFRange)range;

/**
 * @brief Adds the specified indexes to the index set.
 *
 * @param indexes The indexes to add
 */
- (void)addIndexes: (OFIndexSet *)indexes;

/**
 * @brief Removes the specified index from the index set.
 *
 * @param index The index to remove
 */
- (void)removeIndex: (size_t)index;

/**
 * @brief Removes the indexes in the specified range from the index set.
 *
 * @param range The range of indexes to remove
 */
- (void)removeIndexesInRange: (OFRange)range;

/**
 * @brief Removes the specified indexes from the index set.
 *
 * @param indexes The indexes to remove
 */
- (void)removeIndexes: (OFIndexSet *)indexes;

/**
 * @brief Removes all indexes from the index set.
 */
- (void)removeAllIndexes;
@end

OF_ASSUME_NONNULL_END
