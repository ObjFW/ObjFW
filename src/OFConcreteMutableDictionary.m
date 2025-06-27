/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
