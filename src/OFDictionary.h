/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <stdarg.h>

#import "OFObject.h"
#import "OFList.h"

/**
 * The OFDictionary class provides a class for using hash tables.
 */
@interface OFDictionary: OFObject
{
	OFList **data;
	size_t size;
}

/**
 * Creates a new OFDictionary, defaulting to a 12 bit hash.
 *
 * \return A new autoreleased OFDictionary
 */
+ dictionary;

/**
 * Creates a new OFDictionary with a hash of N bits.
 *
 * \param bits The size of the hash to use
 * \return A new autoreleased OFDictionary
 */
+ dictionaryWithHashSize: (int)hashsize;

/**
 * Creates a new OFDictionary with the specified key and object.
 *
 * \param key The key
 * \param obj The object
 * \return A new autoreleased OFDictionary
 */
+ dictionaryWithKey: (OFObject <OFCopying>*)key
	  andObject: (OFObject*)obj;

/**
 * Creates a new OFDictionary with the specified keys objects.
 *
 * \param first The first key
 * \return A new autoreleased OFDictionary
 */
+ dictionaryWithKeysAndObjects: (OFObject <OFCopying>*)first, ...;

/**
 * Initializes an already allocated OFDictionary, defaulting to a 12 bit hash.
 *
 * \return An initialized OFDictionary
 */
- init;

/**
 * Initializes an already allocated OFDictionary with a hash of N bits.
 *
 * \param bits The size of the hash to use
 * \return An initialized OFDictionary
 */
- initWithHashSize: (int)hashsize;

/**
 * Initializes an already allocated OFDictionary with the specified key and
 * object.
 *
 * \param key The key
 * \param obj The object
 * \return A new initialized OFDictionary
 */
- initWithKey: (OFObject <OFCopying>*)key
    andObject: (OFObject*)obj;

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
 * \return A new initialized OFDictionary
 */
- initWithKey: (OFObject <OFCopying>*)first
   andArgList: (va_list)args;

/**
 * \return The average number of items in a used bucket. Buckets that are
 *	   completely empty are not in the calculation. If this value is >= 2.0,
 *	   you should resize the dictionary, in most cases even earlier!
 */
- (float)averageItemsPerBucket;

/**
 * \param key The key whose object should be returned
 * \return The object for the given key or nil if the key was not found
 */
- (id)get: (OFObject*)key;

/**
 * Sets a key to an object. A key can be any object.
 *
 * \param key The key to set
 * \param obj The object to set the key to
 */
- set: (OFObject <OFCopying>*)key
   to: (OFObject*)obj;

/**
 * Remove the object with the given key from the dictionary.
 *
 * \param key The key whose object should be removed
 */
- remove: (OFObject*)key;

/**
 * Changes the hash size of the dictionary.
 *
 * \param hashsize The new hash size for the dictionary
 */
- changeHashSize: (int)hashsize;
@end

#import "OFIterator.h"
#import "OFMutableDictionary.h"
