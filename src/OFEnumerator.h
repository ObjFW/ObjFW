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
#import "OFDictionary.h"

/**
 * An enumerator pair combines a key and its object in a single struct.
 */
typedef struct __of_enumerator_pair {
	/// The key
	id	 key;
	/// The object for the key
	id	 object;
} of_enumerator_pair_t;

extern int _OFEnumerator_reference;

/**
 * The OFEnumerator class provides methods to enumerate through objects.
 */
@interface OFEnumerator: OFObject
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
- (of_enumerator_pair_t)nextKeyObjectPair;

/**
 * Resets the enumerator, so the next call to nextObject returns the first
 * again.
 */
- reset;
@end

/**
 * The OFEnumerator category adds functions to get an interator to OFDictionary.
 */
@interface OFDictionary (OFEnumerator)
/**
 * Creates an OFEnumerator for the dictionary.
 *
 * It will copy the data of the OFDictionary so that OFEnumerator will always
 * operate on the data that was present when it was created. If you changed the
 * OFDictionary and want to operate on the new data, you need to create a new
 * OFEnumerator, as using reset will only reset the OFEnumerator, but won't
 * update the data. It will also retain the data inside the OFDictionary so the
 * OFEnumerator still works after you released the OFDictionary. Thus, if you
 * want to get rid of the objects in the OFDictionary, you also need to release
 * the OFEnumerator.
 *
 * \return An OFEnumerator for the OFDictionary
 */
- (OFEnumerator*)enumerator;
@end
