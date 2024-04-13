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

#import "OFSetOptionFailedException.h"
#import "OFString.h"

@implementation OFSetOptionFailedException
@synthesize object = _object, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithObject: (id)object errNo: (int)errNo
{
	return [[[self alloc] initWithObject: object errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithObject: (id)object errNo: (int)errNo
{
	self = [super init];

	_object = [object retain];
	_errNo = errNo;

	return self;
}

- (void)dealloc
{
	[_object release];

	[super dealloc];
}

- (OFString *)description
{
	if (_object != nil)
		return [OFString stringWithFormat:
		    @"Setting an option in an object of type %@ failed: %@",
		    [_object class], OFStrError(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Setting an option failed: %@", OFStrError(_errNo)];
}
@end
