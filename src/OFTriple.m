/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

- initWithFirstObject: (id)firstObject
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

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [_firstObject hash]);
	OF_HASH_ADD_HASH(hash, [_secondObject hash]);
	OF_HASH_ADD_HASH(hash, [_thirdObject hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
{
	return [self retain];
}

- mutableCopy
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
