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

#import "OFTriple.h"
#import "OFString.h"

@implementation OFTriple
+ (instancetype)tripleWithFirstObject: (id)firstObject
			 secondObject: (id)secondObject
			  thirdObject: (id)thirdObject
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithFirstObject: firstObject
				 secondObject: secondObject
				  thirdObject: thirdObject]);
}

- (instancetype)initWithFirstObject: (id)firstObject
		       secondObject: (id)secondObject
			thirdObject: (id)thirdObject
{
	self = [super init];

	@try {
		_firstObject = objc_retain(firstObject);
		_secondObject = objc_retain(secondObject);
		_thirdObject = objc_retain(thirdObject);
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
	objc_release(_thirdObject);

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

- (id)thirdObject
{
	return _thirdObject;
}

- (bool)isEqual: (id)object
{
	OFTriple *triple;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFTriple class]])
		return false;

	triple = object;

	if (triple->_firstObject != _firstObject &&
	    ![triple->_firstObject isEqual: _firstObject])
		return false;

	if (triple->_secondObject != _secondObject &&
	    ![triple->_secondObject isEqual: _secondObject])
		return false;

	if (triple->_thirdObject != _thirdObject &&
	    ![triple->_thirdObject isEqual: _thirdObject])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, [_firstObject hash]);
	OFHashAddHash(&hash, [_secondObject hash]);
	OFHashAddHash(&hash, [_thirdObject hash]);

	OFHashFinalize(&hash);

	return hash;
}

- (id)copy
{
	return objc_retain(self);
}

- (id)mutableCopy
{
	return [[OFMutableTriple alloc] initWithFirstObject: _firstObject
					       secondObject: _secondObject
						thirdObject: _thirdObject];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<<%@, %@, %@>>",
					   _firstObject, _secondObject,
					   _thirdObject];
}
@end
