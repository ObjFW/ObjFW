/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"
#import "OFComparable.h"

/**
 * The OFArray class provides a class for storing dynamically sized arrays.
 * If you plan to store large hunks of data, you should consider using
 * OFBigArray, which allocates the memory in pages and not in bytes.
 */
@interface OFArray: OFObject <OFComparable>
{
	char   *data;
	size_t itemsize;
	size_t items;
}

/**
 * Creates a new OFArray whose items all have the same size.
 *
 * \param is The size of each element in the OFArray
 * \return A new autoreleased OFArray
 */
+ arrayWithItemSize: (size_t)is;

/*
 * Creates a new OFArray optimized for big arrays whose items all have the same
 * size, which means memory is allocated in pages rather than in bytes.
 *
 * \param is The size of each element in the OFArray
 * \return A new autoreleased OFArray
 */
+ bigArrayWithItemSize: (size_t)is;

/**
 * Initializes an already allocated OFArray whose items all have the same size.
 *
 * \param is The size of each element in the OFArray
 * \return An initialized OFArray
 */
- initWithItemSize: (size_t)is;

/**
 * \return The number of items in the OFArray
 */
- (size_t)items;

/**
 * \return The size of each item in the OFArray in bytes
 */
- (size_t)itemsize;

/**
 * \return All elements of the OFArray
 */
- (void*)data;

/**
 * Returns a specific item of the OFArray.
 *
 * \param item The number of the item to return
 * \return The specified item of the OFArray
 */
- (void*)item: (size_t)item;

/**
 * \return The last item of the OFArray
 */
- (void*)last;

/**
 * Adds an item to the OFArray.
 *
 * \param item A pointer to an arbitrary item
 */
- add: (void*)item;

/**
 * Adds items from a C array to the OFArray.
 *
 * \param nitems The number of items to add
 * \param carray A C array containing the items to add
 */
- addNItems: (size_t)nitems
 fromCArray: (void*)carray;

/**
 * Removes a specified amount of the last items from the OFArray.
 *
 * \param nitems The number of items to remove
 */
- removeNItems: (size_t)nitems;

/**
 * Clones the OFArray, creating a new one.
 *
 * \return A new autoreleased copy of the OFArray
 */
- (id)copy;
@end

@interface OFBigArray: OFArray
{
	size_t size;
}

- initWithItemSize: (size_t)is;
- add: (void*)item;
- addNItems: (size_t)nitems
 fromCArray: (void*)carray;
- removeNItems: (size_t)nitems;
@end
