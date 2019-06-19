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

#import "OFObject.h"
#import "OFEnumerator.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

/*!
 * @struct of_map_table_functions_t OFMapTable.h ObjFW/OFMapTable.h
 *
 * @brief A struct describing the functions to be used by the map table.
 */
typedef struct {
	/*! The function to retain keys / objects */
	void *_Nullable (*_Nullable retain)(void *_Nullable object);
	/*! The function to release keys / objects */
	void (*_Nullable release)(void *_Nullable object);
	/*! The function to hash keys */
	uint32_t (*_Nullable hash)(void *_Nullable object);
	/*! The function to compare keys / objects */
	bool (*_Nullable equal)(void *_Nullable object1,
	    void *_Nullable object2);
} of_map_table_functions_t;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block for enumerating an OFMapTable.
 *
 * @param key The current key
 * @param object The current object
 * @param stop A pointer to a variable that can be set to true to stop the
 *	       enumeration
 */
typedef void (^of_map_table_enumeration_block_t)(void *_Nullable key,
    void *_Nullable object, bool *stop);

/*!
 * @brief A block for replacing objects in an OFMapTable.
 *
 * @param key The key of the object to replace
 * @param object The object to replace
 * @return The object to replace the object with
 */
typedef void *_Nullable (^of_map_table_replace_block_t)(void *_Nullable key,
    void *_Nullable object);
#endif

@class OFMapTableEnumerator;

/*!
 * @class OFMapTable OFMapTable.h ObjFW/OFMapTable.h
 *
 * @brief A class similar to OFDictionary, but providing more options how keys
 *	  and objects should be retained, released, compared and hashed.
 */
@interface OFMapTable: OFObject <OFCopying, OFFastEnumeration>
{
	of_map_table_functions_t _keyFunctions, _objectFunctions;
	struct of_map_table_bucket *_Nonnull *_Nullable _buckets;
	uint32_t _count, _capacity;
	uint8_t _rotate;
	unsigned long _mutations;
}

/*!
 * @brief The key functions used by the map table.
 */
@property (readonly, nonatomic) of_map_table_functions_t keyFunctions;

/*!
 * @brief The object functions used by the map table.
 */
@property (readonly, nonatomic) of_map_table_functions_t objectFunctions;

/*!
 * @brief The number of objects in the map table.
 */
@property (readonly, nonatomic) size_t count;

/*!
 * @brief Creates a new OFMapTable with the specified key and object functions.
 *
 * @param keyFunctions A structure of functions for handling keys
 * @param objectFunctions A structure of functions for handling objects
 * @return A new autoreleased OFMapTable
 */
+ (instancetype)mapTableWithKeyFunctions: (of_map_table_functions_t)keyFunctions
			 objectFunctions: (of_map_table_functions_t)
					      objectFunctions;

/*!
 * @brief Creates a new OFMapTable with the specified key functions, object
 *	  functions and capacity.
 *
 * @param keyFunctions A structure of functions for handling keys
 * @param objectFunctions A structure of functions for handling objects
 * @param capacity A hint about the count of elements expected to be in the map
 *	  table
 * @return A new autoreleased OFMapTable
 */
+ (instancetype)mapTableWithKeyFunctions: (of_map_table_functions_t)keyFunctions
			 objectFunctions: (of_map_table_functions_t)
					      objectFunctions
				capacity: (size_t)capacity;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFMapTable with the specified key
 *	  and object functions.
 *
 * @param keyFunctions A structure of functions for handling keys
 * @param objectFunctions A structure of functions for handling objects
 * @return An initialized OFMapTable
 */
- (instancetype)initWithKeyFunctions: (of_map_table_functions_t)keyFunctions
		     objectFunctions: (of_map_table_functions_t)objectFunctions;

/*!
 * @brief Initializes an already allocated OFMapTable with the specified key
 *	  functions, object functions and capacity.
 *
 * @param keyFunctions A structure of functions for handling keys
 * @param objectFunctions A structure of functions for handling objects
 * @param capacity A hint about the count of elements expected to be in the map
 *	  table
 * @return An initialized OFMapTable
 */
- (instancetype)initWithKeyFunctions: (of_map_table_functions_t)keyFunctions
		     objectFunctions: (of_map_table_functions_t)objectFunctions
			    capacity: (size_t)capacity
    OF_DESIGNATED_INITIALIZER;

/*!
 * @brief Returns the object for the given key or NULL if the key was not found.
 *
 * @param key The key whose object should be returned
 * @return The object for the given key or NULL if the key was not found
 */
- (nullable void *)objectForKey: (void *)key;

/*!
 * @brief Sets an object for a key.
 *
 * @param key The key to set
 * @param object The object to set the key to
 */
- (void)setObject: (nullable void *)object
	   forKey: (nullable void *)key;

/*!
 * @brief Removes the object for the specified key from the map table.
 *
 * @param key The key whose object should be removed
 */
- (void)removeObjectForKey: (nullable void *)key;

/*!
 * @brief Removes all objects.
 */
- (void)removeAllObjects;

/*!
 * @brief Checks whether the map table contains an object equal to the
 *	  specified object.
 *
 * @param object The object which is checked for being in the map table
 * @return A boolean whether the map table contains the specified object
*/
- (bool)containsObject: (nullable void *)object;

/*!
 * @brief Checks whether the map table contains an object with the specified
 *        address.
 *
 * @param object The object which is checked for being in the map table
 * @return A boolean whether the map table contains an object with the
 *	   specified address.
 */
- (bool)containsObjectIdenticalTo: (nullable void *)object;

/*!
 * @brief Returns an OFMapTableEnumerator to enumerate through the map table's
 *	  keys.
 *
 * @return An OFMapTableEnumerator to enumerate through the map table's keys
 */
- (OFMapTableEnumerator *)keyEnumerator;

/*!
 * @brief Returns an OFMapTableEnumerator to enumerate through the map table's
 *	  objects.
 *
 * @return An OFMapTableEnumerator to enumerate through the map table's objects
 */
- (OFMapTableEnumerator *)objectEnumerator;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Executes a block for each key / object pair.
 *
 * @param block The block to execute for each key / object pair.
 */
- (void)enumerateKeysAndObjectsUsingBlock:
    (of_map_table_enumeration_block_t)block;

/*!
 * @brief Replaces each object with the object returned by the block.
 *
 * @param block The block which returns a new object for each object
 */
- (void)replaceObjectsUsingBlock: (of_map_table_replace_block_t)block;
#endif
@end

/*!
 * @class OFMapTableEnumerator OFMapTable.h ObjFW/OFMapTable.h
 *
 * @brief A class which provides methods to enumerate through an OFMapTable's
 *	  keys or objects.
 */
@interface OFMapTableEnumerator: OFObject
{
	OFMapTable *_mapTable;
	struct of_map_table_bucket *_Nonnull *_Nullable _buckets;
	uint32_t _capacity;
	unsigned long _mutations;
	unsigned long *_Nullable _mutationsPtr;
	uint32_t _position;
}

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Returns a pointer to the next object, or NULL if the enumeration
 *	  finished.
 *
 * @return The next object
 */
- (void *_Nullable *_Nullable)nextObject;
@end

OF_ASSUME_NONNULL_END
