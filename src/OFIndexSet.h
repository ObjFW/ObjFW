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
@interface OFIndexSet: OFObject <OFCopying, OFMutableCopying>
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
 * @brief The first index in the index set or @ref OFNotFound.
 */
@property (readonly, nonatomic) size_t firstIndex;

/**
 * @brief The last index in the index set or @ref OFNotFound.
 */
@property (readonly, nonatomic) size_t lastIndex;

/**
 * @brief Creates a new empty index set.
 *
 * @return A new empty index set
 */
+ (instancetype)indexSet;

/**
 * @brief Creates a new index set from the specified index set.
 *
 * @param indexSet The index set to create a new index set from
 * @return A new index set created from the specified index set
 */
+ (instancetype)indexSetWithIndexSet: (OFIndexSet *)indexSet;

/**
 * @brief Creates a new index set only containing the specified index.
 *
 * @param index The index the index set should contain
 * @return A new index set only containing the specified index
 */
+ (instancetype)indexSetWithIndex: (size_t)index;

/**
 * @brief Creates a new index set containing the indexes in the specified range.
 *
 * @param range The range of indexes the index set should contain
 * @return A new index set containing the indexes in the specified range
 */
+ (instancetype)indexSetWithIndexesInRange: (OFRange)range;

/**
 * @brief Initializes an empty index set.
 *
 * @return An initialized empty index set
 */
- (instancetype)init;

/**
 * @brief Initializes an index set from the specified index set.
 *
 * @param indexSet The index set to initialize the index set from
 * @return An index set initialized from the specified index set
 */
- (instancetype)initWithIndexSet: (OFIndexSet *)indexSet;

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

/**
 * @brief Returns the closest index greater than the specified index or
 *	  @ref OFNotFound.
 *
 * @param index The index for which to find an index that is greater
 * @return The closest index greater than the specified index or @ref OFNotFound
 */
- (size_t)indexGreaterThanIndex: (size_t)index;

/**
 * @brief Returns the closest index greater than or equal to the specified
 *	  index or @ref OFNotFound.
 *
 * @param index The index for which to find an index that is greater or equal
 * @return The closest index greater than or equal to the specified index or
 *	   @ref OFNotFound
 */
- (size_t)indexGreaterThanOrEqualToIndex: (size_t)index;

/**
 * @brief Returns the closest index less than the specified index or
 *	  @ref OFNotFound.
 *
 * @param index The index for which to find an index that is less
 * @return The closest index less than the specified index or @ref OFNotFound
 */
- (size_t)indexLessThanIndex: (size_t)index;

/**
 * @brief Returns the closest index less than or equal to the specified index
 *	  or @ref OFNotFound.
 *
 * @param index The index for which to find an index that is less or equal
 * @return The closest index less than or equal to the specified index or
 *	   @ref OFNotFound
 */
- (size_t)indexLessThanOrEqualToIndex: (size_t)index;

/**
 * @brief Copies the indexes in the specified range to the specified buffer.
 *
 * @param indexes A pointer to an array of indexes
 * @param maxCount The maximum number of indexes to copy
 * @param range The range the copied indexes should be in
 * @return The number of indexes copied
 */
- (size_t)getIndexes: (size_t *)indexes
	    maxCount: (size_t)maxCount
	inIndexRange: (nullable OFRange *)range;
@end

OF_ASSUME_NONNULL_END

#import "OFMutableIndexSet.h"
