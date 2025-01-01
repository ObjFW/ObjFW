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

#import "OFActivateSandboxFailedException.h"
#import "OFString.h"
#import "OFSandbox.h"

@implementation OFActivateSandboxFailedException
@synthesize sandbox = _sandbox, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithSandbox: (OFSandbox *)sandbox errNo: (int)errNo
{
	return [[[self alloc] initWithSandbox: sandbox
					errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSandbox: (OFSandbox *)sandbox errNo: (int)errNo
{
	self = [super init];

	_sandbox = [sandbox retain];
	_errNo = errNo;

	return self;
}

- (void)dealloc
{
	[_sandbox release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"The sandbox could not be applied: %@", OFStrError(_errNo)];
}
@end
