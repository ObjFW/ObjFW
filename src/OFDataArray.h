/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"

/**
 * The OFDataArray class provides a class for storing arbitrary data in an
 * array.
 *
 * If you plan to store large hunks of data, you should consider using
 * OFBigDataArray, which allocates the memory in pages rather than in bytes.
 */
@interface OFDataArray: OFObject <OFCopying>
{
	char   *data;
	size_t itemsize;
	size_t count;
}

/**
 * Creates a new OFDataArray whose items all have the same size.
 *
 * \param is The size of each element in the OFDataArray
 * \return A new autoreleased OFDataArray
 */
+ dataArrayWithItemSize: (size_t)is;

/**
 * Initializes an already allocated OFDataArray whose items all have the same
 * size.
 *
 * \param is The size of each element in the OFDataArray
 * \return An initialized OFDataArray
 */
- initWithItemSize: (size_t)is;

/**
 * \return The number of items in the OFDataArray
 */
- (size_t)count;

/**
 * \return The size of each item in the OFDataArray in bytes
 */
- (size_t)itemsize;

/**
 * \return All elements of the OFDataArray as a C array
 */
- (void*)cArray;

/**
 * Compares the OFDataArray to another object.
 *
 * \param ary A data array to compare with
 * \return An of_comparsion_result_t
 */
- (of_comparison_result_t)compare: (OFDataArray*)obj;

/**
 * Returns a specific item of the OFDataArray.
 *
 * \param index The number of the item to return
 * \return The specified item of the OFDataArray
 */
- (void*)itemAtIndex: (size_t)index;

/**
 * \return The last item of the OFDataArray
 */
- (void*)lastItem;

/**
 * Adds an item to the OFDataArray.
 *
 * \param item A pointer to an arbitrary item
 */
- addItem: (void*)item;

/**
 * Adds items from a C array to the OFDataArray.
 *
 * \param nitems The number of items to add
 * \param carray A C array containing the items to add
 */
-  addNItems: (size_t)nitems
  fromCArray: (void*)carray;

/**
 * Removes the specified amount of items from the end of the OFDataArray.
 *
 * \param nitems The number of items to remove
 */
- removeNItems: (size_t)nitems;
@end

/**
 * The OFBigDataArray class provides a class for storing arbitrary data in an
 * array and is designed to store large hunks of data. Therefore, it allocates
 * memory in pages rather than a chunk of memory for each item.
 */
@interface OFBigDataArray: OFDataArray <OFCopying>
{
	size_t size;
}
@end
