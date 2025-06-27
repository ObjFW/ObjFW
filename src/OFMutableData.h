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

#import "OFData.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableData OFMutableData.h ObjFW/ObjFW.h
 *
 * @brief A class for storing and manipulating arbitrary data in an array.
 */
@interface OFMutableData: OFData
/**
 * @brief All items of the OFMutableData as a C array.
 *
 * @warning The pointer is only valid until the OFMutableData is changed!
 *
 * Modifying the returned array directly is allowed and will change the contents
 * of the data.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) void *mutableItems
    OF_RETURNS_INNER_POINTER;

/**
 * @brief The first item of the OFMutableData or `NULL`.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) void *mutableFirstItem
    OF_RETURNS_INNER_POINTER;

/**
 * @brief The last item of the OFMutableData or `NULL`.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) void *mutableLastItem
    OF_RETURNS_INNER_POINTER;

/**
 * @brief Creates a new OFMutableData with enough memory to hold the specified
 *	  number of items which all have an item size of 1.
 *
 * @param capacity The initial capacity for the OFMutableData
 * @return A new autoreleased OFMutableData
 */
+ (instancetype)dataWithCapacity: (size_t)capacity;

/**
 * @brief Creates a new OFMutableData with enough memory to hold the specified
 *	  number of items which all have the same specified size.
 *
 * @param itemSize The size of a single element in the OFMutableData
 * @param capacity The initial capacity for the OFMutableData
 * @return A new autoreleased OFMutableData
 */
+ (instancetype)dataWithItemSize: (size_t)itemSize capacity: (size_t)capacity;

/**
 * @brief Initializes an already allocated OFMutableData with enough memory to
 *	  hold the the specified number of items which all have an item size of
 *	  1.
 *
 * @param capacity The initial capacity for the OFMutableData
 * @return An initialized OFMutableData
 */
- (instancetype)initWithCapacity: (size_t)capacity;

/**
 * @brief Initializes an already allocated OFMutableData with enough memory to
 *	  hold the the specified number of items which all have the same
 *	  specified size.
 *
 * @param itemSize The size of a single element in the OFMutableData
 * @param capacity The initial capacity for the OFMutableData
 * @return An initialized OFMutableData
 */
- (instancetype)initWithItemSize: (size_t)itemSize capacity: (size_t)capacity;

/**
 * @brief Returns a specific item of the OFMutableData.
 *
 * Modifying the returned item directly is allowed and will change the contents
 * of the data.
 *
 * @param index The number of the item to return
 * @return The specified item of the OFMutableData
 */
- (void *)mutableItemAtIndex: (size_t)index OF_RETURNS_INNER_POINTER;

/**
 * @brief Adds an item to the OFMutableData.
 *
 * @param item A pointer to an arbitrary item
 */
- (void)addItem: (const void *)item;

/**
 * @brief Adds an item to the OFMutableData at the specified index.
 *
 * @param item A pointer to an arbitrary item
 * @param index The index where the item should be added
 */
- (void)insertItem: (const void *)item atIndex: (size_t)index;

/**
 * @brief Adds items from a C array to the OFMutableData.
 *
 * @param items A C array containing the items to add
 * @param count The number of items to add
 */
- (void)addItems: (const void *)items count: (size_t)count;

/**
 * @brief Adds items from a C array to the OFMutableData at the specified index.
 *
 * @param items A C array containing the items to add
 * @param index The index where the items should be added
 * @param count The number of items to add
 */
- (void)insertItems: (const void *)items
	    atIndex: (size_t)index
	      count: (size_t)count;

/**
 * @brief Increases the count by the specified number. The new items are all
 *	  filled with null bytes.
 *
 * @param count The count by which to increase the count
 */
- (void)increaseCountBy: (size_t)count;

/**
 * @brief Removes the item at the specified index.
 *
 * @param index The index of the item to remove
 */
- (void)removeItemAtIndex: (size_t)index;

/**
 * @brief Removes the specified amount of items at the specified index.
 *
 * @param range The range of items to remove
 */
- (void)removeItemsInRange: (OFRange)range;

/**
 * @brief Removes the last item.
 */
- (void)removeLastItem;

/**
 * @brief Removes all items.
 */
- (void)removeAllItems;

/**
 * @brief Converts the mutable data to an immutable data.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
