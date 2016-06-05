/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFUndefinedKeyException.h"
#import "OFString.h"

@implementation OFUndefinedKeyException
@synthesize object = _object, key = _key, value = _value;

+ (instancetype)exceptionWithObject: (id)object
				key: (OFString*)key
{
	return [[[self alloc] initWithObject: object
					 key: key] autorelease];
}

+ (instancetype)exceptionWithObject: (id)object
				key: (OFString*)key
			      value: (id)value
{
	return [[[self alloc] initWithObject: object
					 key: key
				       value: value] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithObject: (id)object
	     key: (OFString*)key
{
	self = [super init];

	@try {
		_object = [object retain];
		_key = [key copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObject: (id)object
	     key: (OFString*)key
	   value: (id)value
{
	self = [super init];

	@try {
		_object = [object retain];
		_key = [key copy];
		_value = [value retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_object release];
	[_key release];
	[_value release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"The key \"%@\" is undefined for an object of type %@!",
	    _key, [_object className]];
}
@end
