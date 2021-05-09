/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFTriple.h"
#import "OFString.h"

@implementation OFTriple
+ (instancetype)tripleWithFirstObject: (id)firstObject
			 secondObject: (id)secondObject
			  thirdObject: (id)thirdObject
{
	return [[[self alloc] initWithFirstObject: firstObject
				     secondObject: secondObject
				      thirdObject: thirdObject] autorelease];
}

- (instancetype)initWithFirstObject: (id)firstObject
		       secondObject: (id)secondObject
			thirdObject: (id)thirdObject
{
	self = [super init];

	@try {
		_firstObject = [firstObject retain];
		_secondObject = [secondObject retain];
		_thirdObject = [thirdObject retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_firstObject release];
	[_secondObject release];
	[_thirdObject release];

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
	return [self retain];
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
