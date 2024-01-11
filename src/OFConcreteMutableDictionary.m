/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#include <string.h>

#import "OFConcreteMutableDictionary.h"
#import "OFConcreteDictionary.h"
#import "OFMapTable.h"

#import "OFEnumerationMutationException.h"
#import "OFOutOfRangeException.h"

@implementation OFConcreteMutableDictionary
+ (void)initialize
{
	if (self == [OFConcreteMutableDictionary class])
		[self inheritMethodsFromClass: [OFConcreteDictionary class]];
}

- (void)setObject: (id)object forKey: (id)key
{
	[_mapTable setObject: object forKey: key];
}

- (void)removeObjectForKey: (id)key
{
	[_mapTable removeObjectForKey: key];
}

- (void)removeAllObjects
{
	[_mapTable removeAllObjects];
}

#ifdef OF_HAVE_BLOCKS
- (void)replaceObjectsUsingBlock: (OFDictionaryReplaceBlock)block
{
	@try {
		[_mapTable replaceObjectsUsingBlock:
		    ^ void *(void *key, void *object) {
			return block(key, object);
		}];
	} @catch (OFEnumerationMutationException *e) {
		@throw [OFEnumerationMutationException
		    exceptionWithObject: self];
	}
}
#endif

- (void)makeImmutable
{
	object_setClass(self, [OFConcreteDictionary class]);
}
@end
