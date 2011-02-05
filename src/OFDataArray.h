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

#import "OFObject.h"

@class OFString;

/**
 * \brief A class for storing arbitrary data in an array.
 *
 * If you plan to store large hunks of data, you should consider using
 * OFBigDataArray, which allocates the memory in pages rather than in bytes.
 */
@interface OFDataArray: OFObject <OFCopying, OFComparing>
{
	char   *data;
	size_t count;
	size_t itemSize;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) size_t count;
@property (readonly) size_t itemSize;
#endif

/**
 * Creates a new OFDataArray whose items all have the same size.
 *
 * \param is The size of each element in the OFDataArray
 * \return A new autoreleased OFDataArray
 */
+ dataArrayWithItemSize: (size_t)is;

/**
 * Creates a new OFDataArary with an item size of 1, containing the data of the
 * specified file.
 *
 * \param path The path of the file
 * \return A new autoreleased OFDataArray
 */
+ dataArrayWithContentsOfFile: (OFString*)path;

/**
 * Creates a new OFDataArray with an item size of 1, containing the data of the
 * Base64-encoded string.
 *
 * \param str The string with the Base64-encoded data
 * \return A new autoreleased OFDataArray
 */
+ dataArrayWithBase64EncodedString: (OFString*)str;

/**
 * Initializes an already allocated OFDataArray whose items all have the same
 * size.
 *
 * \param is The size of each element in the OFDataArray
 * \return An initialized OFDataArray
 */
- initWithItemSize: (size_t)is;

/**
 * Initializes an already allocated OFDataArray with an item size of 1,
 * containing the data of the specified file.
 *
 * \param path The path of the file
 * \return An initialized OFDataArray
 */
- initWithContentsOfFile: (OFString*)path;

/**
 * Initializes an already allocated OFDataArray with an item size of 1,
 * containing the data of the Base64-encoded string.
 *
 * \param str The string with the Base64-encoded data
 * \return A initialized OFDataArray
 */
- initWithBase64EncodedString: (OFString*)str;

/**
 * \return The number of items in the OFDataArray
 */
- (size_t)count;

/**
 * \return The size of each item in the OFDataArray in bytes
 */
- (size_t)itemSize;

/**
 * \return All elements of the OFDataArray as a C array
 */
- (void*)cArray;

/**
 * Returns a specific item of the OFDataArray.
 *
 * \param index The number of the item to return
 * \return The specified item of the OFDataArray
 */
- (void*)itemAtIndex: (size_t)index;

/**
 * \return The first item of the OFDataArray or NULL
 */
- (void*)firstItem;

/**
 * \return The last item of the OFDataArray or NULL
 */
- (void*)lastItem;

/**
 * Adds an item to the OFDataArray.
 *
 * \param item A pointer to an arbitrary item
 */
- (void)addItem: (void*)item;

/**
 * Adds an item to the OFDataArray at the specified index.
 *
 * \param item A pointer to an arbitrary item
 * \param index The index where the item should be added
 */
- (void)addItem: (void*)item
	atIndex: (size_t)index;

/**
 * Adds items from a C array to the OFDataArray.
 *
 * \param nitems The number of items to add
 * \param carray A C array containing the items to add
 */
- (void)addNItems: (size_t)nitems
       fromCArray: (void*)carray;

/**
 * Adds items from a C array to the OFDataArray at the specified index.
 *
 * \param nitems The number of items to add
 * \param carray A C array containing the items to add
 * \param index The index where the items should be added
 */
- (void)addNItems: (size_t)nitems
       fromCArray: (void*)carray
	  atIndex: (size_t)index;

/**
 * Removes the item at the specified index.
 *
 * \param index The index of the item to remove
 */
- (void)removeItemAtIndex: (size_t)index;

/**
 * Removes the specified amount of items from the end of the OFDataArray.
 *
 * \param nitems The number of items to remove
 */
- (void)removeNItems: (size_t)nitems;

/**
 * Removes the specified amount of items at the specified index.
 *
 * \param nitems The number of items to remove
 * \param index The index at which the items are removed
 */
- (void)removeNItems: (size_t)nitems
	     atIndex: (size_t)index;

/**
 * \return A string containing the data in Base64 encoding
 */
- (OFString*)stringByBase64Encoding;
@end

/**
 * \brief A class for storing arbitrary big data in an array.
 *
 * The OFBigDataArray class is a class for storing arbitrary data in an array
 * and is designed to store large hunks of data. Therefore, it allocates
 * memory in pages rather than a chunk of memory for each item.
 */
@interface OFBigDataArray: OFDataArray
{
	size_t size;
}
@end

#import "OFDataArray+Hashing.h"
