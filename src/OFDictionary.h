/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <stdarg.h>

#import "OFObject.h"
#import "OFEnumerator.h"

@class OFArray;

/// \cond internal
struct of_dictionary_bucket
{
	OFObject <OFCopying> *key;
	OFObject *object;
	uint32_t hash;
};
/// \endcond

/**
 * \brief A class for storing objects in a hash table.
 */
@interface OFDictionary: OFObject <OFCopying, OFMutableCopying,
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
 * \param dict An OFDictionary
 * \return A new autoreleased OFDictionary
 */
+ dictionaryWithDictionary: (OFDictionary*)dict;

/**
 * Creates a new OFDictionary with the specified key and object.
 *
 * \param key The key
 * \param obj The object
 * \return A new autoreleased OFDictionary
 */
+ dictionaryWithObject: (OFObject*)obj
		forKey: (OFObject <OFCopying>*)key;

/**
 * Creates a new OFDictionary with the specified keys and objects.
 *
 * \param keys An array of keys
 * \param objs An array of objects
 * \return A new autoreleased OFDictionary
 */
+ dictionaryWithObjects: (OFArray*)objs
		forKeys: (OFArray*)keys;

/**
 * Creates a new OFDictionary with the specified keys objects.
 *
 * \param key The first key
 * \return A new autoreleased OFDictionary
 */
+ dictionaryWithKeysAndObjects: (OFObject <OFCopying>*)key, ...;

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
 * \param dict An OFDictionary
 * \return An initialized OFDictionary
 */
- initWithDictionary: (OFDictionary*)dict;

/**
 * Initializes an already allocated OFDictionary with the specified key and
 * object.
 *
 * \param key The key
 * \param obj The object
 * \return A new initialized OFDictionary
 */
- initWithObject: (OFObject*)obj
	  forKey: (OFObject <OFCopying>*)key;

/**
 * Initializes an already allocated OFDictionary with the specified keys and
 * objects.
 *
 * \param keys An array of keys
 * \param objs An array of objects
 * \return A new initialized OFDictionary
 */
- initWithObjects: (OFArray*)objs
	  forKeys: (OFArray*)keys;

/**
 * Initializes an already allocated OFDictionary with the specified keys and
 * objects.
 *
 * \param first The first key
 * \return A new initialized OFDictionary
 */
- initWithKeysAndObjects: (OFObject <OFCopying>*)first, ...;

/**
 * Initializes an already allocated OFDictionary with the specified key and
 * va_list.
 *
 * \param first The first key
 * \param args A va_list of the other arguments
 * \return A new initialized OFDictionary
 */
- initWithKey: (OFObject <OFCopying>*)first
      argList: (va_list)args;

/**
 * \param key The key whose object should be returned
 * \return The object for the given key or nil if the key was not found
 */
- (id)objectForKey: (OFObject <OFCopying>*)key;

/**
 * \return The number of objects in the dictionary
 */
- (size_t)count;

/**
 * \returns An OFEnumerator to enumerate through the dictionary's objects
 */
- (OFEnumerator*)objectEnumerator;

/**
 * \return An OFEnumerator to enumerate through the dictionary's keys
 */
- (OFEnumerator*)keyEnumerator;
@end

/// \cond internal
@interface OFDictionaryEnumerator: OFEnumerator
{
	struct of_dictionary_bucket **data;
	uint32_t size;
	unsigned long mutations;
	unsigned long *mutations_ptr;
	uint32_t pos;
}

-     initWithData: (struct of_dictionary_bucket**)data
	      size: (uint32_t)size
  mutationsPointer: (unsigned long*)mutations_ptr;
@end

@interface OFDictionaryObjectEnumerator: OFDictionaryEnumerator
@end

@interface OFDictionaryKeyEnumerator: OFDictionaryEnumerator
@end
/// \endcond

#import "OFMutableDictionary.h"

extern struct of_dictionary_bucket of_dictionary_deleted_bucket;
