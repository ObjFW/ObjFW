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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <stdarg.h>

#import "OFObject.h"
#import "OFCollection.h"
#import "OFEnumerator.h"
#import "OFSerialization.h"
#import "OFJSONRepresentation.h"
#import "OFMessagePackRepresentation.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);

#ifdef OF_HAVE_BLOCKS
typedef void (^of_dictionary_enumeration_block_t)(id key, id object,
     bool *stop);
typedef bool (^of_dictionary_filter_block_t)(id key, id object);
typedef id _Nonnull (^of_dictionary_map_block_t)(id key, id object);
#endif

/*!
 * @class OFDictionary OFDictionary.h ObjFW/OFDictionary.h
 *
 * @brief An abstract class for storing objects in a dictionary.
 *
 * Keys are copied and thus must conform to the OFCopying protocol.
 *
 * @note Fast enumeration on a dictionary enumerates through the keys of the
 *	 dictionary.
 *
 * @note Subclasses must implement @ref objectForKey:, @ref count and
 *	 @ref keyEnumerator.
 */
@interface OFDictionary OF_GENERIC(KeyType, ObjectType): OFObject <OFCopying,
    OFMutableCopying, OFCollection, OFSerialization, OFJSONRepresentation,
    OFMessagePackRepresentation>
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define KeyType id
# define ObjectType id
#endif
/*!
 * @brief Creates a new OFDictionary.
 *
 * @return A new autoreleased OFDictionary
 */
+ (instancetype)dictionary;

/*!
 * @brief Creates a new OFDictionary with the specified dictionary.
 *
 * @param dictionary An OFDictionary
 * @return A new autoreleased OFDictionary
 */
+ (instancetype)dictionaryWithDictionary:
   (OFDictionary OF_GENERIC(KeyType, ObjectType) *)dictionary;

/*!
 * @brief Creates a new OFDictionary with the specified key and object.
 *
 * @param key The key
 * @param object The object
 * @return A new autoreleased OFDictionary
 */
+ (instancetype)dictionaryWithObject: (ObjectType)object
			      forKey: (KeyType)key;

/*!
 * @brief Creates a new OFDictionary with the specified keys and objects.
 *
 * @param keys An array of keys
 * @param objects An array of objects
 * @return A new autoreleased OFDictionary
 */
+ (instancetype)
    dictionaryWithObjects: (OFArray OF_GENERIC(ObjectType) *)objects
		  forKeys: (OFArray OF_GENERIC(KeyType) *)keys;

/*!
 * @brief Creates a new OFDictionary with the specified keys and objects.
 *
 * @param keys An array of keys
 * @param objects An array of objects
 * @param count The number of objects in the arrays
 * @return A new autoreleased OFDictionary
 */
+ (instancetype)
    dictionaryWithObjects: (ObjectType const _Nonnull *_Nonnull)objects
		  forKeys: (KeyType const _Nonnull *_Nonnull)keys
		    count: (size_t)count;

/*!
 * @brief Creates a new OFDictionary with the specified keys objects.
 *
 * @param firstKey The first key
 * @return A new autoreleased OFDictionary
 */
+ (instancetype)dictionaryWithKeysAndObjects: (KeyType)firstKey, ...
    OF_SENTINEL;

/*!
 * @brief An array of all keys.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(KeyType) *allKeys;

/*!
 * @brief An array of all objects.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(ObjectType) *allObjects;

/*!
 * @brief A URL-encoded string with the contents of the dictionary.
 */
@property (readonly, nonatomic) OFString *stringByURLEncoding;

/*!
 * @brief Initializes an already allocated OFDictionary with the specified
 *	  OFDictionary.
 *
 * @param dictionary An OFDictionary
 * @return An initialized OFDictionary
 */
- (instancetype)initWithDictionary:
    (OFDictionary OF_GENERIC(KeyType, ObjectType) *)dictionary;

/*!
 * @brief Initializes an already allocated OFDictionary with the specified key
 *	  and object.
 *
 * @param key The key
 * @param object The object
 * @return An initialized OFDictionary
 */
- (instancetype)initWithObject: (ObjectType)object
			forKey: (KeyType)key;

/*!
 * @brief Initializes an already allocated OFDictionary with the specified keys
 *	  and objects.
 *
 * @param keys An array of keys
 * @param objects An array of objects
 * @return An initialized OFDictionary
 */
- (instancetype)initWithObjects: (OFArray OF_GENERIC(ObjectType) *)objects
			forKeys: (OFArray OF_GENERIC(KeyType) *)keys;

