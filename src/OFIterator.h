/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"
#import "OFList.h"
#import "OFDictionary.h"

/**
 * An iterator pair combines a key and its object in a single struct.
 */
typedef struct __of_iterator_pair {
	/// The key
	id	 key;
	/// The object for the key
	id	 object;
} of_iterator_pair_t;

extern int _OFIterator_reference;

/**
 * The OFIterator class provides methods to iterate through objects.
 */
@interface OFIterator: OFObject
{
	struct of_dictionary_bucket *data;
	size_t			    size;
	size_t			    pos;
}

- initWithData: (struct of_dictionary_bucket*)data
	  size: (size_t)size;

/**
 * \return A struct containing the next key and object
 */
- (of_iterator_pair_t)nextKeyObjectPair;

/**
 * Resets the iterator, so the next call to nextObject returns the first again.
 */
- reset;
@end

/**
 * The OFIterator category adds functions to get an interator to OFDictionary.
 */
@interface OFDictionary (OFIterator)
/**
 * Creates an OFIterator for the dictionary.
 *
 * It will copy the data of the OFDictionary so that OFIterator will always
 * operate on the data that was present when it was created. If you changed the
 * OFDictionary and want to operate on the new data, you need to create a new
 * OFIterator, as using reset will only reset the OFIterator, but won't update
 * the data. It will also retain the data inside the OFDictionary so the
 * OFIterator still works after you released the OFDictionary. Thus, if you want
 * to get rid of the objects in the OFDictionary, you also need to release the
 * OFIterator.
 *
 * \return An OFIterator for the OFDictionary
 */
- (OFIterator*)iterator;
@end
