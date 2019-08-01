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

#import "OFData.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;
@class OFURL;

/*!
 * @class OFMutableData OFMutableData.h ObjFW/OFMutableData.h
 *
 * @brief A class for storing and manipulating arbitrary data in an array.
 */
@interface OFMutableData: OFData
{
	size_t _capacity;
}

/*!
 * @brief All items of the OFMutableData as a C array.
 *
 * @warning The pointer is only valid until the OFMutableData is changed!
 *
 * Modifying the returned array directly is allowed and will change the contents
 * of the data.
 */
@property (readonly, nonatomic) void *mutableItems OF_RETURNS_INNER_POINTER;

/*!
 * @brief The first item of the OFMutableData or `NULL`.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) void *mutableFirstItem
    OF_RETURNS_INNER_POINTER;

/*!
 * @brief The last item of the OFMutableData or `NULL`.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) void *mutableLastItem
    OF_RETURNS_INNER_POINTER;

/*!
 * @brief Creates a new OFMutableData with an item size of 1.
 *
 * @return A new autoreleased OFMutableData
 */
+ (instancetype)data;

/*!
 * @brief Creates a new OFMutableData whose items all have the same specified
 *	  size.
 *
 * @param itemSize The size of a single element in the OFMutableData
 * @return A new autoreleased OFMutableData
 */
+ (instancetype)dataWithItemSize: (size_t)itemSize;

/*!
 * @brief Creates a new OFMutableData with enough memory to hold the specified
 *	  number of items which all have an item size of 1.
 *
 * @param capacity The initial capacity for the OFMutableData
 * @return A new autoreleased OFMutableData
 */
+ (instancetype)dataWithCapacity: (size_t)capacity;

/*!
 * @brief Creates a new OFMutableData with enough memory to hold the specified
 *	  number of items which all have the same specified size.
 *
 * @param itemSize The size of a single element in the OFMutableData
 * @param capacity The initial capacity for the OFMutableData
 * @return A new autoreleased OFMutableData
 */
+ (instancetype)dataWithItemSize: (size_t)itemSize
			capacity: (size_t)capacity;

/*!
 * @brief Initializes an already allocated OFMutableData with an item size of 1.
 *
 * @return An initialized OFMutableData
 */
- (instancetype)init;

/*!
 * @brief Initializes an already allocated OFMutableData whose items all have
 *	  the same size.
 *
 * @param itemSize The size of a single element in the OFMutableData
 * @return An initialized OFMutableData
 */
- (instancetype)initWithItemSize: (size_t)itemSize;

/*!
 * @brief Initializes an already allocated OFMutableData with enough memory to
 *	  hold the the specified number of items which all have an item size of
 *	  1.
 *
 * @param capacity The initial capacity for the OFMutableData
 * @return An initialized OFMutableData
 */
- (instancetype)initWithCapacity: (size_t)capacity;

/*!
 * @brief Initializes an already allocated OFMutableData with enough memory to
 *	  hold the the specified number of items which all have the same
 *	  specified size.
 *
 * @param itemSize The size of a single element in the OFMutableData
 * @param capacity The initial capacity for the OFMutableData
 * @return An initialized OFMutableData
 */
- (instancetype)initWithItemSize: (size_t)itemSize
			capacity: (size_t)capacity;

/*!
 * @brief Returns a specific item of the OFMutableData.
 *
 * Modifying the returned item directly is allowed and will change the contents
 * of the data.
 *
 * @param index The number of the item to return
 * @return The specified item of the OFMutableData
 */
- (void *)mutableItemAtIndex: (size_t)index OF_RETURNS_INNER_POINTER;

/*!
 * @brief Adds an item to the OFMutableData.
 *
 * @param item A pointer to an arbitrary item
 */
- (void)addItem: (const void *)item;

/*!
 * @brief Adds an item to the OFMutableData at the specified index.
 *
 * @param item A pointer to an arbitrary item
 * @param index The index where the item should be added
 */
- (void)insertItem: (const void *)item
	   atIndex: (size_t)index;

/*!
 * @brief Adds items from a C array to the OFMutableData.
 *
 * @param items A C array containing the items to add
 * @param count The number of items to add
 */
- (void)addItems: (const void *)items
	   count: (size_t)count;

/*!
 * @brief Adds items from a C array to the OFMutableData at the specified index.
 *
 * @param items A C array containing the items to add
 * @param index The index where the items should be added
 * @param count The number of items to add
 */
- (void)insertItems: (const void *)items
	    atIndex: (size_t)index
	      count: (size_t)count;

/*!
 * @brief Increases the count by the specified number. The new items are all
 *	  filled with null bytes.
 *
 * @param count The count by which to increase the count
 */
- (void)increaseCountBy: (size_t)count;

/*!
 * @brief Removes the item at the specified index.
 *
 * @param index The index of the item to remove
 */
- (void)removeItemAtIndex: (size_t)index;

/*!
 * @brief Removes the specified amount of items at the specified index.
 *
 * @param range The range of items to remove
 */
- (void)removeItemsInRange: (of_range_t)range;

/*!
 * @brief Removes the last item.
 */
- (void)removeLastItem;

/*!
 * @brief Removes all items.
 */
- (void)removeAllItems;

/*!
 * @brief Converts the mutable URL to an immutable URL.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
