/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFConcreteSubarray.h"
#import "OFConcreteArray.h"
#import "OFConcreteMutableArray.h"

@implementation OFConcreteSubarray
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

	if (![object isKindOfClass: [OFConcreteArray class]] &&
	    ![object isKindOfClass: [OFConcreteMutableArray class]])
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
- (void)enumerateObjectsUsingBlock: (OFArrayEnumerationBlock)block
{
	id const *objects = self.objects;
	bool stop = false;

	for (size_t i = 0; i < _range.length && !stop; i++)
		block(objects[i], i, &stop);
}
#endif
@end