/*!
 * @brief Initializes an already allocated OFDictionary with the specified keys
 *	  and objects.
 *
 * @param keys An array of keys
 * @param objects An array of objects
 * @param count The number of objects in the arrays
 * @return An initialized OFDictionary
 */
- (instancetype)initWithObjects: (ObjectType const _Nonnull *_Nonnull)objects
			forKeys: (KeyType const _Nonnull *_Nonnull)keys
			  count: (size_t)count;

/*!
 * @brief Initializes an already allocated OFDictionary with the specified keys
 *	  and objects.
 *
 * @param firstKey The first key
 * @return An initialized OFDictionary
 */
- (instancetype)initWithKeysAndObjects: (KeyType)firstKey, ... OF_SENTINEL;

/*!
 * @brief Initializes an already allocated OFDictionary with the specified key
 *	  and va_list.
 *
 * @param firstKey The first key
 * @param arguments A va_list of the other arguments
 * @return An initialized OFDictionary
 */
- (instancetype)initWithKey: (KeyType)firstKey
		  arguments: (va_list)arguments;

/*!
 * @brief Returns the object for the given key or `nil` if the key was not
 *	  found.
 *
 * @warning The returned object is *not* retained and autoreleased for
 *	    performance reasons!
 *
 * @param key The key whose object should be returned
 * @return The object for the given key or `nil` if the key was not found
 */
- (nullable ObjectType)objectForKey: (KeyType)key;
- (nullable ObjectType)objectForKeyedSubscript: (KeyType)key;

/*!
 * @brief Returns the value for the given key or `nil` if the key was not
 *	  found.
 *
 * This is equivalent to @ref objectForKey:.
 *
 * The special key `@count` can be used to retrieve the count as an OFNumber.
 *
 * @param key The key whose value should be returned
 * @return The value for the given key or `nil` if the key was not found
 */
- (nullable id)valueForKey: (OFString *)key;

/*!
 * @brief Sets a value for a key.
 *
 * This is equivalent to OFMutableDictionary#setObject:forKey:. If the
 * dictionary is immutable, an @ref OFUndefinedKeyException is thrown.
 *
 * @param key The key to set
 * @param value The value to set the key to
 */
- (void)setValue: (nullable id)value
	  forKey: (OFString *)key;

/*!
 * @brief Checks whether the dictionary contains an object equal to the
 *	  specified object.
 *
 * @param object The object which is checked for being in the dictionary
 * @return A boolean whether the dictionary contains the specified object
 */
- (bool)containsObject: (ObjectType)object;

/*!
 * @brief Checks whether the dictionary contains an object with the specified
 *	  address.
 *
 * @param object The object which is checked for being in the dictionary
 * @return A boolean whether the dictionary contains an object with the
 *	   specified address
 */
- (bool)containsObjectIdenticalTo: (ObjectType)object;

/*!
 * @brief Returns an OFEnumerator to enumerate through the dictionary's keys.
 *
 * @return An OFEnumerator to enumerate through the dictionary's keys
 */
- (OFEnumerator OF_GENERIC(KeyType) *)keyEnumerator;

/*!
 * @brief Returns an OFEnumerator to enumerate through the dictionary's objects.
 *
 * @return An OFEnumerator to enumerate through the dictionary's objects
 */
- (OFEnumerator OF_GENERIC(ObjectType) *)objectEnumerator;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Executes a block for each key / object pair.
 *
 * @param block The block to execute for each key / object pair.
 */
- (void)enumerateKeysAndObjectsUsingBlock:
    (of_dictionary_enumeration_block_t)block;

/*!
 * @brief Creates a new dictionary, mapping each object using the specified
 *	  block.
 *
 * @param block A block which maps an object for each object
 * @return A new autoreleased OFDictionary
 */
- (OFDictionary OF_GENERIC(KeyType, id) *)mappedDictionaryUsingBlock:
    (of_dictionary_map_block_t)block;

/*!
 * @brief Creates a new dictionary, only containing the objects for which the
 *	  block returns true.
 *
 * @param block A block which determines if the object should be in the new
 *		dictionary
 * @return A new autoreleased OFDictionary
 */
- (OFDictionary OF_GENERIC(KeyType, ObjectType) *)filteredDictionaryUsingBlock:
    (of_dictionary_filter_block_t)block;
#endif
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef KeyType
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END

#import "OFMutableDictionary.h"

#if !defined(NSINTEGER_DEFINED) && !__has_feature(modules)
/* Required for dictionary literals to work */
@compatibility_alias NSDictionary OFDictionary;
#endif
