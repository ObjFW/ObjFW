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

#import "OFUndefinedKeyException.h"
#import "OFString.h"

@implementation OFUndefinedKeyException
@synthesize object = _object, key = _key, value = _value;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithObject: (id)object key: (OFString *)key
{
	return [[[self alloc] initWithObject: object key: key] autorelease];
}

+ (instancetype)exceptionWithObject: (id)object
				key: (OFString *)key
			      value: (id)value
{
	return [[[self alloc] initWithObject: object
					 key: key
				       value: value] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithObject: (id)object key: (OFString *)key
{
	return [self initWithObject: object key: key value: nil];
}

- (instancetype)initWithObject: (id)object key: (OFString *)key value: (id)value
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

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"The key \"%@\" is undefined for an object of type %@!",
	    _key, [_object className]];
}
@end
