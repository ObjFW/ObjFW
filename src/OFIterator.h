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

#import "OFObject.h"
#import "OFList.h"
#import "OFDictionary.h"

typedef struct __of_iterator_pair {
	id key;
	id object;
} of_iterator_pair_t;

extern int _OFIterator_reference;

/**
 * The OFIterator class provides methods to iterate through objects.
 */
@interface OFIterator: OFObject
{
	OFList		 **data;
	size_t		 size;
	size_t			    pos;
	of_dictionary_list_object_t *last;
}

- initWithData: (OFList**)data
       andSize: (size_t)size;

/**
 * \return A struct containing the next key and object
 */
- (of_iterator_pair_t)nextKeyObjectPair;

/**
 * Resets the iterator, so the next call to nextObject returns the first again.
 */
- reset;
@end

@interface OFDictionary (OFIterator)
/**
 * \return An OFIterator for the OFDictionary
 */
- (OFIterator*)iterator;
@end
