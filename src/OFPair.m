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

#import "OFPair.h"
#import "OFString.h"

@implementation OFPair
+ (instancetype)pairWithFirstObject: (id)firstObject
		       secondObject: (id)secondObject
{
	return [[[self alloc] initWithFirstObject: firstObject
				     secondObject: secondObject] autorelease];
}

- initWithFirstObject: (id)firstObject
	 secondObject: (id)secondObject
{
	self = [super init];

	@try {
		_firstObject = [firstObject retain];
		_secondObject = [secondObject retain];
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

	if (![object isKindOfClass: [OFPair class]])
		return false;

	pair = object;

	if (![pair->_firstObject isEqual: _firstObject])
		return false;

	if (![pair->_secondObject isEqual: _secondObject])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [_firstObject hash]);
	OF_HASH_ADD_HASH(hash, [_secondObject hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
{
	return [self retain];
}

- mutableCopy
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
