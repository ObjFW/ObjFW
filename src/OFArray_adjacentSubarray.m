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

#include "config.h"

#import "OFArray_adjacentSubarray.h"
#import "OFArray_adjacent.h"
#import "OFMutableArray_adjacent.h"

@implementation OFArray_adjacentSubarray
- (id*)cArray
{
	return [array cArray] + range.start;
}

- (BOOL)isEqual: (id)object
{
	OFArray *otherArray;
	id *cArray, *otherCArray;
	size_t i;

	if ([object class] != [OFArray_adjacent class] &&
	    [object class] != [OFMutableArray_adjacent class] &&
	    [object class] != [OFArray_adjacentSubarray class])
		return [super isEqual: object];

	otherArray = object;

	if (range.length != [otherArray count])
		return NO;

	cArray = [self cArray];
	otherCArray = [otherArray cArray];

	for (i = 0; i < range.length; i++)
		if (![cArray[i] isEqual: otherCArray[i]])
			return NO;

	return YES;
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_array_enumeration_block_t)block
{
	id *cArray = [self cArray];
	size_t i;
	BOOL stop = NO;

	for (i = 0; i < range.length && !stop; i++)
		block(cArray[i], i, &stop);
}
#endif
@end
