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

extern int _OFIterator_reference;

/**
 * The OFIterator class provides methods to iterate through objects.
 */
@interface OFIterator: OFObject
{
	OFList		 **data;
	size_t		 size;
	size_t		 pos;
	of_list_object_t *last;
}

- initWithData: (OFList**)data
       andSize: (size_t)size;

/**
 * Returns the next object in the dictionary.
 *
 * Always call it twice in a row, as it returns the key on the first call and
 * the value on the second. Therefore, if you want a key value pair, you have
 * to call:
 *
 * key = [iter nextObject];\n
 * value = [iter nextObject];
 *
 * When there is no more object left, an OFNotInSetException is thrown.
 *
 * \return The key on the first call and the value on the second
 */
- (id)nextObject;

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
