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

#include <stdarg.h>

#import "OFObject.h"
#import "OFCollection.h"
#import "OFEnumerator.h"

@class OFArray;

#ifdef OF_HAVE_BLOCKS
typedef void (^of_dictionary_enumeration_block_t)(id key, id object,
     BOOL *stop);
typedef BOOL (^of_dictionary_filter_block_t)(id key, id object);
typedef id (^of_dictionary_map_block_t)(id key, id object);
#endif

struct of_dictionary_bucket
{
	id <OFCopying> key;
	id object;
	uint32_t hash;
};

/**
 * \brief A class for storing objects in a hash table.
 */
@interface OFDictionary: OFObject <OFCopying, OFMutableCopying, OFCollection,
    OFFastEnumeration>
{
	struct of_dictionary_bucket **data;
	uint32_t size;
	size_t count;
}

/**
 * Creates a new OFDictionary.
 *
 * \return A new autoreleased OFDictionary
 */
+ dictionary;

/**
 * Creates a new OFDictionary with the specified dictionary.
 *
 * \param dictionary An OFDictionary
 * \return A new autoreleased OFDictionary
 */
+ dictionaryWithDictionary: (OFDictionary*)dictionary;

/**
 * Creates a new OFDictionary with the specified key and object.
 *
 * \param key The key
 * \param object The object
 * \return A new autoreleased OFDictionary
 */
+ dictionaryWithObject: (id)object
		forKey: (id <OFCopying>)key;

/**
 * Creates a new OFDictionary with the specified keys and objects.
 *
 * \param keys An array of keys
 * \param objects An array of objects
 * \return A new autoreleased OFDictionary
 */
+ dictionaryWithObjects: (OFArray*)objects
		forKeys: (OFArray*)keys;

/**
 * Creates a new OFDictionary with the specified keys objects.
 *
 * \param firstKey The first key
 * \return A new autoreleased OFDictionary
 */
+ dictionaryWithKeysAndObjects: (id <OFCopying>)firstKey, ...;

/**
 * Initializes an already allocated OFDictionary.
 *
 * \return An initialized OFDictionary
 */
- init;

/**
 * Initializes an already allocated OFDictionary with the specified
 * OFDictionary.
 *
 * \param dictionary An OFDictionary
 * \return An initialized OFDictionary
 */
- initWithDictionary: (OFDictionary*)dictionary;

/**
 * Initializes an already allocated OFDictionary with the specified key and
 * object.
 *
 * \param key The key
 * \param object The object
 * \return A new initialized OFDictionary
 */
- initWithObject: (id)object
	  forKey: (id <OFCopying>)key;

/**
 * Initializes an already allocated OFDictionary with the specified keys and
 * objects.
 *
 * \param keys An array of keys
 * \param objects An array of objects
 * \return A new initialized OFDictionary
 */
- initWithObjects: (OFArray*)objects
	  forKeys: (OFArray*)keys;

/**
 * Initializes an already allocated OFDictionary with the specified keys and
 * objects.
 *
 * \param firstKey The first key
 * \return A new initialized OFDictionary
 */
- initWithKeysAndObjects: (id <OFCopying>)firstKey, ...;

/**
 * Initializes an already allocated OFDictionary with the specified key and
 * va_list.
 *
 * \param firstKey The first key
 * \param arguments A va_list of the other arguments
 * \return A new initialized OFDictionary
 */
- initWithKey: (id <OFCopying>)firstKey
    arguments: (va_list)arguments;

/**
 * Returns the object for the given key or nil if the key was not found.
 *
 * The returned object is <i>not</i> retained and autoreleased for performance
 * reasons!
 *
 * \param key The key whose object should be returned
 * \return The object for the given key or nil if the key was not found
 */
- (id)objectForKey: (id)key;

/**
 * \return An OFEnumerator to enumerate through the dictionary's keys
 */
- (OFEnumerator*)keyEnumerator;

#ifdef OF_HAVE_BLOCKS
/**
 * Executes a block for each key / object pair.
 *
 * \param block The block to execute for each key / object pair.
 */
- (void)enumerateKeysAndObjectsUsingBlock:
    (of_dictionary_enumeration_block_t)block;

/**
 * Returns a new dictionary, mapping each object using the specified block.
 *
 * \param block A block which maps an object for each object
 * \return A new, autorelease OFDictionary
 */
- (OFDictionary*)mappedDictionaryUsingBlock: (of_dictionary_map_block_t)block;

/**
 * Returns a new dictionary, only containing the objects for which the block
 * returns YES.
 *
 * \param block A block which determines if the object should be in the new
 *		dictionary
 * \return A new, autoreleased OFDictionary
 */
- (OFDictionary*)filteredDictionaryUsingBlock:
    (of_dictionary_filter_block_t)block;
#endif
@end

@interface OFDictionaryEnumerator: OFEnumerator
{
	OFDictionary *dictionary;
	struct of_dictionary_bucket **data;
	uint32_t size;
	unsigned long mutations;
	unsigned long *mutationsPtr;
	uint32_t pos;
}

- initWithDictionary: (OFDictionary*)dictionary
		data: (struct of_dictionary_bucket**)data
		size: (uint32_t)size
    mutationsPointer: (unsigned long*)mutationsPtr;
@end

@interface OFDictionaryObjectEnumerator: OFDictionaryEnumerator
@end

@interface OFDictionaryKeyEnumerator: OFDictionaryEnumerator
@end

#import "OFMutableDictionary.h"

#ifdef __cplusplus
extern "C" {
#endif
extern struct of_dictionary_bucket of_dictionary_deleted_bucket;
#ifdef __cplusplus
}
#endif
