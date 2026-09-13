/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFPair.h"
#import "OFString.h"

@implementation OFPair
+ (instancetype)pairWithFirstObject: (id)firstObject
		       secondObject: (id)secondObject
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithFirstObject: firstObject
				 secondObject: secondObject]);
}

- (instancetype)initWithFirstObject: (id)firstObject
		       secondObject: (id)secondObject
{
	self = [super init];

	@try {
		_firstObject = objc_retain(firstObject);
		_secondObject = objc_retain(secondObject);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_firstObject);
	objc_release(_secondObject);

	[super dealloc];
}

- (id)firstObject
{
	return _firstObject;
}

- (id)secondObject
{
	return _secondObject;
}

- (bool)isEqual: (id)object
{
	OFPair *pair;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFPair class]])
		return false;

	pair = object;

	if (pair->_firstObject != _firstObject &&
	    ![pair->_firstObject isEqual: _firstObject])
		return false;

	if (pair->_secondObject != _secondObject &&
	    ![pair->_secondObject isEqual: _secondObject])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, [_firstObject hash]);
	OFHashAddHash(&hash, [_secondObject hash]);

	OFHashFinalize(&hash);

	return hash;
}

- (id)copy
{
	return objc_retain(self);
}

- (id)mutableCopy
{
	return [[OFMutablePair alloc] initWithFirstObject: _firstObject
					     secondObject: _secondObject];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<<%@, %@>>",
					   _firstObject, _secondObject];
}
@end
