/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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
#import "OFSerialization.h"

@class OFString;
@class OFURL;

/*!
 * @brief A class for storing arbitrary data in an array.
 *
 * If you plan to store large hunks of data, you should consider using
 * OFBigDataArray, which allocates the memory in pages rather than in bytes.
 *
 * For security reasons, serialization and deserialization is only implemented
 * for OFDataArrays with item size 1.
 */
@interface OFDataArray: OFObject <OFCopying, OFComparing, OFSerialization>
{
	uint8_t *_items;
	size_t _count, _itemSize, _capacity;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) void *items;
@property (readonly) size_t count;
@property (readonly) size_t itemSize;
#endif

/*!
 * @brief Creates a new OFDataArray with an item size of 1.
 *
 * @return A new autoreleased OFDataArray
 */
+ (instancetype)dataArray;

/*!
 * @brief Creates a new OFDataArray whose items all have the same specified
 *	  size.
 *
 * @param itemSize The size of a single element in the OFDataArray
 * @return A new autoreleased OFDataArray
 */
+ (instancetype)dataArrayWithItemSize: (size_t)itemSize;

/*!
 * @brief Creates a new OFDataArray with enough memory to hold the specified
 *	  number of items which all have the same specified size.
 *
 * @param itemSize The size of a single element in the OFDataArray
 * @param capacity The initial capacity for the OFDataArray
 * @return A new autoreleased OFDataArray
 */
+ (instancetype)dataArrayWithItemSize: (size_t)itemSize
			     capacity: (size_t)capacity;

/*!
 * @brief Creates a new OFDataArary with an item size of 1, containing the data
 *	  of the specified file.
 *
 * @param path The path of the file
 * @return A new autoreleased OFDataArray
 */
+ (instancetype)dataArrayWithContentsOfFile: (OFString*)path;

/*!
 * @brief Creates a new OFDataArray with an item size of 1, containing the data
 *	  of the specified URL.
 *
 * @param URL The URL to the contents for the OFDataArray
 * @return A new autoreleased OFDataArray
 */
+ (instancetype)dataArrayWithContentsOfURL: (OFURL*)URL;

/*!
 * @brief Creates a new OFDataArray with an item size of 1, containing the data
 *	  of the string representation.
 *
 * @param string The string representation of the data
 * @return A new autoreleased OFDataArray
 */
+ (instancetype)dataArrayWithStringRepresentation: (OFString*)string;

/*!
 * @brief Creates a new OFDataArray with an item size of 1, containing the data
 *	  of the Base64-encoded string.
 *
 * @param string The string with the Base64-encoded data
 * @return A new autoreleased OFDataArray
 */
+ (instancetype)dataArrayWithBase64EncodedString: (OFString*)string;

/*!
 * @brief Initializes an already allocated OFDataArray whose items all have the
 *	  same size.
 *
 * @param itemSize The size of a single element in the OFDataArray
 * @return An initialized OFDataArray
 */
- initWithItemSize: (size_t)itemSize;

/*!
 * @brief Initializes an already allocated OFDataArray with enough memory to
 *	  hold the specified number of items which all have the same specified
 *	  size.
 *
 * @param itemSize The size of a single element in the OFDataArray
 * @param capacity The initial capacity for the OFDataArray
 * @return An initialized OFDataArray
 */
- initWithItemSize: (size_t)itemSize
	  capacity: (size_t)capacity;

/*!
 * @brief Initializes an already allocated OFDataArray with an item size of 1,
 *	  containing the data of the specified file.
 *
 * @param path The path of the file
 * @return An initialized OFDataArray
 */
- initWithContentsOfFile: (OFString*)path;

/*!
 * @brief Initializes an already allocated OFDataArray with an item size of 1,
 *	  containing the data of the specified URL.
 *
 * @param URL The URL to the contents for the OFDataArray
 * @return A new autoreleased OFDataArray
 */
- initWithContentsOfURL: (OFURL*)URL;

/*!
 * @brief Initializes an already allocated OFDataArray with an item size of 1,
 *	  containing the data of the string representation.
 *
 * @param string The string representation of the data
 * @return A new autoreleased OFDataArray
 */
- initWithStringRepresentation: (OFString*)string;

/*!
 * @brief Initializes an already allocated OFDataArray with an item size of 1,
 *	  containing the data of the Base64-encoded string.
 *
 * @param string The string with the Base64-encoded data
 * @return An initialized OFDataArray
 */
- initWithBase64EncodedString: (OFString*)string;

/*!
 * @brief Returns the number of items in the OFDataArray.
 *
 * @return The number of items in the OFDataArray
 */
- (size_t)count;

/*!
 * @brief Returns the size of a single item in the OFDataArray in bytes.
 *
 * @return The size of a single item in the OFDataArray in bytes
 */
- (size_t)itemSize;

/*!
 * @brief Returns all items of the OFDataArray as a C array.
 *
 * @warning The pointer is only valid until the OFDataArray is changed!
 *
 * Modifying the returned array directly is allowed and will change the contents
 * of the data array.
 *
 * @return All elements of the OFDataArray as a C array
 */
- (void*)items OF_RETURNS_INNER_POINTER;

/*!
 * @brief Returns a specific item of the OFDataArray.
 *
 * @param index The number of the item to return
 * @return The specified item of the OFDataArray
 */
- (void*)itemAtIndex: (size_t)index OF_RETURNS_INNER_POINTER;

/*!
 * @brief Returns the first item of the OFDataArray.
 *
 * @return The first item of the OFDataArray or NULL
 */
- (void*)firstItem OF_RETURNS_INNER_POINTER;

/*!
 * @brief Returns the last item of the OFDataArray.
 *
 * @return The last item of the OFDataArray or NULL
 */
- (void*)lastItem OF_RETURNS_INNER_POINTER;

/*!
 * @brief Adds an item to the OFDataArray.
 *
 * @param item A pointer to an arbitrary item
 */
- (void)addItem: (const void*)item;

/*!
 * @brief Adds an item to the OFDataArray at the specified index.
 *
 * @param item A pointer to an arbitrary item
 * @param index The index where the item should be added
 */
- (void)insertItem: (const void*)item
	   atIndex: (size_t)index;

/*!
 * @brief Adds items from a C array to the OFDataArray.
 *
 * @param items A C array containing the items to add
 * @param count The number of items to add
 */
- (void)addItems: (const void*)items
	   count: (size_t)count;

/*!
 * @brief Adds items from a C array to the OFDataArray at the specified index.
 *
 * @param items A C array containing the items to add
 * @param index The index where the items should be added
 * @param count The number of items to add
 */
- (void)insertItems: (const void*)items
	    atIndex: (size_t)index
	      count: (size_t)count;

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
 * @brief Returns the string representation of the data array.
 *
 * @return The string representation of the data array.
 */
- (OFString*)stringRepresentation;

/*!
 * @brief Returns a string containing the data in Base64 encoding.
 *
 * @return A string containing the data in Base64 encoding
 */
- (OFString*)stringByBase64Encoding;

/*!
 * @brief Writes the OFDataArray into the specified file.
 *
 * @param path The path of the file to write to
 */
- (void)writeToFile: (OFString*)path;
@end

/*!
 * @brief A class for storing arbitrary big data in an array.
 *
 * The OFBigDataArray class is a class for storing arbitrary data in an array
 * and is designed to store large hunks of data. Therefore, it allocates
 * memory in pages rather than a chunk of memory for each item.
 */
@interface OFBigDataArray: OFDataArray
{
	size_t _size;
}
@end

#import "OFDataArray+Hashing.h"
#import "OFDataArray+BinaryPackValue.h"
