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

#import "OFDictionary.h"

struct of_dictionary_hashtable_bucket
{
	id key, object;
	uint32_t hash;
};

@interface OFDictionary_hashtable: OFDictionary
{
	struct of_dictionary_hashtable_bucket **data;
	uint32_t size;
	size_t count;
}

#if defined(OF_SET_M) || defined(OF_COUNTED_SET_M)
- _initWithDictionary: (OFDictionary*)dictionary
	     copyKeys: (BOOL)copyKeys;
#endif
@end

@interface OFDictionaryEnumerator_hashtable: OFEnumerator
{
	OFDictionary_hashtable *dictionary;
	struct of_dictionary_hashtable_bucket **data;
	uint32_t size;
	unsigned long mutations;
	unsigned long *mutationsPtr;
	uint32_t pos;
}

- initWithDictionary: (OFDictionary_hashtable*)dictionary
		data: (struct of_dictionary_hashtable_bucket**)data
		size: (uint32_t)size
    mutationsPointer: (unsigned long*)mutationsPtr;
@end

@interface OFDictionaryKeyEnumerator_hashtable: OFDictionaryEnumerator_hashtable
@end

@interface OFDictionaryObjectEnumerator_hashtable:
    OFDictionaryEnumerator_hashtable
@end

#ifdef __cplusplus
extern "C" {
#endif
extern struct of_dictionary_hashtable_bucket
    of_dictionary_hashtable_deleted_bucket;
#ifdef __cplusplus
}
#endif
