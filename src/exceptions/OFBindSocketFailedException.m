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

#import "OFBindSocketFailedException.h"
#import "OFString.h"

@implementation OFBindSocketFailedException
@synthesize socket = _socket, errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithSocket: (id)sock errNo: (int)errNo
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithSocket: sock
				   errNo: errNo]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSocket: (id)sock errNo: (int)errNo
{
	self = [super init];

	@try {
		_socket = objc_retain(sock);
		_errNo = errNo;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_socket);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Binding a socket of type %@ failed: %@",
	    [_socket class], OFStrError(_errNo)];
}
@end
