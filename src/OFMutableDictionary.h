/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "OFDictionary.h"

#ifdef OF_HAVE_BLOCKS
typedef id (^of_dictionary_replace_block_t)(id key, id object, bool *stop);
#endif

/*!
 * @brief An abstract class for storing and changing objects in a dictionary.
 */
@interface OFMutableDictionary: OFDictionary
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
- initWithCapacity: (size_t)capacity;

/*!
 * @brief Sets an object for a key.
 *
 * A key can be any object that conforms to the OFCopying protocol.
 *
 * @param key The key to set
 * @param object The object to set the key to
 */
- (void)setObject: (id)object
	   forKey: (id)key;
-   (void)setObject: (id)object
  forKeyedSubscript: (id)key;

/*!
 * @brief Removes the object for the specified key from the dictionary.
 *
 * @param key The key whose object should be removed
 */
- (void)removeObjectForKey: (id)key;

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
@end
