/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFObject.h"
#import "OFSerialization.h"
#import "OFMessagePackRepresentation.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;
@class OFURL;

/*!
 * @class OFData OFData.h ObjFW/OFData.h
 *
 * @brief A class for storing arbitrary data in an array.
 *
 * For security reasons, serialization and deserialization is only implemented
 * for OFData with item size 1.
 */
@interface OFData: OFObject <OFCopying, OFMutableCopying, OFComparing,
    OFSerialization, OFMessagePackRepresentation>
{
	unsigned char *_items;
	size_t _count, _itemSize;
	bool _freeWhenDone;
}

/*!
 * The size of a single item in the OFData in bytes.
 */
@property (readonly, nonatomic) size_t itemSize;

/*!
 * @brief Creates a new OFData with the specified `count` items of size 1.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithItems: (const void *)items
			count: (size_t)count;

/*!
 * @brief Creates a new OFData with the specified `count` items of the
 *	  specified size.
 *
 * @param items The items to store in the OFData
 * @param itemSize The item size of a single item in bytes
 * @param count The number of items
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithItems: (const void *)items
		     itemSize: (size_t)itemSize
			count: (size_t)count;

/*!
 * @brief Creates a new OFData with the specified `count` items of size 1 by
 *	  taking over ownership of the specified items pointer.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @param freeWhenDone Whether to free the pointer when it is no longer needed
 *		       by the OFData
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithItemsNoCopy: (const void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone;

/*!
 * @brief Creates a new OFData with the specified `count` items of the
 *	  specified size by taking ownership of the specified items pointer.
 *
 * @param items The items to store in the OFData
 * @param itemSize The item size of a single item in bytes
 * @param count The number of items
 * @param freeWhenDone Whether to free the pointer when it is no longer needed
 *		       by the OFData
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithItemsNoCopy: (const void *)items
			   itemSize: (size_t)itemSize
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone;

#ifdef OF_HAVE_FILES
/*!
 * @brief Creates a new OFData with an item size of 1, containing the data of
 *	  the specified file.
 *
 * @param path The path of the file
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithContentsOfFile: (OFString *)path;
#endif

#if defined(OF_HAVE_FILES) || defined(OF_HAVE_SOCKETS)
/*!
 * @brief Creates a new OFData with an item size of 1, containing the data of
 *	  the specified URL.
 *
 * @param URL The URL to the contents for the OFData
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithContentsOfURL: (OFURL *)URL;
#endif

/*!
 * @brief Creates a new OFData with an item size of 1, containing the data of
 *	  the string representation.
 *
 * @param string The string representation of the data
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithStringRepresentation: (OFString *)string;

/*!
 * @brief Creates a new OFData with an item size of 1, containing the data of
 *	  the Base64-encoded string.
 *
 * @param string The string with the Base64-encoded data
 * @return A new autoreleased OFData
 */
+ (instancetype)dataWithBase64EncodedString: (OFString *)string;

- init OF_UNAVAILABLE;

/*!
 * @brief Initialized an already allocated OFData with the specified `count`
 *	  items of size 1.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @return An initialized OFData
 */
- initWithItems: (const void *)items
	  count: (size_t)count;

/*!
 * @brief Initialized an already allocated OFData with the specified `count`
 *	  items of the specified size.
 *
 * @param items The items to store in the OFData
 * @param itemSize The item size of a single item in bytes
 * @param count The number of items
 * @return An initialized OFData
 */
- initWithItems: (const void *)items
       itemSize: (size_t)itemSize
	  count: (size_t)count;

/*!
 * @brief Initializes an already allocated OFData with the specified `count`
 *	  items of size 1 by taking over ownership of the specified items
 *	  pointer.
 *
 * @param items The items to store in the OFData
 * @param count The number of items
 * @param freeWhenDone Whether to free the pointer when it is no longer needed
 *		       by the OFData
 * @return An initialized OFData
 */
- initWithItemsNoCopy: (const void *)items
		count: (size_t)count
	 freeWhenDone: (bool)freeWhenDone;

/*!
 * @brief Initializes an already allocated OFData with the specified `count`
 *	  items of the specified size by taking ownership of the specified
 *	  items pointer.
 *
 * @param items The items to store in the OFData
 * @param itemSize The item size of a single item in bytes
 * @param count The number of items
 * @param freeWhenDone Whether to free the pointer when it is no longer needed
 *		       by the OFData
 * @return An initialized OFData
 */
- initWithItemsNoCopy: (const void *)items
	     itemSize: (size_t)itemSize
		count: (size_t)count
	 freeWhenDone: (bool)freeWhenDone;

#ifdef OF_HAVE_FILES
/*!
 * @brief Initializes an already allocated OFData with an item size of 1,
 *	  containing the data of the specified file.
 *
 * @param path The path of the file
 * @return An initialized OFData
 */
- initWithContentsOfFile: (OFString *)path;
#endif

#if defined(OF_HAVE_FILES) || defined(OF_HAVE_SOCKETS)
/*!
 * @brief Initializes an already allocated OFData with an item size of 1,
 *	  containing the data of the specified URL.
 *
 * @param URL The URL to the contents for the OFData
 * @return A new autoreleased OFData
 */
- initWithContentsOfURL: (OFURL *)URL;
#endif

/*!
 * @brief Initializes an already allocated OFData with an item size of 1,
 *	  containing the data of the string representation.
 *
 * @param string The string representation of the data
 * @return A new autoreleased OFData
 */
- initWithStringRepresentation: (OFString *)string;

/*!
 * @brief Initializes an already allocated OFData with an item size of 1,
 *	  containing the data of the Base64-encoded string.
 *
 * @param string The string with the Base64-encoded data
 * @return An initialized OFData
 */
- initWithBase64EncodedString: (OFString *)string;

/*!
 * @brief Returns the number of items in the OFData.
 *
 * @return The number of items in the OFData
 */
- (size_t)count;

/*!
 * @brief Returns all items of the OFData as a C array.
 *
 * @warning The pointer is only valid until the OFData is changed!
 *
 * @return All elements of the OFData as a C array
 */
- (const void *)items OF_RETURNS_INNER_POINTER;

/*!
 * @brief Returns a specific item of the OFData.
 *
 * @param index The number of the item to return
 * @return The specified item of the OFData
 */
- (const void *)itemAtIndex: (size_t)index OF_RETURNS_INNER_POINTER;

/*!
 * @brief Returns the first item of the OFData.
 *
 * @return The first item of the OFData or NULL
 */
- (nullable const void *)firstItem OF_RETURNS_INNER_POINTER;

/*!
 * @brief Returns the last item of the OFData.
 *
 * @return The last item of the OFData or NULL
 */
- (nullable const void *)lastItem OF_RETURNS_INNER_POINTER;

/*!
 * @brief Returns the string representation of the data.
 *
 * The string representation is a hex dump of the data, grouped by itemSize
 * bytes.
 *
 * @return The string representation of the data.
 */
- (OFString *)stringRepresentation;

/*!
 * @brief Returns a string containing the data in Base64 encoding.
 *
 * @return A string containing the data in Base64 encoding
 */
- (OFString *)stringByBase64Encoding;

#ifdef OF_HAVE_FILES
/*!
 * @brief Writes the OFData into the specified file.
 *
 * @param path The path of the file to write to
 */
- (void)writeToFile: (OFString *)path;
#endif
@end

OF_ASSUME_NONNULL_END

#import "OFMutableData.h"
#import "OFData+CryptoHashing.h"
#import "OFData+MessagePackValue.h"
