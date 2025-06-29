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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFMutableData;

/**
 * @brief A class storing a set of indexes as sorted ranges.
 */
@interface OFIndexSet: OFObject
{
	OFMutableData *_ranges;
	size_t _count;
	OF_RESERVE_IVARS(OFIndexSet, 4)
}

/**
 * @brief The number of indexes in the set.
 */
@property (readonly, nonatomic) size_t count;

/**
 * @brief Creates an empty index set.
 *
 * @return An empty index set
 */
+ (instancetype)indexSet;

/**
 * @brief Creates an index set only containing the specified index.
 *
 * @param index The index the index set should contain
 * @return An index set only containing the specified index
 */
+ (instancetype)indexSetWithIndex: (size_t)index;

/**
 * @brief Creates an index set containing the indexes in the specified range.
 *
 * @param range The range of indexes the index set should contain
 * @return An index set containing the indexes in the specified range
 */
+ (instancetype)indexSetWithIndexesInRange: (OFRange)range;

/**
 * @brief Initializes an empty index set.
 *
 * @return An initialized empty index set
 */
- (instancetype)init;

/**
 * @brief Initializes an index set to only contain the specified index.
 *
 * @param index The index the index set should contain
 * @return An initialized index set only containing the specified index
 */
- (instancetype)initWithIndex: (size_t)index;

/**
 * @brief Initializes an index set to contain the indexes in the specified
 *	  range.
 *
 * @param range The range of indexes the index set should contain
 * @return An initialized index set containing the indexes in the specified
 *	   range
 */
- (instancetype)initWithIndexesInRange: (OFRange)range;

/**
 * @brief Returns whether the specified index is in the index set.
 *
 * @param index The index to check the index set for
 * @return Whether the specified index is in the index set
 */
- (bool)containsIndex: (size_t)index;

/**
 * @brief Returns whether the specified range of indexes is in the index set.
 *
 * @param range The range of indexes to check the index set for
 * @return Whether the specified range of indexes is in the index set
 */
- (bool)containsIndexesInRange: (OFRange)range;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableIndexSet.h"
