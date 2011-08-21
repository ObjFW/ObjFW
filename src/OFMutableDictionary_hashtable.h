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

@interface OFMutableDictionary_hashtable: OFMutableDictionary
{
	struct of_dictionary_hashtable_bucket **data;
	uint32_t size;
	size_t count;
	unsigned long mutations;
}

#if defined(OF_SET_M) || defined(OF_COUNTED_SET_M)
- _initWithDictionary: (OFDictionary*)dictionary
	     copyKeys: (BOOL)copyKeys;
#endif

#if defined(OF_SET_M) || defined(OF_MUTABLE_SET_M) || defined(OF_COUNTED_SET_M)
- (void)_setObject: (id)object
	    forKey: (id)key
	   copyKey: (BOOL)copyKey;
#endif
@end
