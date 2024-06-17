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

#import "OFObject.h"
#import "OFEnumerator.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

/**
 * @struct OFMapTableFunctions OFMapTable.h ObjFW/ObjFW.h
 *
 * @brief A struct describing the functions to be used by the map table.
 */
typedef struct {
	/** The function to retain keys / objects */
	void *_Nullable (*_Nullable retain)(void *_Nullable object);
	/** The function to release keys / objects */
	void (*_Nullable release)(void *_Nullable object);
	/** The function to hash keys */
	unsigned long (*_Nullable hash)(void *_Nullable object);
	/** The function to compare keys / objects */
	bool (*_Nullable equal)(void *_Nullable object1,
	    void *_Nullable object2);
} OFMapTableFunctions;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block for enumerating an OFMapTable.
 *
 * @param key The current key
 * @param object The current object
 * @param stop A pointer to a variable that can be set to true to stop the
 *	       enumeration
 */
typedef void (^OFMapTableEnumerationBlock)(void *_Nullable key,
    void *_Nullable object, bool *stop);

/**
 * @brief A block for replacing objects in an OFMapTable.
 *
 * @param key The key of the object to replace
 * @param object The object to replace
 * @return The object to replace the object with
 */
typedef void *_Nullable (^OFMapTableReplaceBlock)(void *_Nullable key,
    void *_Nullable object);
#endif

@class OFMapTableEnumerator;

/**
 * @class OFMapTable OFMapTable.h ObjFW/ObjFW.h
 *
 * @brief A class similar to OFDictionary, but providing more options how keys
 *	  and objects should be retained, released, compared and hashed.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFMapTable: OFObject <OFCopying, OFFastEnumeration>
{
	OFMapTableFunctions _keyFunctions, _objectFunctions;
	struct OFMapTableBucket *_Nonnull *_Nullable _buckets;
	uint32_t _count, _capacity;
	unsigned char _rotation;
	unsigned long _mutations;
}

/**
 * @brief The key functions used by the map table.
 */
@property (readonly, nonatomic) OFMapTableFunctions keyFunctions;

/**
 * @brief The object functions used by the map table.
 */
@property (readonly, nonatomic) OFMapTableFunctions objectFunctions;

/**
 * @brief The number of objects in the map table.
 */
@property (readonly, nonatomic) size_t count;

/**
 * @brief Creates a new OFMapTable with the specified key and object functions.
 *
 * @param keyFunctions A structure of functions for handling keys
 * @param objectFunctions A structure of functions for handling objects
 * @return A new autoreleased OFMapTable
 */
+ (instancetype)mapTableWithKeyFunctions: (OFMapTableFunctions)keyFunctions
			 objectFunctions: (OFMapTableFunctions)objectFunctions;

/**
 * @brief Creates a new OFMapTable with the specified key functions, object
 *	  functions and capacity.
 *
 * @param keyFunctions A structure of functions for handling keys
 * @param objectFunctions A structure of functions for handling objects
 * @param capacity A hint about the count of elements expected to be in the map
 *	  table
 * @return A new autoreleased OFMapTable
 */
+ (instancetype)mapTableWithKeyFunctions: (OFMapTableFunctions)keyFunctions
			 objectFunctions: (OFMapTableFunctions)objectFunctions
				capacity: (size_t)capacity;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFMapTable with the specified key
 *	  and object functions.
 *
 * @param keyFunctions A structure of functions for handling keys
 * @param objectFunctions A structure of functions for handling objects
 * @return An initialized OFMapTable
 */
- (instancetype)initWithKeyFunctions: (OFMapTableFunctions)keyFunctions
		     objectFunctions: (OFMapTableFunctions)objectFunctions;

/**
 * @brief Initializes an already allocated OFMapTable with the specified key
 *	  functions, object functions and capacity.
 *
 * @param keyFunctions A structure of functions for handling keys
 * @param objectFunctions A structure of functions for handling objects
 * @param capacity A hint about the count of elements expected to be in the map
 *	  table
 * @return An initialized OFMapTable
 */
- (instancetype)initWithKeyFunctions: (OFMapTableFunctions)keyFunctions
		     objectFunctions: (OFMapTableFunctions)objectFunctions
			    capacity: (size_t)capacity
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Returns the object for the given key or NULL if the key was not found.
 *
 * @param key The key whose object should be returned
 * @return The object for the given key or NULL if the key was not found
 */
- (nullable void *)objectForKey: (void *)key;

/**
 * @brief Sets an object for a key.
 *
 * @param key The key to set
 * @param object The object to set the key to
 */
- (void)setObject: (nullable void *)object forKey: (nullable void *)key;

/**
 * @brief Removes the object for the specified key from the map table.
 *
 * @param key The key whose object should be removed
 */
- (void)removeObjectForKey: (nullable void *)key;

/**
 * @brief Removes all objects.
 */
- (void)removeAllObjects;

/**
 * @brief Checks whether the map table contains an object equal to the
 *	  specified object.
 *
 * @param object The object which is checked for being in the map table
 * @return A boolean whether the map table contains the specified object
*/
- (bool)containsObject: (nullable void *)object;

/**
 * @brief Checks whether the map table contains an object with the specified
 *        address.
 *
 * @param object The object which is checked for being in the map table
 * @return A boolean whether the map table contains an object with the
 *	   specified address.
 */
- (bool)containsObjectIdenticalTo: (nullable void *)object;

/**
 * @brief Returns an OFMapTableEnumerator to enumerate through the map table's
 *	  keys.
 *
 * @return An OFMapTableEnumerator to enumerate through the map table's keys
 */
- (OFMapTableEnumerator *)keyEnumerator;

/**
 * @brief Returns an OFMapTableEnumerator to enumerate through the map table's
 *	  objects.
 *
 * @return An OFMapTableEnumerator to enumerate through the map table's objects
 */
- (OFMapTableEnumerator *)objectEnumerator;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Executes a block for each key / object pair.
 *
 * @param block The block to execute for each key / object pair.
 */
- (void)enumerateKeysAndObjectsUsingBlock: (OFMapTableEnumerationBlock)block;

/**
 * @brief Replaces each object with the object returned by the block.
 *
 * @param block The block which returns a new object for each object
 */
- (void)replaceObjectsUsingBlock: (OFMapTableReplaceBlock)block;
#endif
@end

/**
 * @class OFMapTableEnumerator OFMapTable.h ObjFW/ObjFW.h
 *
 * @brief A class which provides methods to enumerate through an OFMapTable's
 *	  keys or objects.
 */
#ifndef OF_MAP_TABLE_M
OF_SUBCLASSING_RESTRICTED
#endif
@interface OFMapTableEnumerator: OFObject
{
	OFMapTable *_mapTable;
	struct OFMapTableBucket *_Nonnull *_Nullable _buckets;
	uint32_t _capacity;
	unsigned long _mutations, *_Nullable _mutationsPtr, _position;
}

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Returns a pointer to the next object, or NULL if the enumeration
 *	  finished.
 *
 * @return The next object
 */
- (void *_Nullable *_Nullable)nextObject;
@end

OF_ASSUME_NONNULL_END
