/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFAdjacentSubarray.h"
#import "OFAdjacentArray.h"
#import "OFMutableAdjacentArray.h"

@implementation OFAdjacentSubarray
- (const id *)objects
{
	return _array.objects + _range.location;
}

- (bool)isEqual: (id)object
{
	OFArray *otherArray;
	id const *objects, *otherObjects;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFAdjacentArray class]] &&
	    ![object isKindOfClass: [OFMutableAdjacentArray class]])
		return [super isEqual: object];

	otherArray = object;

	if (_range.length != otherArray.count)
		return false;

	objects = self.objects;
	otherObjects = otherArray.objects;

	for (size_t i = 0; i < _range.length; i++)
		if (![objects[i] isEqual: otherObjects[i]])
			return false;

	return true;
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_array_enumeration_block_t)block
{
	id const *objects = self.objects;
	bool stop = false;

	for (size_t i = 0; i < _range.length && !stop; i++)
		block(objects[i], i, &stop);
}
#endif
@end
