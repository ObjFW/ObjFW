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

#import "OFGetCurrentDirectoryFailedException.h"
#import "OFString.h"

@implementation OFGetCurrentDirectoryFailedException
@synthesize errNo = _errNo;

+ (instancetype)exceptionWithErrNo: (int)errNo
{
	return [[[self alloc] initWithErrNo: errNo] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithErrNo: (int)errNo
{
	self = [super init];

	_errNo = errNo;

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Getting the current directory path failed: %@",
	    OFStrError(_errNo)];
}
@end
