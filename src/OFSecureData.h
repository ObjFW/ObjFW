/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
 * @class OFSecureData OFSecureData.h ObjFW/ObjFW.h
 *
 * @brief A class for storing arbitrary data in secure (non-swappable) memory,
 *	  securely wiping it when it gets deallocated.
 *
 * @warning Non-swappable memory might be unavailable, in which case this falls
 *	    back to swappable memory, but still wipes the data when it gets
 *	    deallocated. Check the @ref allowsSwappableMemory property to see
 *	    whether a particular OFSecureData might be allocated in swappable
 *	    memory.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFSecureData: OFData
{
	unsigned char *_Nullable _items;
	size_t _count, _itemSize;
	bool _freeWhenDone, _allowsSwappableMemory;
	void *_page;
}

/**
 * @brief Whether the data may be stored in swappable memory.
 */
@property (readonly, nonatomic) bool allowsSwappableMemory;

/**
 * @brief All items of the OFSecureData as a C array.
 *
 * Modifying the returned array directly is allowed and will change the contents
 * of the data.
 */
@property (readonly, nonatomic) void *mutableItems OF_RETURNS_INNER_POINTER;

/**
 * @brief Preallocates the specified number of bytes for unswappable memory.
 *
 * This is useful to allocate unswappable memory before enabling a sandbox that
 * does not allow it anymore.
 *
 * @note This may only be called once per thread!
 * @note Preallocated unswappable memory is only available for data that is
 *	 smaller than a single page!
 *
 * @param size The number of bytes of unswappable memory to preallocate
 */
+ (void)preallocateUnswappableMemoryWithSize: (size_t)size;

/**
 * @brief Creates a new, autoreleased OFSecureData with `count` items of item
 *	  size 1, all set to zero.
 *
 * @param count The number of zero items the OFSecureData should contain
 * @param allowsSwappableMemory Whether the data may be stored in swappable
 *				memory
 * @return A new, autoreleased OFSecureData
 */
+ (instancetype)dataWithCount: (size_t)count
	allowsSwappableMemory: (bool)allowsSwappableMemory;

/**
 * @brief Creates a new, autoreleased OFSecureData with `count` items of the
 *	  specified item size, all set to zero.
 *
 * @param count The number of zero items the OFSecureData should contain
 * @param itemSize The size of a single item in the OFSecureData in bytes
 * @param allowsSwappableMemory Whether the data may be stored in swappable
 *			       memory
 * @return A new, autoreleased OFSecureData
 */
+ (instancetype)dataWithCount: (size_t)count
		     itemSize: (size_t)itemSize
	allowsSwappableMemory: (bool)allowsSwappableMemory;

+ (instancetype)dataWithItems: (const void *)items
			count: (size_t)count OF_UNAVAILABLE;
+ (instancetype)dataWithItems: (const void *)items
			count: (size_t)count
		     itemSize: (size_t)itemSize OF_UNAVAILABLE;
+ (instancetype)dataWithItemsNoCopy: (void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone OF_UNAVAILABLE;
+ (instancetype)dataWithItemsNoCopy: (void *)items
			      count: (size_t)count
			   itemSize: (size_t)itemSize
		       freeWhenDone: (bool)freeWhenDone OF_UNAVAILABLE;
#ifdef OF_HAVE_FILES
+ (instancetype)dataWithContentsOfFile: (OFString *)path OF_UNAVAILABLE;
#endif
+ (instancetype)dataWithContentsOfIRI: (OFIRI *)IRI OF_UNAVAILABLE;
+ (instancetype)dataWithStringRepresentation: (OFString *)string OF_UNAVAILABLE;
+ (instancetype)dataWithBase64EncodedString: (OFString *)string OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFSecureData with `count` items of
 *	  item size 1, all set to zero.
 *
 * @param count The number of zero items the OFSecureData should contain
 * @param allowsSwappableMemory Whether the data may be stored in swappable
 *				memory
 * @return An initialized OFSecureData
 */
- (instancetype)initWithCount: (size_t)count
	allowsSwappableMemory: (bool)allowsSwappableMemory;

/**
 * @brief Initializes an already allocated OFSecureData with `count` items of
 *	  the specified item size, all set to zero.
 *
 * @param itemSize The size of a single item in the OFSecureData in bytes
 * @param count The number of zero items the OFSecureData should contain
 * @param allowsSwappableMemory Whether the data may be stored in swappable
 *				memory
 * @return An initialized OFSecureData
 */
- (instancetype)initWithCount: (size_t)count
		     itemSize: (size_t)itemSize
	allowsSwappableMemory: (bool)allowsSwappableMemory
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
- (instancetype)initWithItemSize: (size_t)itemSize OF_UNAVAILABLE;
- (instancetype)initWithItems: (const void *)items
			count: (size_t)count OF_UNAVAILABLE;
- (instancetype)initWithItems: (const void *)items
			count: (size_t)count
		     itemSize: (size_t)itemSize OF_UNAVAILABLE;
- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
		       freeWhenDone: (bool)freeWhenDone OF_UNAVAILABLE;
- (instancetype)initWithItemsNoCopy: (void *)items
			      count: (size_t)count
			   itemSize: (size_t)itemSize
		       freeWhenDone: (bool)freeWhenDone OF_UNAVAILABLE;
#ifdef OF_HAVE_FILES
- (instancetype)initWithContentsOfFile: (OFString *)path OF_UNAVAILABLE;
#endif
- (instancetype)initWithContentsOfIRI: (OFIRI *)IRI OF_UNAVAILABLE;
- (instancetype)initWithStringRepresentation: (OFString *)string OF_UNAVAILABLE;
- (instancetype)initWithBase64EncodedString: (OFString *)string OF_UNAVAILABLE;

/**
 * @brief Returns a specific item of the OFSecureData.
 *
 * Modifying the returned item directly is allowed and will change the contents
 * of the data array.
 *
 * @param index The number of the item to return
 * @return The specified item of the OFSecureData
 */
- (void *)mutableItemAtIndex: (size_t)index OF_RETURNS_INNER_POINTER;

/**
 * @brief Checks the OFSecureData for equality to another object.
 *
 * If the specified object is a subclass of @ref OFData, the comparison is
 * performed in constant time.
 *
 * @param object The object which should be tested for equality
 * @return A boolean whether the OFSecureData is equal to the specified object
 */
- (bool)isEqual: (nullable id)object;

/**
 * @brief Zeroes the data.
 */
- (void)zero;

- (OFString *)stringRepresentation OF_UNAVAILABLE;
- (OFString *)stringByBase64Encoding OF_UNAVAILABLE;
#ifdef OF_HAVE_FILES
- (void)writeToFile: (OFString *)path OF_UNAVAILABLE;
#endif
- (void)writeToIRI: (OFIRI *)IRI OF_UNAVAILABLE;
- (OFData *)messagePackRepresentation OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
