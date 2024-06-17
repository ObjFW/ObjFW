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

#import "OFDictionary.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block for replacing objects in an OFMutableDictionary.
 *
 * @param key The key of the object to replace
 * @param object The object to replace
 * @return The object to replace the object with
 */
typedef id _Nonnull (^OFDictionaryReplaceBlock)(id key, id object);
#endif

/**
 * @class OFMutableDictionary OFMutableDictionary.h ObjFW/ObjFW.h
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
/**
 * @brief Creates a new OFMutableDictionary with enough memory to hold the
 *	  specified number of objects.
 *
 * @param capacity The initial capacity for the OFMutableDictionary
 * @return A new autoreleased OFMutableDictionary
 */
+ (instancetype)dictionaryWithCapacity: (size_t)capacity;

/**
 * @brief Initializes an already allocated OFMutableDictionary to be empty.
 *
 * @return An initialized OFMutableDictionary
 */
- (instancetype)init OF_DESIGNATED_INITIALIZER;

/**
 * @brief Initializes an already allocated OFMutableDictionary with enough
 *	  memory to hold the specified number of objects.
 *
 * @param capacity The initial capacity for the OFMutableDictionary
 * @return An initialized OFMutableDictionary
 */
- (instancetype)initWithCapacity: (size_t)capacity OF_DESIGNATED_INITIALIZER;

/**
 * @brief Sets an object for a key.
 *
 * A key can be any object that conforms to the OFCopying protocol.
 *
 * @param key The key to set
 * @param object The object to set the key to
 */
- (void)setObject: (ObjectType)object forKey: (KeyType)key;

/**
 * @brief Sets an object for a key.
 *
 * A key can be any object that conforms to the OFCopying protocol.
 *
 * This method is also used by the subscripting syntax.
 *
 * @param key The key to set
 * @param object The object to set the key to. If it is nil, this is equal to
 *		 calling @ref removeObjectForKey:.
 */
- (void)setObject: (nullable ObjectType)object forKeyedSubscript: (KeyType)key;

/**
 * @brief Removes the object for the specified key from the dictionary.
 *
 * @param key The key whose object should be removed
 */
- (void)removeObjectForKey: (KeyType)key;

/**
 * @brief Removes all objects.
 */
- (void)removeAllObjects;

/**
 * @brief Adds the entries from the specified dictionary.
 *
 * @param dictionary The dictionary whose entries should be added
 */
- (void)addEntriesFromDictionary:
    (OFDictionary OF_GENERIC(KeyType, ObjectType) *)dictionary;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Replaces each object with the object returned by the block.
 *
 * @param block The block which returns a new object for each object
 */
- (void)replaceObjectsUsingBlock: (OFDictionaryReplaceBlock)block;
#endif

/**
 * @brief Converts the mutable dictionary to an immutable dictionary.
 */
- (void)makeImmutable;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef KeyType
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END
