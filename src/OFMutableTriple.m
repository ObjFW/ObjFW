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

#import "OFMutableTriple.h"

@implementation OFMutableTriple
@dynamic firstObject, secondObject, thirdObject;

- (void)setFirstObject: (id)firstObject
{
	id old = _firstObject;
	_firstObject = objc_retain(firstObject);
	objc_release(old);
}

- (void)setSecondObject: (id)secondObject
{
	id old = _secondObject;
	_secondObject = objc_retain(secondObject);
	objc_release(old);
}

- (void)setThirdObject: (id)thirdObject
{
	id old = _thirdObject;
	_thirdObject = objc_retain(thirdObject);
	objc_release(old);
}

- (id)copy
{
	OFMutableTriple *copy = [self mutableCopy];

	[copy makeImmutable];

	return copy;
}

- (void)makeImmutable
{
	object_setClass(self, [OFTriple class]);
}
@end
