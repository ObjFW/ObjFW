/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"

/**
 * The OFArray class provides a class for storing dynamically sized arrays.
 * If you plan to store large hunks of data, you should consider using
 * OFBigArray, which allocates the memory in pages and not in bytes.
 */
@interface OFArray: OFObject
{
	char   *data;
	size_t itemsize;
	size_t items;
}

/**
 * Creates a new OFArray whose items all have the same size.
 *
 * \param is The size of each element in the OFArray
 * \return A new allocated and initialized OFArray
 */
+ newWithItemSize: (size_t)is;

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
 * \param item An arbitrary item
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
@end

/**
 * The OFBigArray class is nearly the same as the OFArray class, but it
 * allocates the memory rather in pages than in bytes.
 * This is faster, but needs more memory. It is especially useful if you want
 * to store large hunks of data.
 */
@interface OFBigArray: OFArray
{
	size_t size;
}

/**
 * Creates a new OFBigArray whose items all have the same size.
 *
 * \param is The size of each element in the OFBigArray
 * \return A new allocated and initialized OFBigArray
 */
+ newWithItemSize: (size_t)is;

/**
 * Initializes an already allocated OFBigArray whose items all have the same
 * size.
 * 
 * \param is The size of each element in the OFBigArray
 * \return An initialized OFBigArray
 */
- initWithItemSize: (size_t)is;

/**
 * Adds an item to the OFBigArray.
 *
 * \param item An arbitrary item
 */
- add: (void*)item;

/**
 * Adds items from a C array to the OFBigArray.
 *
 * \param nitems The number of items to add
 * \param carray A C array containing the items to add
 */
- addNItems: (size_t)nitems
 fromCArray: (void*)carray;

/**
 * Removes a specified amount of the last items from the OFBigArray.
 *
 * \param nitems The number of items to remove
 */
- removeNItems: (size_t)nitems;
@end
