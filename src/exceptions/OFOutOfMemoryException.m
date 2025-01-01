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

#import "OFOutOfMemoryException.h"
#import "OFString.h"

@implementation OFOutOfMemoryException
@synthesize requestedSize = _requestedSize;

+ (instancetype)exceptionWithRequestedSize: (size_t)requestedSize
{
	return [[[self alloc]
	    initWithRequestedSize: requestedSize] autorelease];
}

- (instancetype)init
{
	return [self initWithRequestedSize: 0];
}

- (instancetype)initWithRequestedSize: (size_t)requestedSize
{
	self = [super init];

	_requestedSize = requestedSize;

	return self;
}

- (OFString *)description
{
	if (_requestedSize != 0)
		return [OFString stringWithFormat:
		    @"Could not allocate %zu bytes!", _requestedSize];
	else
		return @"Could not allocate enough memory!";
}
@end
