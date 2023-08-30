/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
