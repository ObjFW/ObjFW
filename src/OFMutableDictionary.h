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

#import "OFDictionary.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block for replacing objects in an OFMutableDictionary.
 *
 * @param key The key of the object to replace
 * @param object The object to replace
 * @return The object to replace the object with
 */
typedef id _Nonnull (^of_dictionary_replace_block_t)(id key, id object);
#endif

/*!
 * @class OFMutableDictionary OFDictionary.h ObjFW/OFDictionary.h
 *
 * @brief An abstract class for storing and changing objects in a dictionary.
 *
 * @note Subclasses must implement @ref setObject:forKey:,
 *	 @ref removeObjectForKey: as well as all methods of @ref OFDictionary
 *	 that need to be implemented.
 */
@interface OFMutableDictionary OF_GENERIC(KeyType, ObjectType):
    OFDictionary OF_GENERIC(KeyType, ObjectType)
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define KeyType id
# define ObjectType id
#endif
/*!
 * @brief Creates a new OFMutableDictionary with enough memory to hold the
 *	  specified number of objects.
 *
 * @param capacity The initial capacity for the OFMutableDictionary
 * @return A new autoreleased OFMutableDictionary
 */
+ (instancetype)dictionaryWithCapacity: (size_t)capacity;

/*!
 * @brief Initializes an already allocated OFMutableDictionary with enough
 *	  memory to hold the specified number of objects.
 *
 * @param capacity The initial capacity for the OFMutableDictionary
 * @return An initialized OFMutableDictionary
 */
- (instancetype)initWithCapacity: (size_t)capacity;

/*!
 * @brief Sets an object for a key.
 *
 * A key can be any object that conforms to the @ref OFCopying protocol.
 *
 * @param key The key to set
 * @param object The object to set the key to
 */
- (void)setObject: (ObjectType)object
	   forKey: (KeyType)key;

/*!
 * @brief Sets an object for a key.
 *
 * A key can be any object that conforms to the @ref OFCopying protocol.
 *
 * This method is also used by the subscripting syntax.
 *
 * @param key The key to set
 * @param object The object to set the key to. If it is nil, this is equal to
 *		 calling @ref removeObjectForKey:.
 */
-   (void)setObject: (nullable ObjectType)object
  forKeyedSubscript: (KeyType)key;

/*!
 * @brief Removes the object for the specified key from the dictionary.
 *
 * @param key The key whose object should be removed
 */
- (void)removeObjectForKey: (KeyType)key;

/*!
 * @brief Removes all objects.
 */
- (void)removeAllObjects;

/*!
 * @brief Adds the entries from the specified dictionary.
 *
 * @param dictionary The dictionary whose entries should be added
 */
- (void)addEntriesFromDictionary:
    (OFDictionary OF_GENERIC(KeyType, ObjectType) *)dictionary;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Replaces each object with the object returned by the block.
 *
 * @param block The block which returns a new object for each object
 */
- (void)replaceObjectsUsingBlock: (of_dictionary_replace_block_t)block;
#endif

/*!
 * @brief Converts the mutable dictionary to an immutable dictionary.
 */
- (void)makeImmutable;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef KeyType
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END
